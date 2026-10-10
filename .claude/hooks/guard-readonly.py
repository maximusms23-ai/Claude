#!/usr/bin/env python3
"""PreToolUse-Hook: schuetzt das Quellmaterial vor Schreibzugriffen.

`Obsidian/raw/` und `Obsidian/Clippings/` sind laut CLAUDE.md und AGENTS.md
read-only. Dieser Hook macht daraus eine erzwungene Regel: Schreibversuche
werden blockiert (Exit 2), bevor sie passieren. Lesen bleibt frei.

Exit 0 = durchlassen, Exit 2 = blocken (stderr geht an Claude).
Bei jedem unerwarteten Fehler wird durchgelassen, nie blockiert — ein defekter
Hook darf die Arbeit nicht lahmlegen.
"""
import json, os, re, sys

PROTECTED = ('Obsidian/raw', 'Obsidian/Clippings')

# Bash-Verben, die Dateien veraendern. Lesen (cat, grep, ls, head) fehlt hier
# absichtlich.
MUTATORS = re.compile(
    r'(^|[;&|]\s*|\s)('
    r'rm|rmdir|mv|cp|install|truncate|shred|unlink|chmod|chown|touch|'
    r'ln|dd|tee|sponge|'
    r'sed\s+[^|]*-i|perl\s+[^|]*-i|'
    r'git\s+(rm|mv|checkout|restore|clean|apply)'
    r')\b', re.I)
REDIRECT = re.compile(r'>>?\s*[\'"]?[^\s\'"|;&]*(?:' + '|'.join(
    p.replace('/', '/') for p in PROTECTED) + r')', re.I)

# Heredoc-Koerper sind Daten, nicht Code. Eine Commit-Nachricht darf die
# geschuetzten Pfade nennen und von `rm` erzaehlen, ohne als Angriff zu gelten.
HEREDOC = re.compile(r'<<-?\s*[\'"]?(\w+)[\'"]?')


def strip_heredocs(cmd):
    """Entfernt Heredoc-Koerper, behaelt aber die Kommandozeile davor.

    `cat > Obsidian/raw/x.md <<EOF` bleibt damit erkennbar, waehrend der Text
    im Koerper die Pruefung nicht mehr ausloest.
    """
    lines, out, skip_until = cmd.split('\n'), [], None
    for line in lines:
        if skip_until is not None:
            if line.strip() == skip_until:
                skip_until = None
            continue
        out.append(line)
        m = HEREDOC.search(line)
        if m:
            skip_until = m.group(1)
    return '\n'.join(out)


def segments(cmd):
    """Zerlegt in einzelne Kommandos.

    Ein Pfad in einem Kommando und ein Schreibverb in einem anderen sind
    zusammen harmlos — nur beides im selben Kommando ist ein Schreibzugriff.
    """
    return [s for s in re.split(r'[\n;]|&&|\|\||\|', cmd) if s.strip()]


def protected(path):
    if not path:
        return None
    norm = os.path.normpath(str(path)).replace(os.sep, '/')
    for p in PROTECTED:
        if norm == p or ('/' + norm).endswith('/' + p) or ('/' + norm + '/').find('/' + p + '/') != -1:
            return p
    return None


def block(area, detail):
    sys.stderr.write(
        '%s ist Quellmaterial und read-only (CLAUDE.md, AGENTS.md).\n'
        'Blockiert: %s\n\n'
        'Stattdessen: nach Obsidian/wiki/ schreiben und von dort auf die Quelle '
        'verweisen. Soll das Quellmaterial wirklich geaendert werden, muss der '
        'User das ausdruecklich freigeben.\n' % (area, detail))
    sys.exit(2)


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    tool = data.get('tool_name') or ''
    args = data.get('tool_input') or {}

    if tool in ('Write', 'Edit', 'MultiEdit', 'NotebookEdit'):
        path = args.get('file_path') or args.get('notebook_path')
        area = protected(path)
        if area:
            block(area, '%s auf %s' % (tool, path))
        for item in (args.get('edits') or []):
            area = protected(item.get('file_path'))
            if area:
                block(area, '%s auf %s' % (tool, item.get('file_path')))

    elif tool == 'Bash':
        cmd = strip_heredocs(args.get('command') or '')
        if not any(p in cmd for p in PROTECTED):
            sys.exit(0)
        for seg in segments(cmd):
            if not any(p in seg for p in PROTECTED):
                continue
            if MUTATORS.search(seg) or REDIRECT.search(seg):
                block('Obsidian/raw bzw. Obsidian/Clippings',
                      'Bash-Kommando mit Schreibzugriff: %s' % seg.strip()[:200])

    sys.exit(0)


if __name__ == '__main__':
    try:
        main()
    except SystemExit:
        raise
    except Exception:
        sys.exit(0)

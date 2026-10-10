#!/usr/bin/env python3
"""Stop-Hook: haelt die Pflicht-Updates der Wissensbasis ein.

CLAUDE.md verlangt nach jeder Inhaltsaenderung einen Eintrag in `wiki/index.md`
("Letzte Aktualisierungen" + Statistiken), und beim Anlegen, Umbenennen oder
Entfernen von Seiten zusaetzlich die Pflege der zugehoerigen `*-Index.md`.
Dieser Hook prueft das am Ende einer Session und blockt das Beenden (Exit 2),
solange etwas fehlt oder `wiki_check.py` einen Fehler meldet.

Eine bloss im Text geaenderte Seite braucht keinen neuen Index-Eintrag — nur
die Zeile im Aenderungsprotokoll.

Loopschutz: wenn `stop_hook_active` gesetzt ist, laeuft der Hook nicht erneut —
sonst koennte er sich selbst endlos aufrufen.

Faellt irgendetwas unerwartet aus, wird durchgelassen. Ein defekter Hook darf
eine Session nicht einsperren.
"""
import json, os, subprocess, sys

def sh(args, cwd):
    try:
        r = subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=30)
        return r.returncode, r.stdout, r.stderr
    except Exception:
        return 1, '', ''

def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        data = {}

    # Loopschutz: nach einem Block nicht noch einmal blocken.
    if data.get('stop_hook_active'):
        sys.exit(0)

    root = os.environ.get('CLAUDE_PROJECT_DIR') or ''
    if not root or not os.path.isdir(root):
        rc, out, _ = sh(['git', 'rev-parse', '--show-toplevel'], os.getcwd())
        root = out.strip() if rc == 0 else os.getcwd()

    rc, out, _ = sh(['git', 'status', '--porcelain'], root)
    if rc != 0:
        sys.exit(0)

    changed, structural = set(), set()
    for line in out.splitlines():
        if len(line) < 4:
            continue
        code, path = line[:2], line[3:].strip().strip('"')
        if ' -> ' in path:           # Rename
            path = path.split(' -> ')[-1].strip().strip('"')
        changed.add(path)
        # Nur Anlegen, Entfernen, Umbenennen beruehrt die Indexseiten.
        # Eine bloss geaenderte Seite (M) braucht keinen neuen Eintrag —
        # CLAUDE.md verlangt Index-Pflege "when adding/removing pages".
        if any(c in code for c in ('A', 'D', 'R', 'C', '?')):
            structural.add(path)

    wiki = 'Obsidian/wiki/'
    content = [p for p in changed
               if p.startswith(wiki) and p.endswith('.md')
               and not p.endswith('-Index.md') and p != wiki + 'index.md']
    if not content:
        sys.exit(0)   # keine Inhaltsaenderung -> nichts zu erzwingen

    problems = []
    if wiki + 'index.md' not in changed:
        problems.append(
            'wiki/index.md ist nicht angepasst — "Letzte Aktualisierungen" und '
            'Statistiken fehlen zu: ' + ', '.join(sorted(content)[:5]))

    sections = {p.split('/')[2] for p in content
                if p.count('/') >= 3 and p in structural}
    idx_map = {'themen': 'Themen-Index', 'konzepte': 'Konzepte-Index',
               'personen': 'Personen-Index', 'projekte': 'Projekte-Index',
               'quellen': 'Quellen-Index'}
    for sec in sorted(sections):
        name = idx_map.get(sec)
        if name and (wiki + sec + '/' + name + '.md') not in changed:
            problems.append('%s.md ist nicht angepasst, obwohl in wiki/%s/ eine Seite '
                            'angelegt, umbenannt oder entfernt wurde' % (name, sec))

    checker = os.path.join(root, 'scripts', 'wiki_check.py')
    if os.path.exists(checker):
        rc, out, err = sh([sys.executable, checker, '--quiet', '--warnings-ok'], root)
        if rc != 0:
            fails = [l for l in (out + err).splitlines() if l.startswith('FEHLER')]
            problems.extend(fails[:8] or ['wiki_check.py meldet Fehler'])

    if not problems:
        sys.exit(0)

    sys.stderr.write(
        'Die Pflicht-Updates aus CLAUDE.md fehlen noch:\n\n'
        + '\n'.join('- ' + p for p in problems)
        + '\n\nBitte nachziehen (oder den Agenten `wiki-index` dafuer nutzen) und '
          'erst dann beenden. Pruefen mit: python3 scripts/wiki_check.py\n')
    sys.exit(2)

if __name__ == '__main__':
    try:
        main()
    except SystemExit:
        raise
    except Exception:
        sys.exit(0)

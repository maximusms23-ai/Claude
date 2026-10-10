#!/usr/bin/env python3
"""Prueft die Wissensbasis gegen die Regeln aus CLAUDE.md / AGENTS.md.

Keine externen Abhaengigkeiten (kein PyYAML) — laeuft mit jedem python3.

Aufruf:
    python3 scripts/wiki_check.py            # Bericht, Exit 1 bei Fehlern
    python3 scripts/wiki_check.py --warnings-ok   # Exit 0 solange nur Warnungen
    python3 scripts/wiki_check.py --quiet    # nur Fehler und Warnungen, kein OK-Rauschen

Fehler (brechen):     fehlendes/kaputtes Frontmatter bei nicht-leeren Seiten
Warnungen (brechen nicht): offene Wikilinks, Index-Drift, falsche Statistik,
                           leere Seiten

Offene `[[Links]]` sind in Obsidian keine Fehler: sie markieren Seiten, die es
noch nicht gibt, und sind damit Themenvorschlaege. Sie werden gezaehlt und
gebuendelt gemeldet, nicht zeilenweise.
"""
import os, re, sys, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WIKI = os.path.join(ROOT, 'Obsidian', 'wiki')
SECTIONS = ['themen', 'konzepte', 'personen', 'projekte', 'quellen']
INDEX_NAMES = {'themen': 'Themen-Index', 'konzepte': 'Konzepte-Index',
               'personen': 'Personen-Index', 'projekte': 'Projekte-Index',
               'quellen': 'Quellen-Index'}
DATE_RE = re.compile(r'^\d{4}-\d{2}-\d{2}$')
LINK_RE = re.compile(r'\[\[([^\]]+)\]\]')
FENCE_RE = re.compile(r'^```.*?^```', re.M | re.S)
INLINE_CODE_RE = re.compile(r'`[^`\n]*`')


def strip_code(text):
    """Entfernt Code-Bloecke und Inline-Code.

    `[[Links]]` in einem Code-Beispiel ist Text ueber Links, kein Link —
    sonst meldet der Pruefer die eigene Dokumentation als Befund.
    """
    return INLINE_CODE_RE.sub('', FENCE_RE.sub('', text))

errors, warnings = [], []


def split_frontmatter(text):
    """Gibt (dict, body) zurueck. Flache Keys plus Listen unter '- '."""
    if not text.startswith('---'):
        return None, text
    end = text.find('\n---', 3)
    if end == -1:
        return None, text
    raw = text[3:end]
    body = text[end + 4:]
    fm, key = {}, None
    for line in raw.split('\n'):
        if not line.strip():
            continue
        m = re.match(r'^(\w+):\s*(.*)$', line)
        if m:
            key = m.group(1)
            val = m.group(2).strip().strip('"').strip("'")
            fm[key] = val if val else []
        elif line.lstrip().startswith('- ') and key:
            item = line.lstrip()[2:].strip().strip('"').strip("'")
            if not isinstance(fm.get(key), list):
                fm[key] = []
            fm[key].append(item)
    return fm, body


def pages():
    for f in sorted(glob.glob(os.path.join(WIKI, '**', '*.md'), recursive=True)):
        yield f, open(f, encoding='utf-8').read()


def main():
    quiet = '--quiet' in sys.argv
    warnings_ok = '--warnings-ok' in sys.argv

    if not os.path.isdir(WIKI):
        print('FEHLER: %s nicht gefunden' % WIKI)
        return 1

    # --- Frontmatter sammeln, Linkziele aufbauen -------------------------
    targets, meta = set(), {}
    for f, text in pages():
        rel = os.path.relpath(f, ROOT)
        base = os.path.splitext(os.path.basename(f))[0]
        fm, _ = split_frontmatter(text)
        targets.add(base)
        if not text.strip():
            warnings.append('%s: leere Seite (Zweck unklar)' % rel)
            meta[f] = {}
            continue
        if fm is None:
            errors.append('%s: kein YAML-Frontmatter' % rel)
            meta[f] = {}
            continue
        meta[f] = fm
        for req in ('title', 'created', 'type'):
            if not fm.get(req):
                errors.append('%s: Frontmatter-Feld `%s` fehlt' % (rel, req))
        created = fm.get('created')
        if isinstance(created, str) and created and not DATE_RE.match(created):
            errors.append('%s: `created: %s` ist nicht YYYY-MM-DD' % (rel, created))
        if isinstance(fm.get('title'), str) and fm['title']:
            targets.add(fm['title'])
        for alias in (fm.get('aliases') or []):
            targets.add(alias)

    # --- Wikilinks ------------------------------------------------------
    open_total = 0
    for f, text in pages():
        rel = os.path.relpath(f, ROOT)
        _, body = split_frontmatter(text)
        unresolved = []
        for link in LINK_RE.findall(strip_code(body)):
            target = link.split('|')[0].split('#')[0].strip()
            if not target or target in targets or target in unresolved:
                continue
            unresolved.append(target)
        if unresolved:
            open_total += len(unresolved)
            shown = ', '.join(unresolved[:6])
            more = '' if len(unresolved) <= 6 else ', +%d weitere' % (len(unresolved) - 6)
            warnings.append('%s: %d offene Links (%s%s)'
                            % (rel, len(unresolved), shown, more))

    # --- Index-Drift und Statistiken ------------------------------------
    counts = {}
    for sec in SECTIONS:
        d = os.path.join(WIKI, sec)
        if not os.path.isdir(d):
            warnings.append('Verzeichnis wiki/%s/ fehlt' % sec)
            counts[sec] = 0
            continue
        content = [p for p in sorted(glob.glob(os.path.join(d, '*.md')))
                   if not os.path.basename(p).endswith('-Index.md')]
        counts[sec] = len(content)
        idx = os.path.join(d, INDEX_NAMES[sec] + '.md')
        if not os.path.exists(idx):
            warnings.append('Indexseite wiki/%s/%s.md fehlt' % (sec, INDEX_NAMES[sec]))
            continue
        idx_text = open(idx, encoding='utf-8').read()
        listed = {l.split('|')[0].split('#')[0].strip()
                  for l in LINK_RE.findall(strip_code(idx_text))}
        for p in content:
            base = os.path.splitext(os.path.basename(p))[0]
            names = {base}
            fm = meta.get(p) or {}
            if isinstance(fm.get('title'), str) and fm['title']:
                names.add(fm['title'])
            for a in (fm.get('aliases') or []):
                names.add(a)
            if not (names & listed):
                warnings.append('wiki/%s/%s.md in %s nicht verlinkt'
                                % (sec, base, INDEX_NAMES[sec]))

    main_idx = os.path.join(WIKI, 'index.md')
    if os.path.exists(main_idx):
        txt = open(main_idx, encoding='utf-8').read()
        labels = {'themen': 'Themen', 'konzepte': 'Konzepte', 'personen': 'Personen',
                  'projekte': 'Projekte', 'quellen': 'Quellen'}
        for sec, label in labels.items():
            m = re.search(r'^-\s*%s:\s*(\d+)\s*$' % label, txt, re.M)
            if not m:
                warnings.append('wiki/index.md: Statistikzeile "%s" fehlt' % label)
            elif int(m.group(1)) != counts.get(sec, 0):
                warnings.append('wiki/index.md: Statistik %s = %s, gezaehlt %d'
                                % (label, m.group(1), counts.get(sec, 0)))
    else:
        errors.append('wiki/index.md fehlt')

    # --- Bericht ---------------------------------------------------------
    for e in errors:
        print('FEHLER   %s' % e)
    for w in warnings:
        print('WARNUNG  %s' % w)
    if not quiet:
        print('\n%d Seiten geprueft | %d Fehler | %d Warnungen | %d offene Links'
              % (len(meta), len(errors), len(warnings), open_total))
        print('Bestand: ' + ', '.join('%s=%d' % (s, counts.get(s, 0)) for s in SECTIONS))
    if errors:
        return 1
    return 0 if (warnings_ok or not warnings) else 1


if __name__ == '__main__':
    sys.exit(main())

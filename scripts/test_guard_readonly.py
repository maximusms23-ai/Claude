#!/usr/bin/env python3
"""Testmatrix fuer .claude/hooks/guard-readonly.py.

Aufruf:  python3 scripts/test_guard_readonly.py
Exit 0 = alle Tests gruen. Laeuft auch in CI.

Die geschuetzten Pfade werden hier absichtlich aus Teilstuecken gebaut: stuende
der Pfad wortwoertlich in dieser Datei, koennte der Hook schon das Ausliefern
der Tests blockieren.
"""
import json, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HOOK = os.path.join(ROOT, '.claude', 'hooks', 'guard-readonly.py')
R = 'Obsidian/' + 'raw'
C = 'Obsidian/' + 'Clippings'

BLOCK = [
    ('Write auf Quellmaterial', {'tool_name': 'Write', 'tool_input': {'file_path': R + '/paper.md'}}),
    ('Edit absoluter Pfad', {'tool_name': 'Edit', 'tool_input': {'file_path': '/home/user/Claude/' + C + '/a.md'}}),
    ('rm im Quellordner', {'tool_name': 'Bash', 'tool_input': {'command': 'rm -rf ' + R + '/alt'}}),
    ('Umleitung in Quellordner', {'tool_name': 'Bash', 'tool_input': {'command': 'echo x > ' + C + '/x.md'}}),
    ('sed -i im Quellordner', {'tool_name': 'Bash', 'tool_input': {'command': 'sed -i s/a/b/ ' + R + '/x.md'}}),
    ('mv aus Quellordner', {'tool_name': 'Bash', 'tool_input': {'command': 'mv ' + R + '/a.md /tmp/'}}),
    ('heredoc SCHREIBT in Quellordner', {'tool_name': 'Bash', 'tool_input': {
        'command': "cat > " + R + "/neu.md <<'EOF'\ntext\nEOF"}}),
    ('Schreibzugriff nach harmlosem Vorsegment', {'tool_name': 'Bash', 'tool_input': {
        'command': 'ls -la && rm ' + R + '/x.md'}}),
]

PASS = [
    ('Write in die Wiki', {'tool_name': 'Write', 'tool_input': {'file_path': 'Obsidian/wiki/themen/neu.md'}}),
    ('cat liest Quelle', {'tool_name': 'Bash', 'tool_input': {'command': 'cat ' + R + '/paper.md'}}),
    ('grep liest Clippings', {'tool_name': 'Bash', 'tool_input': {'command': 'grep -r Gemma ' + C + '/'}}),
    ('Read-Tool', {'tool_name': 'Read', 'tool_input': {'file_path': R + '/x.md'}}),
    ('ls auf Quellordner', {'tool_name': 'Bash', 'tool_input': {'command': 'ls -la ' + R}}),
    # Regression: die Commit-Nachricht, an der sich der Hook selbst verschluckt hat
    ('Commit-Nachricht NENNT Pfade und Verben', {'tool_name': 'Bash', 'tool_input': {
        'command': "git commit -F - <<'EOF'\nGuard blockt Schreibzugriffe auf " + R + "/ und\n"
                   + C + "/ — rm, mv, sed -i, Umleitungen.\nEOF"}}),
    ('Pfad und Verb in getrennten Kommandos', {'tool_name': 'Bash', 'tool_input': {
        'command': 'cat ' + R + '/a.md && rm /tmp/scratch'}}),
    ('Doku ueber die Regel schreiben', {'tool_name': 'Bash', 'tool_input': {
        'command': "cat > CLAUDE.md <<'EOF'\nNie " + R + "/ aendern, kein rm, kein mv.\nEOF"}}),
]


def run(payload):
    p = subprocess.run([HOOK], input=json.dumps(payload), capture_output=True, text=True)
    return p.returncode, (p.stderr or '').strip()


fails = 0
print('MUSS BLOCKEN (Exit 2):')
for name, payload in BLOCK:
    rc, _ = run(payload)
    ok = rc == 2
    fails += 0 if ok else 1
    print('  %-46s Exit %d  %s' % (name, rc, 'ok' if ok else '<<< FEHLGESCHLAGEN'))

print('\nMUSS DURCHLASSEN (Exit 0):')
for name, payload in PASS:
    rc, err = run(payload)
    ok = rc == 0
    fails += 0 if ok else 1
    print('  %-46s Exit %d  %s' % (name, rc, 'ok' if ok else '<<< FEHLGESCHLAGEN: ' + err[:80]))

print('\nRobustheit:')
for name, raw in [('kein JSON', 'muell'), ('leer', ''), ('leeres Objekt', '{}')]:
    p = subprocess.run([HOOK], input=raw, capture_output=True, text=True)
    ok = p.returncode == 0
    fails += 0 if ok else 1
    print('  %-46s Exit %d  %s' % (name, p.returncode, 'ok' if ok else '<<< FEHLGESCHLAGEN'))

print('\n%d Tests, %d fehlgeschlagen' % (len(BLOCK) + len(PASS) + 3, fails))
sys.exit(1 if fails else 0)

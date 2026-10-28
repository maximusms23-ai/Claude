import sys
OR="#E8711A"; RD="#D23B2E"; BL="#2F6FD6"
HEAD='''<!doctype html><html><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Caveat:wght@600;700&display=swap" rel="stylesheet">
<style>html,body{margin:0;background:#fff}svg{display:block}text{font-family:'Caveat',cursive;font-weight:700}</style></head><body>
<svg width="1600" height="900" viewBox="0 0 1600 900" xmlns="http://www.w3.org/2000/svg">
<defs><filter id="w" x="-5%" y="-5%" width="110%" height="110%"><feTurbulence type="fractalNoise" baseFrequency="0.018" numOctaves="2" seed="SEED" result="n"/><feDisplacementMap in="SourceGraphic" in2="n" scale="5"/></filter>
<marker id="ah" viewBox="0 0 12 12" refX="8" refY="6" markerWidth="11" markerHeight="11" orient="auto"><path d="M1,1 L10,6 L1,11" fill="none" stroke="#E8711A" stroke-width="2" stroke-linecap="round"/></marker>
<marker id="ahb" viewBox="0 0 12 12" refX="8" refY="6" markerWidth="10" markerHeight="10" orient="auto"><path d="M1,1 L10,6 L1,11" fill="none" stroke="#2F6FD6" stroke-width="2" stroke-linecap="round"/></marker></defs>
'''
TAIL='</svg></body></html>'
def xh(cx,cy,s=1.0,rot=0,extra=''):
    # blob centered at cx,cy (body ~80x100*s), eyes, plus extra limbs (absolute coords)
    return f'''<g filter="url(#w)"><g transform="translate({cx},{cy}) rotate({rot}) scale({s})">
<path d="M-38,30 C-50,-10 -40,-50 -6,-54 C28,-58 44,-26 40,12 C36,38 22,50 2,50 C-16,50 -32,44 -38,30 Z" fill="#111"/>
<circle cx="-12" cy="-14" r="5.5" fill="#fff"/><circle cx="12" cy="-16" r="5.5" fill="#fff"/></g>
<g stroke="#111" stroke-width="3" stroke-linecap="round" fill="none">{extra}</g></g>'''
def t(x,y,txt,size=44,col="#111",rot=0):
    return f'<text x="{x}" y="{y}" font-size="{size}" fill="{col}" transform="rotate({rot} {x} {y})">{txt}</text>'
def G(inner,sw=3.2): return f'<g filter="url(#w)" fill="none" stroke="#111" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round">{inner}</g>'

imgs={}
# 02 Zahlenschloss
imgs['02-zahlenschloss']=(7, G('''
<path d="M440,360 L1120,360 Q1150,360 1150,390 L1150,610 Q1150,640 1120,640 L440,640 Q410,640 410,610 L410,390 Q410,360 440,360 Z" fill="#fff"/>
<path d="M1150,440 Q1260,440 1260,500 Q1260,560 1150,560" stroke-width="5"/>
<ellipse cx="560" cy="500" rx="120" ry="200" fill="#fff"/><ellipse cx="575" cy="500" rx="120" ry="200"/>
<ellipse cx="820" cy="500" rx="78" ry="130" fill="#fff"/><ellipse cx="830" cy="500" rx="78" ry="130"/>
<ellipse cx="1030" cy="500" rx="45" ry="75" fill="#fff"/><ellipse cx="1036" cy="500" rx="45" ry="75"/>
<path d="M500,340 L510,320 L498,300" stroke="#D23B2E" stroke-width="2.6"/>
''')+t(520,545,'2',130)+t(800,535,'4',90)+t(1018,522,'1',55)
 +t(690,520,'.',70)+t(935,520,'.',70)
 +xh(270,520,1.25,-18,'<path d="M300,470 L440,455 M305,505 L440,520"/><path d="M240,578 L200,640 M272,585 L250,650"/><path d="M180,470 q-14,8 -6,22 M170,505 q-14,8 -6,22" stroke-width="2"/>')
 +f'<path filter="url(#w)" d="M1070,410 C1110,380 1110,330 1070,320" fill="none" stroke="{OR}" stroke-width="3.4" stroke-linecap="round" marker-end="url(#ah)"/>'
 +f'<path filter="url(#w)" d="M470,250 C520,215 600,215 640,250" fill="none" stroke="{OR}" stroke-width="3.4" stroke-linecap="round" stroke-dasharray="12 8" marker-end="url(#ah)"/>'
 +t(420,200,'MAJOR – bricht was',48,RD)+t(740,330,'MINOR – neu',42)+t(950,290,'PATCH – Fix',42)
 +t(150,380,'schwer',40,BL)+t(1175,410,'leicht',38,BL))
# 03 Kanarienvogel
imgs['03-kanarienvogel']=(11, G('''
<path d="M80,470 L600,468 M760,470 L1520,468"/>
<path d="M600,468 L606,880 M760,470 L754,880"/>
<path d="M640,520 q10,6 4,14 M720,560 q-8,6 -2,14 M650,780 q8,6 2,14" stroke-width="1.8"/>
<path d="M520,412 Q600,380 682,400 L682,640" stroke-width="2.4"/>
<path d="M640,690 Q640,640 682,640 Q724,640 724,690 L724,760 L640,760 Z" fill="#fff"/>
<path d="M654,662 L654,760 M668,648 L668,760 M682,644 L682,760 M696,648 L696,760 M710,662 L710,760" stroke-width="1.6"/>
<path d="M662,740 q8,-26 26,-22 q14,4 10,20 q-6,10 -24,8 z" fill="#fff" stroke-width="2.2"/><circle cx="690" cy="724" r="2.2" fill="#111"/>
<path d="M700,724 l8,2 l-8,3" stroke-width="2"/>
<path d="M676,722 L672,690 L690,696 L674,704" stroke-width="2"/>
<path d="M940,420 L940,468 M1460,420 L1460,468 M940,425 Q1200,450 1460,425" stroke-width="2.4"/>
<g stroke-width="2.6">
<circle cx="1000" cy="380" r="11"/><path d="M1000,391 L1000,430 M1000,430 L991,466 M1000,430 L1009,466 M988,404 L1012,404"/>
<circle cx="1070" cy="376" r="11"/><path d="M1070,387 L1070,428 M1070,428 L1061,466 M1070,428 L1079,466 M1058,400 L1082,404"/>
<circle cx="1140" cy="382" r="11"/><path d="M1140,393 L1140,432 M1140,432 L1131,466 M1140,432 L1149,466 M1128,406 L1152,406"/>
<circle cx="1210" cy="378" r="11"/><path d="M1210,389 L1210,430 M1210,430 L1201,466 M1210,430 L1219,466 M1198,402 L1222,402"/>
<circle cx="1280" cy="380" r="11"/><path d="M1280,391 L1280,430 M1280,430 L1271,466 M1280,430 L1289,466 M1268,404 L1292,404"/>
<circle cx="1350" cy="376" r="11"/><path d="M1350,387 L1350,428 M1350,428 L1341,466 M1350,428 L1359,466 M1338,400 L1362,400"/>
<circle cx="1420" cy="382" r="11"/><path d="M1420,393 L1420,432 M1420,432 L1411,466 M1420,432 L1429,466 M1408,406 L1432,406"/>
</g>
<path d="M260,350 A70,70 0 0 1 400,350" fill="#fff"/><path d="M330,350 L362,300" stroke-width="2.6"/><path d="M272,330 l10,4 M388,330 l-10,4" stroke-width="2"/>
''')
 +xh(470,425,1.0,8,'<path d="M500,415 L520,412 M498,440 L522,414"/><path d="M450,472 L430,470 M478,474 L470,470"/>')
 +f'<path filter="url(#w)" d="M735,690 C820,560 760,360 620,320 C540,300 460,310 410,330" fill="none" stroke="{BL}" stroke-width="2.4" stroke-dasharray="4 8" stroke-linecap="round" marker-end="url(#ahb)"/>'
 +f'<path filter="url(#w)" d="M800,300 C880,240 960,240 1040,300" fill="none" stroke="{OR}" stroke-width="3.4" stroke-linecap="round" stroke-dasharray="14 10" marker-end="url(#ah)"/>'
 +t(760,640,'erst 5 %',46,OR)+t(250,280,'alles ok?',42,BL)+t(820,225,'dann alle',46,OR)+t(1150,540,'warten …',42))
# 04 Drachen
imgs['04-drachen']=(5, G('''
<path d="M80,720 L1520,718"/>
<g transform="rotate(28 1240 230)"><path d="M1240,110 L1320,230 L1240,380 L1160,230 Z" fill="#fff"/><path d="M1240,110 L1240,380 M1160,230 L1320,230" stroke-width="2"/></g>
<path d="M1170,360 q-20,30 0,50 t0,50 t-10,40" stroke-width="2"/><path d="M1162,400 l-12,-8 l4,14 z M1160,450 l-12,-8 l4,14 z" stroke-width="1.8"/>
<path d="M1240,300 C1000,360 700,420 500,600" stroke-width="2"/>
<circle cx="470" cy="620" r="40" fill="#fff"/><circle cx="470" cy="620" r="10"/><path d="M470,620 L520,650 L528,670" stroke-width="3"/>
<path d="M180,716 L300,716 L290,690 L190,690 Z" fill="#fff"/><path d="M200,690 L240,668 L280,690" fill="#fff"/>
''')+f'<g filter="url(#w)" fill="none" stroke="{RD}" stroke-width="2.6" stroke-linecap="round"><path d="M1340,150 q20,-20 40,0 t40,0 M1360,190 l30,-10 M1110,160 q-14,-18 6,-30 q16,14 -6,30"/></g>'
 +t(1210,260,'v2.4',40,'#111',28)
 +xh(390,640,1.05,-6,'<path d="M420,630 L462,618 M422,650 L500,660"/><path d="M372,690 L362,718 M402,692 L408,718"/>')
 +f'<path filter="url(#w)" d="M1100,380 C900,430 720,480 600,560" fill="none" stroke="{OR}" stroke-width="3.4" stroke-linecap="round" stroke-dasharray="14 10" marker-end="url(#ah)"/>'
 +t(1330,120,'stürzt ab',50,RD)+t(760,420,'zurückholen',48,OR,-14)+t(150,780,'v2.3 bereit',42,BL)+t(200,650,'Plan B',40))
# 05 Waage
imgs['05-waage']=(9, G('''
<path d="M640,780 L960,780 M800,780 L800,370"/>
<path d="M470,395 L1130,345" stroke-width="5"/>
<circle cx="800" cy="370" r="10" fill="#fff"/>
<path d="M490,394 L440,560 M490,394 L560,560 M1110,347 L1060,500 M1110,347 L1180,500" stroke-width="2"/>
<path d="M420,560 Q500,600 580,560" fill="#fff"/><path d="M1040,500 Q1120,540 1200,500" fill="#fff"/>
<rect x="445" y="520" width="42" height="40" fill="#fff"/><path d="M466,520 L466,560 M445,540 L487,540 M466,520 q-12,-14 -16,0 M466,520 q12,-14 16,0" stroke-width="2"/>
<rect x="497" y="530" width="34" height="30" fill="#fff"/><path d="M514,530 L514,560 M514,530 q-10,-12 -12,0 M514,530 q10,-12 12,0" stroke-width="2"/>
<rect x="468" y="488" width="30" height="30" fill="#fff"/><path d="M483,488 L483,518 M483,488 q-8,-12 -12,0 M483,488 q8,-12 12,0" stroke-width="2"/>
<path d="M720,470 A80,80 0 0 0 880,470" stroke-width="2.2"/><path d="M800,380 L760,532" stroke-width="2.4"/>
''')+'<g filter="url(#w)" fill="#111" stroke="#111" stroke-width="1.8">'+''.join(f'<ellipse cx="{x}" cy="{y}" rx="9" ry="6"/><path d="M{x-6},{y-5} l-6,-6 M{x},{y-6} l0,-8 M{x+6},{y-5} l6,-6 M{x-6},{y+5} l-6,6 M{x+6},{y+5} l6,6" fill="none"/>' for x,y in [(1080,495),(1110,488),(1140,496),(1165,490)])+'</g>'
 +xh(800,295,1.0,-4,'<path d="M770,290 L700,262 M830,284 L900,250"/><path d="M786,342 L782,366 M812,340 L818,364"/>')
 +t(390,640,'neue Funktionen',44)+t(1030,590,'offene Bugs',44,RD)+t(640,520,'Go?',44,OR)+t(890,520,'No-Go?',40,BL))
for name,(seed,body) in imgs.items():
    open(f'{sys.argv[1]}/{name}.html','w').write(HEAD.replace('SEED',str(seed))+body+TAIL)

"""Generate a provisional, evidence-linked Fortress specification for layout review.
All dimensions and repeated counts are estimates, not a survey or photogrammetry.
"""
import json
import math
from pathlib import Path

project=Path(__file__).resolve().parent
state=json.loads((project/'status.json').read_text())
original=next(project.glob('room_spec.*.draft.json'))
spec=json.loads(original.read_text())
spec.update(title='The Fortress — provisional venue blockout',
    review={'status':'reviewed','reviewer':'Codex visual interpretation',
            'basis':'Reviewed the combined movie contact sheet and source frames. Approved as an estimated layout illustration only; no user measurements or survey supplied.'},
    scale_status='PROVISIONAL / estimated 20 × 24 × 7.5 m envelope; dimensions, positions and counts are not measured.',
    room={'width':20,'depth':24,'height':7.5,'wall_thickness':0.2},
    spawn={'eye':[10,2,1.65],'look_at':[10,21,2]},
    materials={'wall':[.16,.18,.21],'floor':[.09,.115,.14],'stage':[.23,.25,.28],
               'trim':[.055,.065,.08],'seat':[.36,.59,.62],'bleacher':[.56,.64,.64],
               'metal':[.34,.38,.43],'screen':[.06,.45,.46],'display':[.79,.58,.20],
               'accent':[.12,.29,.36],'opening':[.045,.06,.08]},objects=[])
spec['assumptions'] += [
    'Nominal shell 20 m wide, 24 m deep and 7.5 m high is chosen for this visual blockout; not measured from images.',
    'Front is the stage end (+Y), left/right are defined while looking toward the stage. The origin is rear-left floor.',
    'Stage is estimated as 14 × 4.2 × 0.8 m; central seating and side tiers are representative counts and spacing.',
    'Wall panels, aisle widths, trusses, speaker boxes and fixture placeholders indicate observed categories, not manufacturer-accurate hardware.',
    'The suspended curved display is approximated by stepped box segments; overhead items attached to hidden wall groups are removed with that side for clarity.',
    'Rear boundary and doorway positions are provisional closures of incompletely observed geometry.',
    'Screens use plain colored materials. People, show beams and video content are excluded from permanent architecture.'
]
front=', '.join(spec['shell_evidence']['front']);rear=', '.join(spec['shell_evidence']['rear'])
left=', '.join(spec['shell_evidence']['left']);right=', '.join(spec['shell_evidence']['right']);ceiling=', '.join(spec['shell_evidence']['ceiling'])
def box(name,pos,size,mat,evidence,side=None,collision=False,surface=False):
    spec['objects'].append({'id':name,'position':[round(v,5) for v in pos],
        'size':[round(v,5) for v in size],'material':mat,'evidence':evidence+'; dimensions and position estimated',
        'cutaway_wall':side,'collision':collision,'placement_surface':surface})
box('floor',(10,12,-.12),(20.4,24.4,.24),'floor','Combined room references',collision=True,surface=True)
box('front-wall',(10,24.1,3.75),(20,.2,7.5),'wall',front,'front',True)
box('rear-wall',(10,-.1,3.75),(20,.2,7.5),'wall',rear+'; rear perimeter incomplete','rear',True)
box('left-wall',(-.1,12,3.75),(.2,24,7.5),'wall',left,'left',True)
box('right-wall',(20.1,12,3.75),(.2,24,7.5),'wall',right,'right',True)
box('ceiling',(10,12,7.6),(20,24,.2),'wall',ceiling,'ceiling',True)
box('stage-platform',(10,21.2,.4),(14,4.2,.8),'stage',front,collision=True,surface=True)
box('stage-backdrop',(10,23.45,2.7),(17,.25,4),'trim',front,'front')
box('stage-main-screen',(10,23.24,3.25),(10.8,.12,3.8),'screen',front,'front')
for side,x in [('left',2.3),('right',17.7)]:
    box(f'{side}-stage-screen',(x,22.7,3.9),(2.6,.15,1.7),'screen',front,'front')
    box(f'{side}-curtain',(x,23.1,2.7),(2.6,.18,4.5),'accent',front,'front')
    for step in range(4):
        box(f'{side}-stage-step-{step}',(3.6 if side=='left' else 16.4,18.1+step*.28,(step+1)*.1),
            (1.3,.28,(step+1)*.2),'metal',front,collision=True)
for index,x in enumerate((4.8,7.4,10,12.6,15.2)):
    box(f'stage-speaker-{index}',(x,18.65,.42),(.85,.62,.84),'trim',front,collision=True)
# Central chairs: two banks with a continuous center aisle and side circulation.
for row in range(9):
    y=5+row*1.23
    for bank,start in [('left',5.05),('right',11.35)]:
        for chair in range(6):
            x=start+chair*.65
            prefix=f'chair-{bank}-{row:02}-{chair:02}'
            ev='movie-2-reference_06_0023.2s.jpg, movie-2-reference_15_0061.1s.jpg; representative chair count'
            box(prefix+'-seat',(x,y,.47),(.52,.52,.09),'seat',ev)
            box(prefix+'-back',(x,y-.255,.79),(.52,.055,.57),'seat',ev)
            for dx in (-.21,.21):
                box(prefix+('-leg-l' if dx<0 else '-leg-r'),(x+dx,y,.23),(.035,.43,.46),'metal',ev)
# Four simplified inward-facing bleacher tiers along each side.
for side in ('left','right'):
    evidence=left if side=='left' else right
    for tier in range(4):
        x=.55+tier*.72 if side=='left' else 19.45-tier*.72
        top=(4-tier)*.33
        box(f'{side}-tier-{tier}',(x,10.9,top/2),(.72,13.8,top),'stage',evidence,collision=True)
        box(f'{side}-bench-seat-{tier}',(x,10.9,top+.43),(.57,13.55,.14),'bleacher',evidence)
        back=x-.28 if side=='left' else x+.28
        box(f'{side}-bench-back-{tier}',(back,10.9,top+.71),(.11,13.55,.5),'bleacher',evidence)
    # Small guardrails mark the raised rear tier, separate from cutaway walls.
    x=.13 if side=='left' else 19.87
    box(f'{side}-tier-rail',(x,10.9,2.35),(.05,14.1,.05),'metal',evidence)
    for j,y in enumerate((4,7.5,11,14.5,17.8)):
        box(f'{side}-rail-post-{j}',(x,y,1.82),(.05,.05,1.06),'metal',evidence)
    # Side display panels belong to their corresponding removable wall.
    for index,y in enumerate((6.2,10.8,15.4,19.3)):
        x=.12 if side=='left' else 19.88
        box(f'{side}-wall-display-{index}',(x,y,4.1),(.1,1.6,2.2),'display',evidence,side)
        box(f'{side}-wall-inset-{index}',(x, y-1.65,4.1),(.07,1.45,2.2),'accent',evidence,side)
# Rear panels mark incompletely seen access locations; no claim of door openings.
for i,x in enumerate((3.8,16.2)):
    box(f'rear-access-placeholder-{i}',(x,.025,1.25),(1.8,.05,2.5),'opening',rear,'rear')
# Sparse overhead rigging. Remove only the ceiling grid with the roof, keep rig visible.
for i,x in enumerate((3.6,16.4)):
    box(f'rig-longitudinal-{i}',(x,12,6.4),(.2,18,.2),'metal',ceiling)
for i,y in enumerate((7.5,14.5,20.8)):
    for z in (6.18,6.58):
        box(f'rig-cross-{i}-{int(z*100)}',(10,y,z),(14,.08,.08),'metal',ceiling)
    for j in range(15):
        box(f'rig-cross-web-{i}-{j}',(3+j,y,6.38),(.04,.08,.4),'metal',ceiling)
    for j,x in enumerate((4.4,6.6,8.8,11.2,13.4,15.6)):
        box(f'rig-fixture-{i}-{j}',(x,y,5.93),(.34,.4,.38),'trim',ceiling+'; generic fixture placeholder')
# Curved overhead ribbon: faceted box approximation, positioned above the audience.
for i in range(48):
    theta=2*math.pi*i/48
    x=10+5.4*math.cos(theta);y=12+3.5*math.sin(theta)
    box(f'overhead-ribbon-{i:02}',(x,y,5.4),(.65,.48,.8),'display',ceiling+'; curved display approximated as box segments')
for i,x in enumerate((2.5,7.5,12.5,17.5)):
    box(f'roof-beam-{i}',(x,12,7.13),(.24,24,.3),'metal',ceiling,'ceiling')
(project/'room_spec.provisional.json').write_text(json.dumps(spec,indent=2)+'\n')
print('Wrote provisional specification:',len(spec['objects']),'objects')

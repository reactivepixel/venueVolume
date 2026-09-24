"""Editable vector drawings of the visionOS prototype; no screenshot claims."""
from pathlib import Path
from html import escape

OUT = Path(__file__).resolve().parents[3] / "assets/design/venue-volume/visionos"
OUT.mkdir(parents=True, exist_ok=True)
CYAN, WHITE, MUTED = "#40e0f5", "#f4f8fa", "#a9bac3"
VALUES = [200, 128, 255, 64, 180, 0, 96, 224, 32, 160, 80, 255, 0, 112, 48, 192]


def text(x, y, value, size=16, fill=WHITE, weight=400, anchor="start"):
    return f'<text x="{x}" y="{y}" fill="{fill}" font-size="{size}" font-weight="{weight}" text-anchor="{anchor}">{escape(str(value))}</text>'


def rect(x, y, w, h, fill, radius=0, opacity=1, stroke="none"):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}" fill="{fill}" fill-opacity="{opacity}" stroke="{stroke}"/>'


def line(x1, y1, x2, y2, opacity=.25, color=MUTED, width=1):
    return f'<path d="M{x1} {y1}L{x2} {y2}" fill="none" stroke="{color}" stroke-opacity="{opacity}" stroke-width="{width}"/>'


def glass(x, y, w, h, radius=28):
    return rect(x, y+18, w, h, "#000", radius, .18) + rect(x, y, w, h, "url(#glass)", radius, 1, "#52646e")


def button(x, y, w, title, primary=False, h=46):
    return rect(x, y, w, h, CYAN if primary else "#596c77", 23, 1 if primary else .4) + text(x+w/2, y+h/2+6, title, 16, "#08292f" if primary else WHITE, 600, "middle")


def slider(x, y, w, value):
    level = (w-18)*value/255
    return rect(x, y+8, w, 6, "#708690", 3, .45) + rect(x, y+8, max(0.1, level+9), 6, CYAN, 3, 1 if value else 0) + f'<circle cx="{x+level+9}" cy="{y+11}" r="11" fill="{WHITE}"/>'


def cube(x, y, scale=1, selected=True):
    opacity = .12 if selected else .055
    return f'''<g id="transparent-cube" transform="translate({x} {y}) scale({scale})">
    <ellipse cx="130" cy="302" rx="130" ry="18" fill="#000" fill-opacity=".16"/>
    <path d="M20 72L130 12L240 72L130 136Z M20 72L130 136L130 270L20 206Z M130 136L240 72L240 206L130 270Z" fill="{CYAN}" fill-opacity="{opacity}" stroke="{CYAN}" stroke-width="{2 if selected else 1.4}" stroke-opacity="{1 if selected else .45}"/>
    <path d="M130 12V146L20 206M130 146L240 206" fill="none" stroke="{CYAN}" stroke-width="1" stroke-opacity=".3" stroke-dasharray="5 5"/>
    </g>'''


def tooltip(x, y, name="Front wash", selected=True):
    return '<g id="fixture-tooltip">' + glass(x, y, 264, 76, 22) + f'<circle cx="{x+22}" cy="{y+38}" r="4" fill="{CYAN if selected else MUTED}"/>' + text(x+40, y+31, name, 19, weight=600) + text(x+40, y+55, "U1 · 1–16", 14, MUTED) + text(x+233, y+43, "⌃", 22, CYAN) + '</g>'


def inspector(x, y, all_channels=False):
    rows = 8 if all_channels else 4
    height = 360 + rows*66
    s = '<g id="fixture-inspector">' + glass(x, y, 520, height)
    s += text(x+24, y+43, "Front wash", 26, weight=600) + text(x+475, y+42, "×", 27, MUTED)
    s += text(x+24, y+68, "GENERIC DMX · 8-BIT", 12, CYAN, 600)
    s += rect(x+24, y+86, 472, 48, "#122329", 14, .56) + text(x+40, y+117, "Front wash", 17)
    for i, (label, val) in enumerate([("Universe", "1"), ("Start address", "1"), ("Channels", "16  ⌄")]):
        px = x+24+i*161
        s += text(px, y+162, label, 13, MUTED) + rect(px, y+174, 150, 44, "#192930", 12, .65) + text(px+14, y+202, val, 19, weight=500)
    s += text(x+24, y+253, "Patch 1–16 · U1", 14, MUTED) + button(x+356, y+232, 140, "Apply patch", h=36)
    s += line(x+24, y+284, x+496, y+284)
    for i in range(rows*2):
        cx, cy = x+24+(i%2)*246, y+312+(i//2)*66
        s += text(cx, cy, f"CH {i+1:02d} · {i+1}", 13, MUTED, 600)
        s += text(cx+225, cy, VALUES[i], 18, CYAN, 600, "end")
        s += slider(cx, cy+13, 225, VALUES[i])
    fy = y+height-56
    s += button(x+24, fy, 174, "Zero channels", h=38) + button(x+376, fy, 120, "Remove", h=38)
    if not all_channels:
        s += rect(x+506, y+304, 3, 232, "#80959e", 2, .24) + rect(x+506, y+304, 3, 106, "#d4e5eb", 2, .7)
    return s + '</g>'


def debug(x, y, placing=False, synced=False):
    h = 584 if placing else 502
    s = '<g id="following-debug-panel">' + glass(x, y, 360, h)
    s += text(x+24, y+36, "VENUE VOLUME", 13, weight=700) + text(x+336, y+36, "DEBUG", 11, CYAN, 700, "end")
    s += text(x+24, y+92, "1", 42, weight=500) + text(x+58, y+90, "fixture", 17, MUTED) + text(x+336, y+88, "16 channels", 15, MUTED, 400, "end")
    s += f'<circle cx="{x+28}" cy="{y+120}" r="3" fill="{CYAN}"/>' + text(x+40, y+125, "World tracking active", 13, MUTED)
    s += button(x+24, y+146, 312, "×   Cancel placement" if placing else "+   Place fixture")
    shift = 82 if placing else 0
    if placing:
        s += text(x+24, y+223, "Look at the grid and pinch.", 16)
        s += text(x+24, y+260, "Distance", 13, MUTED) + slider(x+92, y+243, 138, 99) + text(x+336, y+260, "2.00 m", 13, MUTED, 400, "end")
    else:
        s += text(x+24, y+224, "Configure Front wash", 16)
    divider_y = y+248+shift
    s += line(x+24, divider_y, x+336, divider_y)
    s += text(x+24, divider_y+34, "Mock API", 17, weight=600) + text(x+336, divider_y+34, "Synced" if synced else "Unsynced", 13, CYAN if synced else MUTED, 400, "end")
    s += button(x+24, divider_y+53, 312, "Sync all configurations", primary=True)
    s += text(x+24, divider_y+123, "HTTP 200 · 1 fixture · 16 channels" if synced else "No configuration sent", 13, MUTED)
    s += text(x+24, divider_y+158, "Simulate API failure", 13, MUTED) + rect(x+294, divider_y+141, 42, 24, "#72858e", 12, .5) + f'<circle cx="{x+306}" cy="{divider_y+153}" r="9" fill="{WHITE}"/>'
    s += text(x+24, divider_y+194, "›   Last request · POST", 13, MUTED)
    s += text(x+24, divider_y+228, "Local mock · no DMX output", 11, MUTED) + text(x+336, divider_y+228, "Leave", 13, WHITE, 400, "end")
    return s + '</g>'


def header(title, sub, width):
    return text(56, 66, title, 26, weight=600) + text(56, 96, sub, 15, MUTED) + text(width-56, 66, "VENUE VOLUME", 12, CYAN, 700, "end")


def room():
    s = ""
    for y in [550, 665, 820, 950]:
        s += line(0, y, 1600, y, .1)
    for x in [-400, 0, 400, 800, 1200, 1600, 2000]:
        s += line(800, 340, x, 1000, .09)
    return s


def save(name, width, height, body):
    defs = '''<defs><linearGradient id="glass" x1="0" x2="1" y1="0" y2="1"><stop stop-color="#36464f"/><stop offset="1" stop-color="#24323a"/></linearGradient><radialGradient id="room"><stop stop-color="#233c45"/><stop offset="1" stop-color="#10171c"/></radialGradient></defs>'''
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" font-family="SF Pro, -apple-system, Helvetica Neue, Arial, sans-serif">{defs}'
    svg += rect(0, 0, width, height, "url(#room)") + body + '</svg>'
    (OUT / f"{name}.svg").write_text(svg)


scene = header("Fixture in space", "Selected fixture · expanded DMX controls · following debug panel", 1600) + room()
scene += inspector(56, 180) + cube(684, 414, 1) + tooltip(682, 302) + debug(1160, 224)
scene += text(814, 762, "Double-select the name", 18, weight=500, anchor="middle") + text(814, 790, "to expand or collapse controls.", 15, MUTED, anchor="middle")
scene += text(56, 937, "World-anchored fixture", 15, CYAN, 500) + text(1160, 780, "Head-following debug panel", 15, CYAN, 500)
scene += text(56, 970, "DESIGN DRAWING · Editable vectors · Sample configuration · Not a simulator screenshot", 12, MUTED)
save("01-spatial-interface", 1600, 1000, scene)

placement = header("Place a fixture", "Choose distance, look at the placement grid, then pinch to drop a transparent cube.", 1600) + room()
placement += rect(130, 220, 850, 490, CYAN, 16, .025, "#34545f")
for x in range(180, 981, 100):
    placement += line(x, 220, x, 710, .15, CYAN)
for y in range(270, 711, 80):
    placement += line(130, y, 980, y, .15, CYAN)
placement += cube(443, 360, .85, selected=False)
placement += f'<circle cx="554" cy="480" r="24" fill="none" stroke="{CYAN}" stroke-opacity=".65"/><circle cx="554" cy="480" r="3" fill="{WHITE}"/>'
placement += debug(1144, 185, placing=True)
placement += glass(315, 765, 480, 76, 24) + text(555, 797, "Look here, then pinch to place", 20, weight=500, anchor="middle") + text(555, 823, "Placement distance  2.00 m", 14, MUTED, anchor="middle")
placement += text(56, 943, "The grid follows the head; dropped fixtures stay in world space.", 16, MUTED)
placement += text(56, 974, "DESIGN DRAWING · Reticle and preview cube illustrate the gaze point; they are not implemented UI.", 12, MUTED)
save("02-placement", 1600, 1000, placement)

elements = header("Interface elements", "Full 16-channel inspector, cube states, name tooltip, and sync status", 1600)
elements += inspector(56, 170, all_channels=True) + debug(652, 170, synced=True)
elements += tooltip(1185, 205) + cube(1190, 326, .83)
elements += text(1317, 633, "Selected", 16, CYAN, 500, "middle")
elements += cube(1205, 705, .65, selected=False) + text(1290, 929, "Unselected", 16, MUTED, 400, "middle")
elements += glass(652, 754, 360, 190) + text(676, 790, "Mock sync · error state", 17, weight=600)
elements += text(676, 823, "HTTP 503 · Service unavailable", 15, "#ffc08a") + text(676, 851, "Configuration unchanged. Retry sync.", 13, MUTED)
elements += button(676, 877, 312, "Retry sync", primary=True)
elements += text(56, 1100, "16 channels · 0–255 integer values · one-based DMX patch · no physical lighting output", 16, MUTED)
elements += text(56, 1148, "DESIGN DRAWING · All UI labels and geometry remain editable on SVG import.", 12, MUTED)
save("03-interface-elements", 1600, 1200, elements)

launch = header("Enter venue", "Launch window · 620 × 620 pt", 1000)
launch += glass(190, 190, 620, 620, 36) + text(226, 242, "VENUE VOLUME", 14, CYAN, 700)
launch += text(226, 308, "Your space.", 44, weight=600) + text(226, 362, "Your fixtures.", 44, weight=600) + cube(670, 260, .32)
launch += text(226, 412, "Place virtual DMX fixtures in the room, shape their", 17, MUTED) + text(226, 438, "channels, and sync a complete mock configuration.", 17, MUTED)
launch += line(226, 466, 774, 466)
for i, value in enumerate(["Place fixture → look at the grid → pinch", "Select a cube to highlight its fixture", "Double-select its name to open DMX controls"]):
    launch += text(226, 505+i*42, f"0{i+1}", 13, CYAN, 600) + text(261, 505+i*42, value, 16)
launch += text(226, 640, "0 fixtures · 0 channels", 15, MUTED) + text(774, 640, "MOCK OUTPUT", 12, CYAN, 600, "end")
launch += button(226, 685, 548, "Enter venue", primary=True, h=54)
launch += text(226, 776, "Session-only prototype · Generic 8-bit channels · No physical output", 12, MUTED)
launch += text(56, 946, "DESIGN DRAWING · Based on apps/visionos/VenueVolume/Views/LaunchView.swift", 12, MUTED)
save("04-launch-window", 1000, 1000, launch)
print(f"Wrote four editable SVG drawings to {OUT}")

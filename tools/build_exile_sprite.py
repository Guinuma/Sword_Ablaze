"""Build original grid-aligned SVG sprite art; no source raster is resampled."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PALETTE = {
    "outline": "101b29", "dark": "263747", "steel": "496072",
    "ivory": "eee5cb", "shade": "bcb99e", "light": "fff3da",
    "teal": "23858d", "deep": "176578", "cyan": "53b8b4",
    "gold": "b88d4d", "ember": "ed874b", "eye": "f4c875",
}

def build():
    shapes = []
    def rect(x, y, w, h, color):
        shapes.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="#{PALETTE[color]}"/>')
    for row, view in enumerate(["front", "back", "side"]):
        for frame in range(9):
            ox, oy = frame * 24, row * 32
            dash = frame in (5, 6)
            hurt = frame in (7, 8)
            lean = 2 if dash else -1 if hurt else 0
            bob = -1 if frame in (2, 4) else 0
            def r(x, y, w, h, c):
                rect(ox + x + lean, oy + y + bob, w, h, c)
            # Identical ground contact, anatomy and hood proportions in every view.
            left = [0, -2, 0, 2, 0, -2, -1, 1, 0][frame]
            right = -left
            r(7, 20, 4, 7 + left, "outline")
            r(13, 20, 4, 7 + right, "outline")
            r(8, 21, 2, 4 + left, "steel")
            r(14, 21, 2, 4 + right, "dark")
            r(6 if not dash else 4, 26 + left, 5, 2, "outline")
            r(13, 26 + right, 6 if dash else 5, 2, "outline")
            r(6, 12, 12, 10, "outline")
            r(7, 13, 10, 7, "dark")
            r(7, 20, 10, 2, "gold")
            r(11, 20, 2, 2, "light")
            # Short turquoise mantle, with an uninterrupted back-facing cape.
            r(5, 11, 14, 4, "deep")
            r(6, 12, 12, 2, "teal")
            r(6, 12, 2, 7, "cyan")
            if view == "back":
                r(7, 13, 10, 10, "deep")
                r(8, 13, 3, 9, "teal")
                r(8, 22, 8, 1, "gold")
            elif view == "side":
                r(6, 13, 5, 8, "deep")
                r(7, 13, 2, 7, "teal")
                r(14, 15, 3, 3, "steel")
            else:
                r(8, 14, 2, 5, "gold")
                r(14, 14, 2, 5, "steel")
            # Hood outline, stepped corners and restrained highlight clusters.
            r(7, 2, 10, 11, "outline")
            r(6, 4, 12, 7, "outline")
            r(8, 2, 8, 1, "shade")
            r(7, 4, 10, 7, "ivory")
            r(8, 3, 8, 8, "ivory")
            r(8, 3, 5, 2, "light")
            r(7, 9, 2, 3, "shade")
            r(15, 5, 2, 6, "shade")
            if view == "back":
                r(11, 5, 1, 5, "shade")
                r(8, 11, 8, 2, "shade")
            elif view == "side":
                r(12, 6, 6, 5, "outline")
                r(13, 7, 5, 3, "shade")
                r(14, 7, 4, 1, "eye")
                r(12, 11, 4, 2, "ivory")
            else:
                r(9, 6, 6, 6, "outline")
                r(10, 7, 4, 4, "shade")
                r(10, 7, 1, 1, "eye")
                r(13, 7, 1, 1, "eye")
                r(11, 10, 2, 2, "ivory")
            if hurt:
                r(5, 14, 3, 3, "ivory")
                r(16, 16 if frame == 7 else 14, 2, 3, "shade")
            if dash:
                r(4, 16, 3, 4, "teal")
    # Four grounded defeat poses in the same grid and palette.
    for frame in range(4):
        ox, oy = frame * 24, 96
        def d(x,y,w,h,c): rect(ox+x,oy+y,w,h,c)
        if frame < 2:
            y = 6 + frame * 6
            d(6,y,12,11,"outline"); d(7,y+1,10,8,"ivory")
            d(12,y+4,6,3,"dark"); d(14,y+4,3,1,"eye")
            d(5,y+10,12,8,"deep"); d(6,y+11,5,6,"teal")
            d(10,26,10,2,"outline"); d(7,24,4,4,"steel")
        else:
            d(2,22,20,6,"outline"); d(3,23,8,4,"ivory")
            d(4,23,4,2,"light"); d(10,23,7,4,"deep")
            d(11,23,4,2,"teal"); d(17,25,5,2,"steel")
            if frame == 2:
                d(3,19,8,5,"ivory"); d(6,21,5,2,"dark")
    svg = '<svg xmlns="http://www.w3.org/2000/svg" width="216" height="128" viewBox="0 0 216 128">' + ''.join(shapes) + '</svg>\n'
    (ROOT / "assets/art/player/exile-native.svg").write_text(svg, encoding="utf-8")
    # Keep the SpriteFrames interface used by gameplay animation checks.
    entries = []
    for i in range(4):
        entries.append(f'[sub_resource type="AtlasTexture" id="Atlas_{i}"]\natlas = ExtResource("1")\nregion = Rect2({(i+1)*24}, 64, 24, 32)\n')
    frames = ', '.join('{"duration": 1.0, "texture": SubResource("Atlas_%d")}' % i for i in range(4))
    tres = '[gd_resource type="SpriteFrames" load_steps=6 format=3]\n[ext_resource type="Texture2D" path="res://assets/art/player/exile-native.svg" id="1"]\n' + '\n'.join(entries) + '[resource]\nanimations = [{"frames": [' + frames + '], "loop": true, "name": &"walk", "speed": 8.0}]\n'
    (ROOT / "assets/art/player/exile-native-walk.tres").write_text(tres, encoding="utf-8")

if __name__ == "__main__":
    build()

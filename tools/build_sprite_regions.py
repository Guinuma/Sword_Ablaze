"""Measure alpha bounds and write Godot atlas metadata; never rewrite source PNGs."""
import argparse
from pathlib import Path
from PIL import Image

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("image", type=Path)
    parser.add_argument("--grid", type=int, default=2)
    parser.add_argument("--animation", default="poses")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    source = args.image.resolve()
    im = Image.open(source)
    width, height = im.size
    grid = args.grid
    regions = []
    for index in range(grid * grid):
        x, y = index % grid * width // grid, index // grid * height // grid
        end_x, end_y = (index % grid + 1) * width // grid, (index // grid + 1) * height // grid
        alpha = im.getchannel("A").crop((x, y, end_x, end_y))
        bounds = alpha.point(lambda value: 255 if value > 32 else 0).getbbox()
        if bounds is None:
            raise ValueError(f"Empty cell {index}: {source}")
        regions.append((x + bounds[0], y + bounds[1], bounds[2] - bounds[0], bounds[3] - bounds[1]))
    relative = source.relative_to(root).as_posix()
    lines = [f'[gd_resource type="SpriteFrames" load_steps={len(regions)+2} format=3]', f'[ext_resource type="Texture2D" path="res://{relative}" id="1"]']
    for index, region in enumerate(regions):
        lines += [f'[sub_resource type="AtlasTexture" id="Frame_{index}"]', 'atlas = ExtResource("1")', 'region = Rect2(%d, %d, %d, %d)' % region]
    entries = ', '.join('{"duration": 1.0, "texture": SubResource("Frame_%d")}' % i for i in range(len(regions)))
    animations = '{"frames": [' + entries + '], "loop": false, "name": &"' + args.animation + '", "speed": 8.0}'
    if grid == 3:
        walk = ', '.join('{"duration": 1.0, "texture": SubResource("Frame_%d")}' % i for i in range(1, 5))
        animations += ', {"frames": [' + walk + '], "loop": true, "name": &"walk", "speed": 8.0}'
    lines += ['[resource]', 'animations = [' + animations + ']']
    source.with_name(source.stem + '-frames.tres').write_text('\n'.join(lines) + '\n', encoding='utf-8')

if __name__ == "__main__":
    main()

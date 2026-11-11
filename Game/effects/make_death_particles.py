"""Create the two small textures used by MIKO's death particles."""
from pathlib import Path
from PIL import Image
import math

out = Path(__file__).resolve().parent

smoke = Image.new('RGBA', (64, 64))
for y in range(64):
    for x in range(64):
        dx, dy = (x - 31.5) / 31.5, (y - 31.5) / 31.5
        r = math.hypot(dx, dy)
        edge = 1.0 + 0.09 * math.sin(math.atan2(dy, dx) * 5) + 0.05 * math.cos(math.atan2(dy, dx) * 8)
        opacity = max(0.0, 1.0 - (r / edge) ** 1.8) ** 2
        smoke.putpixel((x, y), (150, 161, 173, round(opacity * 205)))
smoke.save(out / 'death_smoke.png')

spark = Image.new('RGBA', (16, 16))
for y in range(16):
    for x in range(16):
        radius = math.hypot(x - 7.5, y - 7.5)
        if radius < 1.4:
            rgba = (255, 255, 244, 255)
        elif radius < 3.0:
            rgba = (255, 215, 115, round(230 * (3.0 - radius) / 1.6))
        elif radius < 6.5:
            rgba = (255, 122, 40, round(80 * (6.5 - radius) / 3.5))
        else:
            rgba = (0, 0, 0, 0)
        spark.putpixel((x, y), rgba)
spark.save(out / 'death_spark.png')

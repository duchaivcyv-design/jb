# Builds the dark-mode app icons (Icon-<Name>-Dark@2x/@3x.png) from the light ones. Needs numpy, scipy and Pillow.
# The glyph is separated from its background with an exact coverage value per pixel (no thresholds), so the
# shapes keep their outline; then it is painted again on a dark tile with a new gradient.
import os, sys
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'app', 'Resources') + '/'
S = 180
YY, XX = np.mgrid[0:S, 0:S].astype(np.float32)
X = (XX + .5) / S
Y = (YY + .5) / S

def load(n): return np.asarray(Image.open(R + f'Icon-{n}@3x.png').convert('RGB')).astype(np.float32)
def smooth(x, a, b):
    t = np.clip((x - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)

def dark_base():
    top = np.array([34, 34, 38], np.float32); bot = np.array([13, 13, 15], np.float32)
    base = top * (1 - Y[..., None]) + bot * Y[..., None]
    glow = np.exp(-(((X - .5) / .7) ** 2 + ((Y - 0.0) / .45) ** 2)) * 5
    return np.clip(base + glow[..., None], 0, 255)

def grad(stops, angle=0.5):
    # stops: list of colours spread along a diagonal (top-left -> bottom-right), angle = share of the vertical direction
    t = np.clip(X * (1 - angle) + Y * angle, 0, 1)
    pos = np.linspace(0, 1, len(stops))
    out = np.zeros((S, S, 3), np.float32)
    for c in range(3):
        out[..., c] = np.interp(t, pos, [s[c] for s in stops])
    return out

def comp(base, color, alpha):
    return base * (1 - alpha[..., None]) + color * alpha[..., None]

def fit_background(a, mask):
    # quadratic surface per channel, fitted on the pixels that really are background
    terms = np.stack([np.ones_like(X), X, Y, X * Y, X * X, Y * Y], -1)
    bg = np.zeros_like(a)
    m = mask.reshape(-1)
    for c in range(3):
        coef, *_ = np.linalg.lstsq(terms.reshape(-1, 6)[m], a[..., c].reshape(-1)[m], rcond=None)
        bg[..., c] = terms @ coef
    return np.clip(bg, 0, 255)

def white_coverage(a):
    # pure white glyph over a smooth background:  p = k*255 + (1-k)*bg  ->  k per pixel, exactly
    mask = a.min(axis=2) < 150
    for _ in range(3):
        bg = fit_background(a, mask)
        w = 255 - bg
        k = ((a - bg) * w).sum(axis=2) / np.maximum((w * w).sum(axis=2), 1)   # least squares over the 3 channels
        k = np.clip(k, 0, 1)
        mask = k < 0.01
    return k, bg

def dark_glyph_coverage(a):
    # coloured glyph over a light background: coverage = distance from the background relative to the local core distance
    corner = np.concatenate([a[:6, :6].reshape(-1, 3), a[:6, -6:].reshape(-1, 3), a[-6:, :6].reshape(-1, 3), a[-6:, -6:].reshape(-1, 3)])
    mask = np.zeros((S, S), bool); mask[:8, :8] = mask[:8, -8:] = mask[-8:, :8] = mask[-8:, -8:] = True
    for _ in range(3):
        bg = fit_background(a, mask)
        d = np.sqrt(((a - bg) ** 2).sum(axis=2))
        core = ndi.maximum_filter(d, size=7)
        k = np.where(d > 6, d / np.maximum(core, 1), 0)
        k = np.clip(k, 0, 1)
        mask = d < 5
    return k, bg

def glyph_colour(a, bg, k):
    # un-mix the background, then spread the colours of the solid core outwards so the edge has no light fringe
    solid = k > 0.92
    raw = (a - bg * (1 - k[..., None])) / np.maximum(k[..., None], 0.05)
    idx = ndi.distance_transform_edt(~solid, return_distances=False, return_indices=True)
    return raw[idx[0], idx[1]]

def save(n, img):
    im = Image.fromarray(np.clip(np.rint(img), 0, 255).astype(np.uint8))
    im.save(R + f'Icon-{n}-Dark@3x.png', optimize=True)
    im.resize((120, 120), Image.LANCZOS).save(R + f'Icon-{n}-Dark@2x.png', optimize=True)
    return im

out = {}
base = dark_base()

def white_icon(name):
    # the white glyph takes exactly the colours of the original background gradient (fitted and carried under the glyph)
    k, bg = white_coverage(load(name))
    if len(sys.argv) > 2: print(name, 'bg corners TL/TR/BL/BR', [bg[y, x].round().tolist() for y, x in ((4, 4), (4, 175), (175, 4), (175, 175))])
    # Dark gradients (Dopamine, Github) would vanish on the dark tile: lift them with one gain, same hues and same gradient
    solid = k > 0.5
    peak = np.percentile(bg.max(axis=2)[solid], 95)
    if peak < 215:
        gain = 215 / peak
        top = bg[bg.max(axis=2) >= peak - 1].mean(axis=0)
        bg = np.clip(bg * gain, 0, 255) * 0.82 + top * gain * 0.18
    out[name] = save(name, comp(base, np.clip(bg, 0, 255), k))

for n in ('SideStore', 'Dopamine', 'Sileo', 'Github'): white_icon(n)

# Chimera: the glyph keeps its own colours
a = load('Chimera'); k, bg = dark_glyph_coverage(a)
out['Chimera'] = save('Chimera', comp(base, glyph_colour(a, bg, k), k))

# Default: the original rainbow, colours recovered without the light background
a = load('Default'); k, bg = dark_glyph_coverage(a)
col = glyph_colour(a, bg, k)
out['Default'] = save('Default', comp(base, col, k))

# LiveContainer: rounded plate, blue ring, dark tile with the blueprint grid, glyph in a blue gradient
a = load('LiveContainer'); r = a[..., 0]
frame_or_tile = r > 60
plate = ndi.binary_fill_holes(frame_or_tile)                     # everything inside the outer edge of the frame
plate_a = np.clip(ndi.gaussian_filter(plate.astype(np.float32), 0.7), 0, 1)
tile_a = smooth(r, 150, 215) * plate_a                          # the white tile (grid lines are a little darker than it)
ring_glyph = (1 - smooth(r, 25, 100)) * plate_a * (1 - tile_a)   # blue ring + glyph: coverage from the red channel
_, lcbg = white_coverage(a)
plate_col = base * 0.72 + lcbg * 0.28 + 6      # dark plate tinted with the original blue
img = comp(base, plate_col, plate_a * 0.96)
# 1 px light edge on the top of the plate
edge = np.clip(plate_a - ndi.shift(plate_a, (2, 0), order=1, mode='nearest'), 0, 1)
img = comp(img, np.array([96, 100, 112], np.float32), edge * 0.55)
tile_col = np.stack([12 + 6 * Y, 16 + 8 * Y, 30 + 14 * Y], -1)      # very dark navy
img = comp(img, tile_col, tile_a)
grid = smooth(244 - a.min(axis=2), 6, 36) * tile_a              # the faint blueprint lines of the tile
img = comp(img, np.array([44, 54, 84], np.float32), grid * 0.9)
img = comp(img, a, ring_glyph)       # ring and glyph keep the exact blue of the original
out['LiveContainer'] = save('LiveContainer', img)

if len(sys.argv) > 1:
    names = ['Default', 'SideStore', 'LiveContainer', 'Dopamine', 'Chimera', 'Sileo', 'Github']
    sheet = Image.new('RGB', (S * 7 + 80, S * 2 + 30), (110, 110, 110))
    for i, n in enumerate(names):
        sheet.paste(Image.open(R + f'Icon-{n}@3x.png'), (10 + i * (S + 10), 10))
        sheet.paste(out[n], (10 + i * (S + 10), S + 20))
    sheet.save(sys.argv[1])

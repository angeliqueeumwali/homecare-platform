"""Generate flat-design service category images as PNG files.

Pure standard library (zlib + struct) so no image library is required.
Shapes are rasterised with per-row span filling, then downsampled 4x for
anti-aliasing. Colours come from the Homecare navy/white design palette.
"""

import math
import os
import struct
import zlib

OUT_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "app",
    "static",
    "services",
)

SIZE = 256
SS = 4
CANVAS = SIZE * SS

NAVY = (0x14, 0x2B, 0x4A)
NAVY_DEEP = (0x0B, 0x1F, 0x38)
NAVY_SECONDARY = (0x20, 0x3D, 0x63)
WHITE = (0xFF, 0xFF, 0xFF)

BG_TOP = NAVY
BG_BOTTOM = NAVY_SECONDARY


class Canvas:
    def __init__(self, width, height, background):
        self.w = width
        self.h = height
        self.buf = bytearray(background * (width * height))

    def span(self, y, x0, x1, color, alpha=1.0):
        if y < 0 or y >= self.h:
            return
        x0 = max(0, int(round(x0)))
        x1 = min(self.w, int(round(x1)))
        if x1 <= x0:
            return
        if alpha >= 1.0:
            self.buf[y * self.w * 3 + x0 * 3 : y * self.h * 3 + x1 * 3] = bytes(color) * (x1 - x0)
            return
        inv = 1.0 - alpha
        for x in range(x0, x1):
            i = (y * self.w + x) * 3
            for c in range(3):
                self.buf[i + c] = int(self.buf[i + c] * inv + color[c] * alpha)

    def vertical_gradient(self, top, bottom):
        for y in range(self.h):
            t = y / max(1, self.h - 1)
            color = tuple(
                int(top[c] + (bottom[c] - top[c]) * t) for c in range(3)
            )
            self.buf[y * self.w * 3 : (y + 1) * self.w * 3] = bytes(color) * self.w


def fill_circle(cv, cx, cy, r, color, alpha=1.0):
    for y in range(int(cy - r) - 1, int(cy + r) + 2):
        dy = y - cy
        if abs(dy) > r:
            continue
        hw = math.sqrt(max(0.0, r * r - dy * dy))
        cv.span(y, cx - hw, cx + hw + 1, color, alpha)


def fill_ring(cv, cx, cy, r, thickness, color, alpha=1.0):
    inner = r - thickness
    for y in range(int(cy - r) - 1, int(cy + r) + 2):
        dy = y - cy
        if abs(dy) > r:
            continue
        hw = math.sqrt(max(0.0, r * r - dy * dy))
        if abs(dy) < inner:
            iw = math.sqrt(max(0.0, inner * inner - dy * dy))
            cv.span(y, cx - hw, cx - iw, color, alpha)
            cv.span(y, cx + iw, cx + hw + 1, color, alpha)
        else:
            cv.span(y, cx - hw, cx + hw + 1, color, alpha)


def fill_rect(cv, x0, y0, x1, y1, color, alpha=1.0):
    for y in range(int(y0), int(y1) + 1):
        cv.span(y, x0, x1 + 1, color, alpha)


def fill_round_rect(cv, x0, y0, x1, y1, radius, color, alpha=1.0):
    for y in range(int(y0) - 1, int(y1) + 2):
        if y < y0:
            dy = y0 - y
        elif y > y1:
            dy = y - y1
        else:
            dy = 0
        if dy >= radius:
            cv.span(y, x0, x1 + 1, color, alpha)
            continue
        inset = radius - math.sqrt(max(0.0, radius * radius - dy * dy))
        cv.span(y, x0 + inset, x1 - inset, color, alpha)


def fill_polygon(cv, points, color, alpha=1.0):
    ys = [p[1] for p in points]
    for y in range(int(min(ys)), int(max(ys)) + 1):
        crossings = []
        n = len(points)
        for i in range(n):
            x1, y1 = points[i]
            x2, y2 = points[(i + 1) % n]
            if (y1 <= y < y2) or (y2 <= y < y1):
                t = (y - y1) / (y2 - y1)
                crossings.append(x1 + t * (x2 - x1))
        crossings.sort()
        for i in range(0, len(crossings) - 1, 2):
            cv.span(y, crossings[i], crossings[i + 1], color, alpha)


def sparkle(cv, cx, cy, r, color, alpha=1.0):
    """Four-point sparkle: concave diamond built from two quadratic curves."""
    k = r * 0.28
    fill_polygon(
        cv,
        [
            (cx, cy - r),
            (cx + k, cy - k),
            (cx + r, cy),
            (cx + k, cy + k),
            (cx, cy + r),
            (cx - k, cy + k),
            (cx - r, cy),
            (cx - k, cy - k),
        ],
        color,
        alpha,
    )
    for sign in (-1, 1):
        fill_circle(cv, cx + sign * r * 0.95, cy - r * 0.75, r * 0.13, color, alpha)


def downsample(cv, factor):
    w = cv.w // factor
    h = cv.h // factor
    out = bytearray(w * h * 3)
    n = factor * factor
    for y in range(h):
        for x in range(w):
            r = g = b = 0
            for dy in range(factor):
                base = ((y * factor + dy) * cv.w + x * factor) * 3
                for dx in range(factor):
                    i = base + dx * 3
                    r += cv.buf[i]
                    g += cv.buf[i + 1]
                    b += cv.buf[i + 2]
            o = (y * w + x) * 3
            out[o] = r // n
            out[o + 1] = g // n
            out[o + 2] = b // n
    return w, h, out


def write_png(path, w, h, rgb):
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        raw.extend(rgb[y * w * 3 : (y + 1) * w * 3])

    def chunk(tag, data):
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    with open(path, "wb") as fh:
        fh.write(png)


def new_canvas():
    cv = Canvas(CANVAS, CANVAS, BG_TOP)
    cv.vertical_gradient(BG_TOP, BG_BOTTOM)
    return cv


def icon_housekeeping(cv, s):
    sparkle(cv, s * 0.5, s * 0.5, s * 0.30, WHITE)
    sparkle(cv, s * 0.80, s * 0.24, s * 0.11, WHITE, 0.85)


def icon_laundry(cv, s):
    fill_round_rect(cv, s * 0.20, s * 0.16, s * 0.80, s * 0.84, s * 0.10, WHITE)
    fill_rect(cv, s * 0.20, s * 0.16, s * 0.80, s * 0.34, NAVY)
    fill_circle(cv, s * 0.38, s * 0.58, s * 0.07, NAVY)
    fill_circle(cv, s * 0.62, s * 0.58, s * 0.07, NAVY)


def icon_cooking(cv, s):
    fill_rect(cv, s * 0.30, s * 0.22, s * 0.70, s * 0.26, WHITE)
    fill_round_rect(cv, s * 0.20, s * 0.30, s * 0.80, s * 0.78, s * 0.12, WHITE)
    fill_rect(cv, s * 0.44, s * 0.08, s * 0.56, s * 0.20, WHITE)
    fill_rect(cv, s * 0.30, s * 0.50, s * 0.70, s * 0.56, NAVY)


def icon_elderly(cv, s):
    fill_circle(cv, s * 0.38, s * 0.38, s * 0.13, WHITE)
    fill_circle(cv, s * 0.62, s * 0.38, s * 0.13, WHITE)
    fill_polygon(
        cv,
        [
            (s * 0.50, s * 0.60),
            (s * 0.86, s * 0.90),
            (s * 0.14, s * 0.90),
        ],
        WHITE,
    )


def icon_child_care(cv, s):
    fill_circle(cv, s * 0.34, s * 0.34, s * 0.15, WHITE)
    fill_circle(cv, s * 0.66, s * 0.34, s * 0.15, WHITE)
    fill_round_rect(cv, s * 0.16, s * 0.56, s * 0.50, s * 0.88, s * 0.08, WHITE)
    fill_round_rect(cv, s * 0.50, s * 0.56, s * 0.84, s * 0.88, s * 0.08, WHITE)


def icon_pet_care(cv, s):
    fill_circle(cv, s * 0.30, s * 0.36, s * 0.10, WHITE)
    fill_circle(cv, s * 0.50, s * 0.26, s * 0.10, WHITE)
    fill_circle(cv, s * 0.70, s * 0.36, s * 0.10, WHITE)
    fill_circle(cv, s * 0.50, s * 0.62, s * 0.22, WHITE)


def icon_home_repair(cv, s):
    fill_round_rect(cv, s * 0.40, s * 0.36, s * 0.60, s * 0.90, s * 0.06, WHITE)
    fill_round_rect(cv, s * 0.16, s * 0.16, s * 0.56, s * 0.40, s * 0.08, WHITE)
    fill_circle(cv, s * 0.66, s * 0.28, s * 0.10, NAVY)
    fill_circle(cv, s * 0.50, s * 0.62, s * 0.05, NAVY)


def icon_medical(cv, s):
    fill_round_rect(cv, s * 0.18, s * 0.40, s * 0.82, s * 0.60, s * 0.04, WHITE)
    fill_round_rect(cv, s * 0.40, s * 0.18, s * 0.60, s * 0.82, s * 0.04, WHITE)


def icon_companionship(cv, s):
    fill_ring(cv, s * 0.38, s * 0.5, s * 0.26, s * 0.09, WHITE)
    fill_ring(cv, s * 0.62, s * 0.5, s * 0.26, s * 0.09, WHITE)


def icon_garden(cv, s):
    fill_circle(cv, s * 0.50, s * 0.22, s * 0.10, WHITE)
    fill_rect(cv, s * 0.46, s * 0.28, s * 0.54, s * 0.88, WHITE)
    for sign, cy in ((-1, 0.50), (1, 0.70)):
        fill_circle(cv, s * (0.50 + sign * 0.22), s * cy, s * 0.14, WHITE)
        fill_rect(cv, s * (0.50 + sign * 0.22), s * cy, s * 0.50, s * cy, NAVY)


ICONS = {
    "housekeeping": icon_housekeeping,
    "laundry": icon_laundry,
    "cooking": icon_cooking,
    "elderly-care": icon_elderly,
    "child-care": icon_child_care,
    "pet-care": icon_pet_care,
    "home-repair": icon_home_repair,
    "medical-nursing": icon_medical,
    "companionship": icon_companionship,
    "gardening": icon_garden,
}


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for slug, icon in ICONS.items():
        cv = new_canvas()
        icon(cv, CANVAS)
        w, h, rgb = downsample(cv, SS)
        path = os.path.join(OUT_DIR, f"{slug}.png")
        write_png(path, w, h, rgb)
        print(f"wrote {path} ({os.path.getsize(path)} bytes)")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Cairo prototype of the Legacy Surf iOS 6 skin primitives.

Mirrors the Core Graphics drawing in Classes/RBClassicSkin.m (same unit
coordinates and colors) so shapes can be checked without an iOS 6 device.
Coordinates are UIKit points (y down); surfaces render at 2x. Used by
preview.py.
"""
import math
import cairo

S = 2.0  # retina scale


def rgb(r, g, b, a=1.0):
    return (r / 255.0, g / 255.0, b / 255.0, a)


def set_color(ctx, c):
    ctx.set_source_rgba(*c)


def vgrad(ctx, x, y, w, h, stops):
    """stops: list of (offset, color)"""
    pat = cairo.LinearGradient(0, y, 0, y + h)
    for off, c in stops:
        pat.add_color_stop_rgba(off, *c)
    ctx.save()
    ctx.rectangle(x, y, w, h)
    ctx.clip()
    ctx.set_source(pat)
    ctx.paint()
    ctx.restore()


def rounded(ctx, x, y, w, h, r):
    r = max(0.0, min(r, w / 2.0, h / 2.0))
    ctx.new_sub_path()
    ctx.arc(x + w - r, y + r, r, -math.pi / 2, 0)
    ctx.arc(x + w - r, y + h - r, r, 0, math.pi / 2)
    ctx.arc(x + r, y + h - r, r, math.pi / 2, math.pi)
    ctx.arc(x + r, y + r, r, math.pi, 3 * math.pi / 2)
    ctx.close_path()


# ------------------------------------------------------------------ glyphs

def glyph_paths(ctx, icon, ox, oy, s):
    """Draw glyph `icon` in the current source, as RBDrawClassicGlyph does."""
    P = lambda x, y: (ox + x * s, oy + y * s)
    R = lambda x, y, w, h: (ox + x * s, oy + y * s, w * s, h * s)

    def line(x0, y0, x1, y1, width, cap=cairo.LINE_CAP_ROUND):
        ctx.move_to(*P(x0, y0))
        ctx.line_to(*P(x1, y1))
        ctx.set_line_width(width * s)
        ctx.set_line_cap(cap)
        ctx.stroke()

    def clear(draw):
        ctx.save()
        ctx.set_operator(cairo.OPERATOR_CLEAR)
        draw()
        ctx.fill()
        ctx.restore()

    def quad(x0, y0, cx, cy, x1, y1):
        # quadratic -> cubic
        c1 = (x0 + 2.0 / 3.0 * (cx - x0), y0 + 2.0 / 3.0 * (cy - y0))
        c2 = (x1 + 2.0 / 3.0 * (cx - x1), y1 + 2.0 / 3.0 * (cy - y1))
        ctx.curve_to(c1[0], c1[1], c2[0], c2[1], x1, y1)

    if icon in ("back", "forward"):
        back = icon == "back"
        tip, base = (0.17, 0.78) if back else (0.83, 0.22)
        ctx.move_to(*P(tip, 0.5))
        ctx.line_to(*P(base, 0.16))
        ctx.line_to(*P(base, 0.84))
        ctx.close_path()
        ctx.set_line_join(cairo.LINE_JOIN_ROUND)
        ctx.set_line_width(s * 0.07)
        ctx.fill_preserve()
        ctx.stroke()
    elif icon in ("up", "down"):
        up = icon == "up"
        ctx.move_to(*P(0.5, 0.24 if up else 0.76))
        ctx.line_to(*P(0.86, 0.74 if up else 0.26))
        ctx.line_to(*P(0.14, 0.74 if up else 0.26))
        ctx.close_path()
        ctx.set_line_join(cairo.LINE_JOIN_ROUND)
        ctx.set_line_width(s * 0.06)
        ctx.fill_preserve()
        ctx.stroke()
    elif icon == "share":
        rounded(ctx, *R(0.10, 0.36, 0.64, 0.52), s * 0.07)
        ctx.set_line_width(s * 0.085)
        ctx.stroke()
        clear(lambda: ctx.rectangle(*R(0.42, 0.24, 0.50, 0.34)))
        x0, y0 = P(0.30, 0.74)
        cx, cy = P(0.30, 0.38)
        x1, y1 = P(0.66, 0.36)
        ctx.move_to(x0, y0)
        quad(x0, y0, cx, cy, x1, y1)
        ctx.set_line_width(s * 0.12)
        ctx.set_line_cap(cairo.LINE_CAP_ROUND)
        ctx.stroke()
        ctx.move_to(*P(0.95, 0.36))
        ctx.line_to(*P(0.62, 0.12))
        ctx.line_to(*P(0.62, 0.60))
        ctx.close_path()
        ctx.set_line_join(cairo.LINE_JOIN_ROUND)
        ctx.set_line_width(s * 0.04)
        ctx.fill_preserve()
        ctx.stroke()
    elif icon == "book":
        def qto(cx, cy, x1, y1):
            x0, y0 = ctx.get_current_point()
            c = P(cx, cy)
            e = P(x1, y1)
            quad(x0, y0, c[0], c[1], e[0], e[1])
        ctx.move_to(*P(0.50, 0.30))
        qto(0.28, 0.14, 0.07, 0.25)
        ctx.line_to(*P(0.07, 0.80))
        qto(0.28, 0.69, 0.50, 0.84)
        qto(0.72, 0.69, 0.93, 0.80)
        ctx.line_to(*P(0.93, 0.25))
        qto(0.72, 0.14, 0.50, 0.30)
        ctx.close_path()
        ctx.move_to(*P(0.50, 0.30))
        ctx.line_to(*P(0.50, 0.84))
        ctx.set_line_width(s * 0.075)
        ctx.set_line_join(cairo.LINE_JOIN_ROUND)
        ctx.stroke()
    elif icon == "tabs":
        rounded(ctx, *R(0.10, 0.10, 0.56, 0.56), s * 0.07)
        ctx.set_line_width(s * 0.08)
        ctx.stroke()
        clear(lambda: rounded(ctx, *R(0.27, 0.27, 0.71, 0.71), s * 0.12))
        rounded(ctx, *R(0.34, 0.34, 0.56, 0.56), s * 0.07)
        ctx.fill()
    elif icon == "more":
        for i in range(3):
            x = 0.20 + 0.30 * i
            cx, cy = P(x, 0.5)
            ctx.arc(cx, cy, 0.095 * s, 0, 2 * math.pi)
            ctx.fill()
    elif icon == "reload":
        cx, cy = P(0.48, 0.54)
        r = s * 0.29
        start = math.radians(-40)
        end = math.radians(245)
        ctx.arc(cx, cy, r, start, end)  # clockwise in y-down space
        ctx.set_line_width(s * 0.115)
        ctx.set_line_cap(cairo.LINE_CAP_BUTT)
        ctx.stroke()
        ex, ey = cx + r * math.cos(end), cy + r * math.sin(end)
        tx, ty = -math.sin(end), math.cos(end)
        nx, ny = math.cos(end), math.sin(end)
        L, H = s * 0.24, s * 0.17
        ctx.move_to(ex + tx * L, ey + ty * L)
        ctx.line_to(ex + nx * H, ey + ny * H)
        ctx.line_to(ex - nx * H, ey - ny * H)
        ctx.close_path()
        ctx.fill()
    elif icon in ("stop", "close"):
        w = 0.13 if icon == "stop" else 0.14
        line(0.25, 0.25, 0.75, 0.75, w)
        line(0.75, 0.25, 0.25, 0.75, w)
    elif icon == "plus":
        line(0.5, 0.18, 0.5, 0.82, 0.15, cairo.LINE_CAP_SQUARE)
        line(0.18, 0.5, 0.82, 0.5, 0.15, cairo.LINE_CAP_SQUARE)
    elif icon == "search":
        cx, cy = P(0.40, 0.40)
        ctx.arc(cx, cy, 0.26 * s, 0, 2 * math.pi)
        ctx.set_line_width(s * 0.10)
        ctx.stroke()
        line(0.62, 0.62, 0.84, 0.84, 0.15)
    else:
        raise ValueError(icon)


def glyph_mask(icon, size):
    surf = cairo.ImageSurface(cairo.FORMAT_ARGB32, int(math.ceil(size * S)), int(math.ceil(size * S)))
    ctx = cairo.Context(surf)
    ctx.scale(S, S)
    ctx.set_source_rgba(1, 1, 1, 1)
    glyph_paths(ctx, icon, 0, 0, size)
    return surf


def draw_mask(ctx, mask, x, y, color):
    ctx.save()
    ctx.translate(x, y)
    ctx.scale(1 / S, 1 / S)
    set_color(ctx, color)
    ctx.mask_surface(mask, 0, 0)
    ctx.restore()


def draw_mask_gradient(ctx, mask, x, y, size, top, bottom):
    ctx.save()
    ctx.translate(x, y)
    pat = cairo.LinearGradient(0, 0, 0, size)
    pat.add_color_stop_rgba(0, *top)
    pat.add_color_stop_rgba(1, *bottom)
    ctx.set_source(pat)
    ctx.scale(1 / S, 1 / S)
    ctx.mask_surface(mask, 0, 0)
    ctx.restore()


def etched_glyph(ctx, icon, cx, cy, size, dark=False, enabled=True):
    mask = glyph_mask(icon, size)
    x = cx - size / 2.0
    y = cy - size / 2.0
    ctx.push_group()
    draw_mask(ctx, mask, x, y - 1.0, rgb(0, 0, 0, 0.85 if dark else 0.5))
    draw_mask(ctx, mask, x, y, rgb(236, 236, 238) if dark else rgb(255, 255, 255))
    ctx.pop_group_to_source()
    ctx.paint_with_alpha(1.0 if enabled else (0.32 if dark else 0.40))


# -------------------------------------------------------------------- bars

def bar(ctx, x, y, w, h, rule_at_top, dark=False):
    if dark:
        vgrad(ctx, x, y, w, h, [(0, rgb(74, 74, 77)), (0.5, rgb(31, 31, 33)),
                                (0.5, rgb(13, 13, 14)), (1, rgb(2, 2, 2))])
    else:
        vgrad(ctx, x, y, w, h, [(0, rgb(185, 199, 217)), (1, rgb(91, 118, 153))])
    rule = rgb(0, 0, 0) if dark else rgb(45, 60, 82)
    sheen = rgb(255, 255, 255, 0.20) if dark else rgb(226, 233, 242, 0.85)
    set_color(ctx, rule)
    ctx.rectangle(x, y if rule_at_top else y + h - 1, w, 1)
    ctx.fill()
    set_color(ctx, sheen)
    ctx.rectangle(x, y + 1 if rule_at_top else y, w, 1)
    ctx.fill()


def gloss_button(ctx, x, y, w, h, r, border, upper, lower, inner_sheen, outer_sheen):
    body_h = h - 1
    if outer_sheen:
        set_color(ctx, outer_sheen)
        rounded(ctx, x, y + 1, w, body_h, r)
        ctx.fill()
    set_color(ctx, border)
    rounded(ctx, x, y, w, body_h, r)
    ctx.fill()
    ix, iy, iw, ih = x + 1, y + 1, w - 2, body_h - 2
    ctx.save()
    rounded(ctx, ix, iy, iw, ih, max(0, r - 1))
    ctx.clip()
    if lower:
        th = math.floor(ih / 2.0)
        vgrad(ctx, ix, iy, iw, th, [(0, upper[0]), (1, upper[1])])
        vgrad(ctx, ix, iy + th, iw, ih - th, [(0, lower[0]), (1, lower[1])])
    else:
        vgrad(ctx, ix, iy, iw, ih, [(0, upper[0]), (1, upper[1])])
    if inner_sheen:
        set_color(ctx, inner_sheen)
        ctx.rectangle(ix, iy, iw, 1)
        ctx.fill()
    ctx.restore()


STYLE = {
    "blue": (rgb(30, 62, 138), [rgb(130, 169, 241), rgb(84, 135, 232)],
             [rgb(58, 113, 225), rgb(43, 102, 220)], rgb(255, 255, 255, .4), rgb(255, 255, 255, .45)),
    "silver": (rgb(128, 134, 145), [rgb(255, 255, 255), rgb(245, 246, 247)],
               [rgb(235, 236, 238), rgb(222, 224, 227)], rgb(255, 255, 255, 1), rgb(255, 255, 255, .55)),
    "black": (rgb(8, 8, 10), [rgb(94, 96, 101), rgb(56, 58, 63)],
              [rgb(42, 44, 49), rgb(23, 25, 29)], rgb(255, 255, 255, .22), rgb(255, 255, 255, .12)),
    "bar": (rgb(46, 62, 88), [rgb(146, 164, 190), rgb(70, 101, 141)], None,
            rgb(255, 255, 255, .28), rgb(255, 255, 255, .28)),
    "done": (rgb(36, 58, 110), [rgb(126, 162, 234), rgb(44, 103, 220)], None,
             rgb(255, 255, 255, .35), rgb(255, 255, 255, .28)),
    "tab": (rgb(50, 70, 100), [rgb(240, 243, 247), rgb(198, 208, 222)], None,
            rgb(255, 255, 255, 1), rgb(255, 255, 255, .30)),
}


def button(ctx, style, x, y, w, h, r, title=None, font=13, dark_text=False):
    gloss_button(ctx, x, y, w, h, r, *STYLE[style])
    if title:
        text(ctx, title, x + w / 2, y + (h - 1) / 2, font, bold=True,
             color=rgb(42, 50, 62) if dark_text else rgb(255, 255, 255),
             shadow=rgb(255, 255, 255, .9) if dark_text else rgb(0, 0, 0, .5),
             shadow_dy=1 if dark_text else -1, center=True)


def text(ctx, s, x, y, size, bold=False, color=rgb(0, 0, 0), shadow=None, shadow_dy=1,
         center=False, maxw=None):
    ctx.select_font_face("Helvetica", cairo.FONT_SLANT_NORMAL,
                         cairo.FONT_WEIGHT_BOLD if bold else cairo.FONT_WEIGHT_NORMAL)
    ctx.set_font_size(size)
    ext = ctx.text_extents(s)
    tx = x - ext.width / 2 - ext.x_bearing if center else x
    ty = y - (ext.height / 2 + ext.y_bearing) if center else y
    if shadow:
        set_color(ctx, shadow)
        ctx.move_to(tx, ty + shadow_dy)
        ctx.show_text(s)
    set_color(ctx, color)
    ctx.move_to(tx, ty)
    ctx.show_text(s)


def fit_text(ctx, s, size, bold, maxw):
    ctx.select_font_face("Helvetica", cairo.FONT_SLANT_NORMAL,
                         cairo.FONT_WEIGHT_BOLD if bold else cairo.FONT_WEIGHT_NORMAL)
    ctx.set_font_size(size)
    if ctx.text_extents(s).x_advance <= maxw:
        return s
    while s and ctx.text_extents(s + "\u2026").x_advance > maxw:
        s = s[:-1]
    return s.rstrip() + "\u2026"


def field(ctx, x, y, w, h, r, fill=rgb(255, 255, 255), progress=0.0, dark=False):
    # sheen below the field
    set_color(ctx, rgb(255, 255, 255, .35))
    rounded(ctx, x, y + 1, w, h, r)
    ctx.fill()
    ctx.save()
    rounded(ctx, x, y, w, h, r)
    ctx.clip()
    set_color(ctx, fill)
    ctx.paint()
    if progress:
        stops = [(0, rgb(62, 100, 162)), (1, rgb(34, 66, 124))] if dark else \
                [(0, rgb(182, 214, 250)), (1, rgb(116, 168, 238))]
        vgrad(ctx, x, y, w * progress, h, stops)
    ctx.restore()
    ctx.save()
    rounded(ctx, x + 1, y + 1, w - 2, h - 2, r - 1)
    ctx.clip()
    vgrad(ctx, x, y + 1, w, 4.5, [(0, rgb(0, 0, 0, .60 if dark else .32)), (1, rgb(0, 0, 0, 0))])
    ctx.restore()
    rounded(ctx, x, y, w, h, r)
    rounded(ctx, x + 1, y + 1, w - 2, h - 2, r - 1)
    ctx.set_fill_rule(cairo.FILL_RULE_EVEN_ODD)
    set_color(ctx, rgb(8, 8, 10) if dark else rgb(93, 115, 142))
    ctx.fill()
    ctx.set_fill_rule(cairo.FILL_RULE_WINDING)


def plain_glyph(ctx, icon, x, y, size, color):
    draw_mask(ctx, glyph_mask(icon, size), x, y, color)


def close_badge(ctx, x, y, side):
    cx, cy = x + side / 2, y + side / 2
    rr = side / 2 - 2
    set_color(ctx, rgb(0, 0, 0, .35))
    ctx.arc(cx, cy, rr + 1.5, 0, 2 * math.pi)
    ctx.fill()
    set_color(ctx, rgb(255, 255, 255))
    ctx.arc(cx, cy, rr, 0, 2 * math.pi)
    ctx.fill()
    ctx.save()
    ctx.arc(cx, cy, rr - 2, 0, 2 * math.pi)
    ctx.clip()
    vgrad(ctx, x, y + 4, side, side - 8, [(0, rgb(238, 88, 88)), (1, rgb(176, 18, 22))])
    vgrad(ctx, x, y + 4, side, (side - 8) * .52, [(0, rgb(255, 255, 255, .45)), (1, rgb(255, 255, 255, .06))])
    ctx.restore()
    arm = side * .15
    set_color(ctx, rgb(255, 255, 255))
    ctx.set_line_width(max(2, side * .09))
    ctx.set_line_cap(cairo.LINE_CAP_ROUND)
    ctx.move_to(cx - arm, cy - arm); ctx.line_to(cx + arm, cy + arm)
    ctx.move_to(cx + arm, cy - arm); ctx.line_to(cx - arm, cy + arm)
    ctx.stroke()


def activity_tile(ctx, icon, x, y, side, lucide_fallback=False):
    radius = round(side * .18)
    ctx.save()
    rounded(ctx, x, y, side, side, radius)
    ctx.clip()
    vgrad(ctx, x, y, side, side, [(0, rgb(238, 238, 240)), (1, rgb(146, 148, 153))])
    rim = max(2, round(side * .045))
    fx, fy, fw, fh = x + rim, y + rim, side - 2 * rim, side - 2 * rim
    rounded(ctx, fx, fy, fw, fh, max(1, radius - rim))
    ctx.clip()
    vgrad(ctx, fx, fy, fw, fh, [(0, rgb(68, 69, 73)), (1, rgb(27, 28, 31))])
    yy = fy + 2
    row = 0
    while yy < fy + fh:
        xx = fx + (4 if row % 2 else 2)
        while xx < fx + fw:
            set_color(ctx, rgb(0, 0, 0, .45))
            ctx.arc(xx, yy, .8, 0, 2 * math.pi); ctx.fill()
            set_color(ctx, rgb(255, 255, 255, .07))
            ctx.arc(xx, yy + .8, .7, 0, 2 * math.pi); ctx.fill()
            xx += 4
        yy += 4
        row += 1
    set_color(ctx, rgb(255, 255, 255, .14))
    ctx.rectangle(fx, fy, fw, 1); ctx.fill()
    ctx.restore()
    g = round(side * .52)
    gx, gy = x + round((side - g) / 2), y + round((side - g) / 2)
    if not lucide_fallback:
        mask = glyph_mask(icon, g)
        draw_mask(ctx, mask, gx, gy + 1, rgb(0, 0, 0, .8))
        draw_mask_gradient(ctx, mask, gx, gy, g, rgb(255, 255, 255), rgb(184, 186, 191))
    else:
        text(ctx, icon, x + side / 2, y + side / 2, g * .7, bold=True, color=rgb(230, 230, 232), center=True)

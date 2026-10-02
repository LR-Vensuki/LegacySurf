#!/usr/bin/env python3
"""Renders the docs/preview-*.png mockups of the Legacy Surf iOS 6 skin.

Prototype only: the shapes, colors and metrics mirror Classes/RBClassicSkin.m
and the classic layouts in the view classes, but this is Cairo, not UIKit.
The system linen, Lucide glyphs and fonts are approximated, so details on a
device differ.

    python3 scripts/design/preview.py          # writes docs/preview-*.png
"""
import math
import os
import random
import sys

import cairo

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from skin import (S, rgb, set_color, vgrad, rounded, glyph_mask, draw_mask, etched_glyph, bar,  # noqa: E402
                  button, text, field, fit_text, plain_glyph, close_badge, activity_tile, gloss_button)

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DOCS = os.path.join(ROOT, "docs")
MARK = os.path.join(ROOT, "Resources", "brand-mark.png")


def surface(w, h):
    surf = cairo.ImageSurface(cairo.FORMAT_ARGB32, int(w * S), int(h * S))
    ctx = cairo.Context(surf)
    ctx.scale(S, S)
    return surf, ctx


def linen(ctx, x, y, w, h, dark=False):
    """Stand-in for UIKit's under-page and dark linen patterns."""
    set_color(ctx, rgb(52, 53, 57) if dark else rgb(178, 181, 186))
    ctx.rectangle(x, y, w, h)
    ctx.fill()
    rnd = random.Random(6)
    yy = y
    while yy < y + h:
        light = rnd.random() < 0.5
        ctx.set_source_rgba(1, 1, 1, rnd.uniform(0.0, 0.05 if dark else 0.10)) if light else \
            ctx.set_source_rgba(0, 0, 0, rnd.uniform(0.0, 0.10 if dark else 0.06))
        ctx.rectangle(x, yy, w, 0.5)
        ctx.fill()
        yy += 0.5
    xx = x
    while xx < x + w:
        ctx.set_source_rgba(0, 0, 0, rnd.uniform(0.0, 0.06 if dark else 0.04))
        ctx.rectangle(xx, y, 0.5, h)
        ctx.fill()
        xx += rnd.choice([0.5, 1.0, 1.5])


def letterpress(ctx, s, x, y, size, dark, bold=True, center=True, color=None):
    text(ctx, s, x, y, size, bold=bold,
         color=color or (rgb(224, 226, 230) if dark else rgb(76, 86, 108)),
         shadow=rgb(0, 0, 0, .8) if dark else rgb(255, 255, 255, .8),
         shadow_dy=-1 if dark else 1, center=center)


def brand_mark(ctx, x, y, side):
    img = cairo.ImageSurface.create_from_png(MARK)
    ctx.save()
    # drop shadow
    ctx.translate(x, y + 2)
    ctx.scale(side / img.get_width(), side / img.get_height())
    ctx.set_source_rgba(0, 0, 0, 0.35)
    ctx.mask_surface(img, 0, 0)
    ctx.restore()
    ctx.save()
    ctx.translate(x, y)
    ctx.scale(side / img.get_width(), side / img.get_height())
    ctx.set_source_surface(img, 0, 0)
    ctx.paint()
    ctx.restore()


def card(ctx, x, y, w, h, r=8, dark=False):
    set_color(ctx, rgb(0, 0, 0, .45 if dark else .16))
    rounded(ctx, x, y + 1, w, h - 1, r)
    ctx.fill()
    set_color(ctx, rgb(0, 0, 0, .85 if dark else .24))
    rounded(ctx, x, y, w, h - 1, r)
    ctx.fill()
    ctx.save()
    rounded(ctx, x + 1, y + 1, w - 2, h - 3, r - 1)
    ctx.clip()
    if dark:
        vgrad(ctx, x, y, w, h, [(0, rgb(72, 72, 76)), (1, rgb(50, 50, 54))])
    else:
        vgrad(ctx, x, y, w, h, [(0, rgb(255, 255, 255)), (1, rgb(239, 240, 242))])
    set_color(ctx, rgb(255, 255, 255, .14 if dark else 1))
    ctx.rectangle(x + 1, y + 1, w - 2, 1)
    ctx.fill()
    ctx.restore()


def icon_tile(ctx, x, y, side, color):
    r, g, b = color
    light = rgb(min(255, r * 1.18 + 15), min(255, g * 1.18 + 15), min(255, b * 1.18 + 15))
    deep = rgb(r * .8, g * .8, b * .8)
    ctx.save()
    rounded(ctx, x, y, side, side, round(side * .22))
    ctx.clip()
    vgrad(ctx, x, y, side, side, [(0, light), (1, deep)])
    ctx.move_to(x, y)
    ctx.line_to(x + side, y)
    ctx.line_to(x + side, y + side * .42)
    ctx.curve_to(x + side * .66, y + side * .54, x + side * .33, y + side * .54, x, y + side * .42)
    ctx.close_path()
    ctx.clip()
    vgrad(ctx, x, y, side, side * .55, [(0, rgb(255, 255, 255, .55)), (1, rgb(255, 255, 255, .10))])
    ctx.restore()


def phone_chrome(ctx, W, H, title, url, placeholder=False, progress=0.0, dark=False, tabs=1, back=True,
                 loading=False):
    bar(ctx, 0, 0, W, 60, rule_at_top=False, dark=dark)
    text(ctx, title, W / 2, 11, 13, bold=True,
         color=rgb(216, 216, 218) if dark else rgb(60, 70, 81),
         shadow=rgb(0, 0, 0, .9) if dark else rgb(255, 255, 255, .55),
         shadow_dy=-1 if dark else 1, center=True)
    field(ctx, 6, 23, W - 12, 31, 6, fill=rgb(44, 44, 47) if dark else rgb(255, 255, 255), progress=progress,
          dark=dark)
    if placeholder:
        text(ctx, "Search or enter address", 16, 43, 14, color=rgb(170, 170, 170))
    else:
        text(ctx, url, 16, 43, 14, color=rgb(240, 240, 240) if dark else rgb(0, 0, 0))
    glyph = "stop" if loading else "reload"
    size = 13 if loading else 16
    plain_glyph(ctx, glyph, W - 6 - 31 + (31 - size) / 2, 23 + (31 - size) / 2, size,
                rgb(184, 184, 184) if dark else rgb(97, 115, 138))
    by = H - 48
    bar(ctx, 0, by, W, 48, rule_at_top=True, dark=dark)
    bw = W / 5.0
    for i, ic in enumerate(["back", "forward", "share", "tabs", "more"]):
        enabled = not ((ic == "back" and not back) or ic == "forward")
        etched_glyph(ctx, ic, bw * i + bw / 2, by + 24, 22, dark=dark, enabled=enabled)
    gx = bw * 3 + bw / 2 - 11
    gy = by + 24 - 11
    text(ctx, str(tabs), gx + 22 * .34 + 22 * .56 / 2, gy + 22 * .34 + 22 * .56 / 2 + .5, 11, bold=True,
         color=rgb(26, 26, 26) if dark else rgb(61, 74, 92), center=True)


FAVORITES = [("Wikipedia", (38, 115, 230)), ("YouTube", (51, 158, 56)), ("GitHub", (84, 107, 140)),
             ("Hacker News", (237, 133, 26)), ("Reddit", (209, 43, 43)), ("Archive", (128, 69, 179))]


def new_tab(ctx, W, H, top_y, dark=False):
    h = H
    x0 = 14
    cw = W - 28
    top, mark = 10, 46
    linen(ctx, 0, top_y, W, h, dark)
    brand_mark(ctx, (W - mark) / 2, top_y + top, mark)
    letterpress(ctx, "Legacy Surf", W / 2, top_y + top + mark + 1 + 16, 28, dark)
    search_top = top + mark + 34
    pill_y = top_y + search_top + 5
    field(ctx, x0, pill_y, cw, 34, 17, fill=rgb(44, 44, 47) if dark else rgb(255, 255, 255), dark=dark)
    hint = rgb(158, 158, 158) if dark else rgb(143, 143, 143)
    plain_glyph(ctx, "search", x0 + 14, pill_y + 9, 16, hint)
    text(ctx, "Search or enter address", x0 + 14 + 16 + 9, pill_y + 22, 15, color=hint)
    fav_top = search_top + 50
    letterpress(ctx, "Favorites", x0 + 2, top_y + fav_top + 15, 15, dark, center=False)
    fy = top_y + fav_top + 24
    cell_w = (cw - 8) / 2
    for i, (name, color) in enumerate(FAVORITES):
        cx = x0 + (i % 2) * (cell_w + 8)
        cy = fy + (i // 2) * (46 + 8)
        card(ctx, cx, cy, cell_w, 46, 8, dark)
        icon_tile(ctx, cx + 8, cy + 7, 30, color)
        text(ctx, name[0], cx + 8 + 15, cy + 7 + 15, 15, bold=True, color=rgb(255, 255, 255),
             shadow=rgb(0, 0, 0, .6), shadow_dy=-1, center=True)
        text(ctx, name, cx + 46, cy + 28, 14, bold=True,
             color=rgb(235, 235, 235) if dark else rgb(41, 48, 61),
             shadow=rgb(0, 0, 0, .6) if dark else rgb(255, 255, 255, .9), shadow_dy=-1 if dark else 1)
    lib_y = top_y + min(fav_top + 24 + 3 * 46 + 2 * 8 + 8, h - 44)
    lx = (W - 176) / 2
    if dark:
        gloss_button(ctx, lx, lib_y, 176, 38, 8, rgb(0, 0, 0), [rgb(112, 112, 116), rgb(88, 88, 92)],
                     [rgb(74, 74, 78), rgb(62, 62, 66)], rgb(255, 255, 255, .22), rgb(255, 255, 255, .12))
        tc, sc, dy = rgb(255, 255, 255), rgb(0, 0, 0, .5), -1
    else:
        button(ctx, "silver", lx, lib_y, 176, 38, 8)
        tc, sc, dy = rgb(42, 50, 62), rgb(255, 255, 255, .9), 1
    mask = glyph_mask("book", 18)
    draw_mask(ctx, mask, lx + 30, lib_y + 9 + dy, sc)
    draw_mask(ctx, mask, lx + 30, lib_y + 9, rgb(255, 255, 255) if dark else rgb(77, 92, 115))
    text(ctx, "Open Library", lx + 30 + 18 + 8, lib_y + 25, 15, bold=True, color=tc, shadow=sc, shadow_dy=dy)


def page_mock(ctx, x, y, w, h, scale=1.0):
    set_color(ctx, rgb(255, 255, 255))
    ctx.rectangle(x, y, w, h)
    ctx.fill()
    ctx.save()
    ctx.rectangle(x, y, w, h)
    ctx.clip()
    s = scale
    set_color(ctx, rgb(246, 246, 246))
    ctx.rectangle(x, y, w, 44 * s)
    ctx.fill()
    set_color(ctx, rgb(200, 200, 200))
    ctx.rectangle(x, y + 44 * s, w, 1)
    ctx.fill()
    text(ctx, "WIKIPEDIA", x + w / 2, y + 22 * s, 15 * s, bold=True, color=rgb(30, 30, 30), center=True)
    yy = y + 60 * s
    text(ctx, "Welcome to Wikipedia,", x + 12 * s, yy + 14 * s, 17 * s, color=rgb(30, 30, 30))
    yy += 34 * s
    rnd = random.Random(3)
    while yy < y + h - 12 * s:
        lw = w - 24 * s - rnd.uniform(0, 70) * s
        set_color(ctx, rgb(205, 207, 211))
        ctx.rectangle(x + 12 * s, yy, lw, 6 * s)
        ctx.fill()
        yy += 13 * s
        if rnd.random() < 0.18:
            set_color(ctx, rgb(214, 228, 245))
            ctx.rectangle(x + 12 * s, yy + 2 * s, w - 24 * s, 46 * s)
            ctx.fill()
            yy += 56 * s
    ctx.restore()


def pages(ctx, W, H):
    vgrad(ctx, 0, 0, W, H, [(0, rgb(124, 132, 144)), (.5, rgb(86, 93, 103)), (1, rgb(52, 57, 64))])
    text(ctx, "Wikipedia, the free encyclopedia", W / 2, 17, 17, bold=True, color=rgb(255, 255, 255),
         shadow=rgb(0, 0, 0, .6), shadow_dy=-1, center=True)
    text(ctx, "https://en.wikipedia.org/wiki/Main_Page", W / 2, 35, 13, color=rgb(214, 214, 214),
         shadow=rgb(0, 0, 0, .6), shadow_dy=-1, center=True)
    bottom_h, dots_h, cap = 44, 25, 46
    scroll_h = H - cap - bottom_h - dots_h
    cw = min(320, max(220, W - 42))
    ch = max(160, scroll_h - 32)
    cx = (W - cw) / 2
    cy = cap + 18
    # card shadow
    for i in range(7, 0, -1):
        ctx.set_source_rgba(0, 0, 0, 0.06)
        ctx.rectangle(cx - i + 1, cy - i + 4, cw + 2 * i - 2, ch + 2 * i - 2)
        ctx.fill()
    page_mock(ctx, cx, cy, cw, ch, scale=cw / 320.0)
    close_badge(ctx, cx - 15 + 3, cy - 15 + 3, 30)
    dy = H - bottom_h - dots_h / 2
    for i in range(3):
        set_color(ctx, rgb(255, 255, 255, 1 if i == 0 else .3))
        ctx.arc(W / 2 - 16 + i * 16, dy, 3, 0, 2 * math.pi)
        ctx.fill()
    by = H - bottom_h
    bar(ctx, 0, by, W, bottom_h, rule_at_top=True)
    button(ctx, "bar", 6, by + 7, 78, 30, 5, "New Tab", 12)
    button(ctx, "done", W - 64, by + 7, 58, 30, 5, "Done", 12)


def stand_in_glyph(kind):
    def draw(ctx, x, y, s, color):
        set_color(ctx, color)
        ctx.set_line_width(s * .1)
        ctx.set_line_cap(cairo.LINE_CAP_ROUND)
        if kind == "reader":
            for i, lw in enumerate([.8, .8, .6, .8, .5]):
                ctx.move_to(x + s * .12, y + s * (.2 + i * .15))
                ctx.line_to(x + s * (.12 + lw * .76), y + s * (.2 + i * .15))
            ctx.stroke()
        elif kind == "media":
            ctx.arc(x + s / 2, y + s / 2, s * .4, 0, 2 * math.pi)
            ctx.stroke()
            ctx.move_to(x + s * .42, y + s * .32)
            ctx.line_to(x + s * .70, y + s * .5)
            ctx.line_to(x + s * .42, y + s * .68)
            ctx.close_path()
            ctx.fill()
        elif kind == "expand":
            for (ax, ay, dx, dy) in [(.15, .15, 1, 1), (.85, .15, -1, 1), (.15, .85, 1, -1), (.85, .85, -1, -1)]:
                ctx.move_to(x + s * ax, y + s * (ay + dy * .25))
                ctx.line_to(x + s * ax, y + s * ay)
                ctx.line_to(x + s * (ax + dx * .25), y + s * ay)
            ctx.stroke()
        elif kind == "sliders":
            for i, k in enumerate([.3, .65, .45]):
                yy = y + s * (.25 + i * .25)
                ctx.move_to(x + s * .1, yy)
                ctx.line_to(x + s * .9, yy)
                ctx.stroke()
                ctx.arc(x + s * k, yy, s * .09, 0, 2 * math.pi)
                ctx.fill()
    return draw


def tools_sheet(ctx, W, H):
    page_mock(ctx, 0, 60, W, H - 108)
    phone_chrome(ctx, W, H, "Wikipedia, the free encyclopedia", "https://en.wikipedia.org/wiki/Main_Page",
                 tabs=3)
    ctx.set_source_rgba(0.02, 0.02, 0.02, 0.34)
    ctx.paint()
    sh = 292
    sy = H - sh
    vgrad(ctx, 0, sy + 2, W, sh - 2, [(0, rgb(104, 106, 111, .97)), (.2, rgb(46, 47, 51, .97)),
                                      (1, rgb(38, 39, 43, .97))])
    set_color(ctx, rgb(0, 0, 0, .7))
    ctx.rectangle(0, sy, W, 1)
    ctx.fill()
    set_color(ctx, rgb(255, 255, 255, .32))
    ctx.rectangle(0, sy + 1, W, 1)
    ctx.fill()
    text(ctx, "Browser tools", W / 2, sy + 20, 13, bold=True, color=rgb(219, 219, 219),
         shadow=rgb(0, 0, 0, .6), shadow_dy=-1, center=True)
    items = [("Library", "book"), ("Reader", "reader"), ("Find on Page", "search"),
             ("Media Controls", "media"), ("Fullscreen", "expand"), ("Settings", "sliders")]
    inset, gap = 12, 4
    tw = (W - inset * 2 - gap * 2) // 3
    for i, (name, ic) in enumerate(items):
        tx = inset + (i % 3) * (tw + gap)
        ty = sy + 36 + (i // 3) * (92 + gap)
        ix = tx + (tw - 57) / 2
        if ic in ("book", "search"):
            activity_tile(ctx, ic, ix, ty + 2, 57)
        else:
            activity_tile(ctx, "more", ix, ty + 2, 57)
            # repaint the face center with the stand-in glyph
            ctx.save()
            rounded(ctx, ix + 3, ty + 5, 51, 51, 7)
            ctx.clip()
            vgrad(ctx, ix + 3, ty + 5, 51, 51, [(0, rgb(68, 69, 73)), (1, rgb(27, 28, 31))])
            ctx.restore()
            stand_in_glyph(ic)(ctx, ix + 14, ty + 15, 30, rgb(232, 232, 234))
        text(ctx, name, tx + tw / 2, ty + 2 + 57 + 14, 12, bold=True, color=rgb(255, 255, 255),
             shadow=rgb(0, 0, 0, .6), shadow_dy=-1, center=True)
    button(ctx, "black", 20, H - 58, W - 40, 45, 9, "Cancel", 19)


def ipad_rail(ctx, W, H):
    page_mock(ctx, 0, 0, W, H - 50, scale=1.2)
    by = H - 50
    bar(ctx, 0, by, W, 50, rule_at_top=True)
    etched_glyph(ctx, "back", 22, by + 25, 22)
    etched_glyph(ctx, "forward", 66, by + 25, 22, enabled=False)
    fx, fw = 94, 225
    fy = by + (50 - 31) / 2
    field(ctx, fx, fy, fw, 31, 6, progress=0.0)
    plain_glyph(ctx, "reload", fx + fw - 31 + 7.5, fy + 7.5, 16, rgb(97, 115, 138))
    text(ctx, "en.wikipedia.org", fx + 10, fy + 20.5, 14, bold=True)
    tabs_x = fx + fw + 9
    tabs_r = W - 132 - 5
    plus_w = 36
    avail = tabs_r - tabs_x - plus_w - 5
    names = ["Wikipedia, the free…", "YouTube", "Hacker News", "GitHub"]
    tw = min(190, avail / len(names))
    for i, name in enumerate(names):
        x = tabs_x + i * tw + 1
        y = fy + 2
        label = fit_text(ctx, name, 12, True, tw - 2 - 27 - 9 - 4)
        if i == 0:
            button(ctx, "tab", x, y, tw - 2, 27, 5)
            text(ctx, label, x + 9, y + 17.5, 12, bold=True, color=rgb(36, 44, 56),
                 shadow=rgb(255, 255, 255, .85), shadow_dy=1)
            plain_glyph(ctx, "close", x + tw - 2 - 19, y + 8, 11, rgb(84, 97, 117))
        else:
            button(ctx, "bar", x, y, tw - 2, 27, 5)
            text(ctx, label, x + 9, y + 17.5, 12, bold=True, color=rgb(255, 255, 255, .9),
                 shadow=rgb(0, 0, 0, .6), shadow_dy=-1)
            plain_glyph(ctx, "close", x + tw - 2 - 19, y + 8, 11, rgb(255, 255, 255, .7))
    etched_glyph(ctx, "plus", tabs_r - plus_w / 2, by + 25, 22)
    for i, ic in enumerate(["share", "book", "more"]):
        etched_glyph(ctx, ic, W - 132 + 22 + i * 44, by + 25, 22)


def save(surf, name):
    path = os.path.join(DOCS, name)
    surf.write_to_png(path)
    print(path)


def main():
    os.makedirs(DOCS, exist_ok=True)
    W, H = 320, 480
    surf, ctx = surface(W, H)
    new_tab(ctx, W, H - 108, 60)
    phone_chrome(ctx, W, H, "New Tab", "", placeholder=True, back=False)
    save(surf, "preview-iphone-newtab.png")

    surf, ctx = surface(W, H)
    new_tab(ctx, W, H - 108, 60, dark=True)
    phone_chrome(ctx, W, H, "New Tab", "", placeholder=True, dark=True, back=False)
    save(surf, "preview-iphone-dark.png")

    surf, ctx = surface(W, H)
    page_mock(ctx, 0, 60, W, H - 108)
    phone_chrome(ctx, W, H, "Wikipedia, the free encyclopedia", "https://en.wikipedia.org/wiki/Main_Page",
                 progress=0.62, tabs=3, loading=True)
    save(surf, "preview-iphone-loading.png")

    surf, ctx = surface(W, H)
    pages(ctx, W, H)
    save(surf, "preview-iphone-pages.png")

    surf, ctx = surface(W, H)
    tools_sheet(ctx, W, H)
    save(surf, "preview-iphone-tools.png")

    surf, ctx = surface(1024, 140)
    ipad_rail(ctx, 1024, 140)
    save(surf, "preview-ipad-rail.png")


if __name__ == "__main__":
    main()

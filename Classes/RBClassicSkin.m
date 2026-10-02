#import "RBClassicSkin.h"

#import <QuartzCore/QuartzCore.h>

#include <math.h>

static UIColor *RBRGBA(CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    return [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:a];
}

static UIColor *RBRGB(CGFloat r, CGFloat g, CGFloat b) {
    return RBRGBA(r, g, b, 1.0);
}

static NSCache *RBSkinCache(void) {
    static NSCache *cache;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cache = [[NSCache alloc] init];
        cache.countLimit = 192;
    });
    return cache;
}

static NSString *RBColorKey(UIColor *color) {
    if (!color) return @"-";
    CGFloat r = 0.0, g = 0.0, b = 0.0, a = 0.0;
    if (![color getRed:&r green:&g blue:&b alpha:&a]) {
        CGFloat white = 0.0;
        if ([color getWhite:&white alpha:&a]) r = g = b = white;
    }
    return [NSString stringWithFormat:@"%.3f,%.3f,%.3f,%.3f", r, g, b, a];
}

typedef void (^RBSkinDrawing)(CGContextRef context, CGSize size);

// Renders once per key at the screen scale; a nil key skips the cache.
static UIImage *RBSkinRender(NSString *key, CGSize size, RBSkinDrawing drawing) {
    UIImage *image = key ? [RBSkinCache() objectForKey:key] : nil;
    if (image) return image;
    if (size.width <= 0.0 || size.height <= 0.0) return nil;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    drawing(UIGraphicsGetCurrentContext(), size);
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (image && key) [RBSkinCache() setObject:image forKey:key];
    return image;
}

// Vertical gradient over rect. Colors must be RGB UIColors.
static void RBFillGradient(CGContextRef context, CGRect rect, NSArray *colors, const CGFloat *locations) {
    if (CGRectIsEmpty(rect) || [colors count] < 2) return;
    NSMutableArray *cgColors = [NSMutableArray arrayWithCapacity:[colors count]];
    for (UIColor *color in colors) [cgColors addObject:(__bridge id)[color CGColor]];
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(space, (__bridge CFArrayRef)cgColors, locations);
    CGContextSaveGState(context);
    CGContextClipToRect(context, rect);
    CGContextDrawLinearGradient(context, gradient,
                                CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect)),
                                CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect)), 0);
    CGContextRestoreGState(context);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(space);
}

static UIImage *RBTinted(UIImage *mask, UIColor *color) {
    if (!mask) return nil;
    UIGraphicsBeginImageContextWithOptions(mask.size, NO, mask.scale);
    CGRect rect = (CGRect){CGPointZero, mask.size};
    [mask drawInRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    [color setFill];
    CGContextFillRect(context, rect);
    UIImage *tinted = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return tinted;
}

static UIImage *RBGradientTinted(UIImage *mask, UIColor *top, UIColor *bottom) {
    if (!mask) return nil;
    UIGraphicsBeginImageContextWithOptions(mask.size, NO, mask.scale);
    CGRect rect = (CGRect){CGPointZero, mask.size};
    [mask drawInRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    RBFillGradient(context, rect, @[top, bottom], NULL);
    UIImage *tinted = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return tinted;
}

static UIImage *RBFaded(NSString *key, UIImage *image, CGFloat alpha) {
    if (!image) return nil;
    return RBSkinRender(key, image.size, ^(CGContextRef context, CGSize size) {
        [image drawAtPoint:CGPointZero blendMode:kCGBlendModeNormal alpha:alpha];
    });
}

// ------------------------------------------------------------------ glyphs

static CGPoint RBP(CGRect r, CGFloat x, CGFloat y) {
    return CGPointMake(r.origin.x + x * r.size.width, r.origin.y + y * r.size.height);
}

static CGRect RBR(CGRect r, CGFloat x, CGFloat y, CGFloat w, CGFloat h) {
    return CGRectMake(r.origin.x + x * r.size.width, r.origin.y + y * r.size.height,
                      w * r.size.width, h * r.size.height);
}

static void RBClear(CGContextRef context, UIBezierPath *path) {
    CGContextSaveGState(context);
    CGContextSetBlendMode(context, kCGBlendModeClear);
    [path fill];
    CGContextRestoreGState(context);
}

static UIBezierPath *RBLine(CGRect r, CGFloat x0, CGFloat y0, CGFloat x1, CGFloat y1, CGFloat width) {
    UIBezierPath *line = [UIBezierPath bezierPath];
    [line moveToPoint:RBP(r, x0, y0)];
    [line addLineToPoint:RBP(r, x1, y1)];
    line.lineWidth = width * r.size.width;
    line.lineCapStyle = kCGLineCapRound;
    return line;
}

// Solid iOS 6 shapes for the browser controls, drawn in the current color.
// Returns NO for icons that keep their Lucide glyph.
static BOOL RBDrawClassicGlyph(CGContextRef context, RBIcon icon, CGRect r) {
    CGFloat s = r.size.width;
    switch (icon) {
        case RBIconBack:
        case RBIconForward: {
            BOOL back = icon == RBIconBack;
            CGFloat tip = back ? 0.17 : 0.83;
            CGFloat base = back ? 0.78 : 0.22;
            UIBezierPath *triangle = [UIBezierPath bezierPath];
            [triangle moveToPoint:RBP(r, tip, 0.50)];
            [triangle addLineToPoint:RBP(r, base, 0.16)];
            [triangle addLineToPoint:RBP(r, base, 0.84)];
            [triangle closePath];
            triangle.lineJoinStyle = kCGLineJoinRound;
            triangle.lineWidth = s * 0.07;
            [triangle fill];
            [triangle stroke];
            return YES;
        }
        case RBIconChevronUp:
        case RBIconChevronDown: {
            BOOL up = icon == RBIconChevronUp;
            UIBezierPath *triangle = [UIBezierPath bezierPath];
            [triangle moveToPoint:RBP(r, 0.50, up ? 0.24 : 0.76)];
            [triangle addLineToPoint:RBP(r, 0.86, up ? 0.74 : 0.26)];
            [triangle addLineToPoint:RBP(r, 0.14, up ? 0.74 : 0.26)];
            [triangle closePath];
            triangle.lineJoinStyle = kCGLineJoinRound;
            triangle.lineWidth = s * 0.06;
            [triangle fill];
            [triangle stroke];
            return YES;
        }
        case RBIconShare: {
            // The iOS 6 action glyph: an open tray with an arrow leaving it.
            UIBezierPath *tray = [UIBezierPath bezierPathWithRoundedRect:RBR(r, 0.10, 0.36, 0.64, 0.52)
                                                            cornerRadius:s * 0.07];
            tray.lineWidth = s * 0.085;
            [tray stroke];
            RBClear(context, [UIBezierPath bezierPathWithRect:RBR(r, 0.42, 0.24, 0.50, 0.34)]);
            UIBezierPath *shaft = [UIBezierPath bezierPath];
            [shaft moveToPoint:RBP(r, 0.30, 0.74)];
            [shaft addQuadCurveToPoint:RBP(r, 0.66, 0.36) controlPoint:RBP(r, 0.30, 0.38)];
            shaft.lineWidth = s * 0.12;
            shaft.lineCapStyle = kCGLineCapRound;
            [shaft stroke];
            UIBezierPath *head = [UIBezierPath bezierPath];
            [head moveToPoint:RBP(r, 0.95, 0.36)];
            [head addLineToPoint:RBP(r, 0.62, 0.12)];
            [head addLineToPoint:RBP(r, 0.62, 0.60)];
            [head closePath];
            head.lineJoinStyle = kCGLineJoinRound;
            head.lineWidth = s * 0.04;
            [head fill];
            [head stroke];
            return YES;
        }
        case RBIconBook: {
            // Open book seen from above, as on the iOS 6 Bookmarks button.
            UIBezierPath *book = [UIBezierPath bezierPath];
            [book moveToPoint:RBP(r, 0.50, 0.30)];
            [book addQuadCurveToPoint:RBP(r, 0.07, 0.25) controlPoint:RBP(r, 0.28, 0.14)];
            [book addLineToPoint:RBP(r, 0.07, 0.80)];
            [book addQuadCurveToPoint:RBP(r, 0.50, 0.84) controlPoint:RBP(r, 0.28, 0.69)];
            [book addQuadCurveToPoint:RBP(r, 0.93, 0.80) controlPoint:RBP(r, 0.72, 0.69)];
            [book addLineToPoint:RBP(r, 0.93, 0.25)];
            [book addQuadCurveToPoint:RBP(r, 0.50, 0.30) controlPoint:RBP(r, 0.72, 0.14)];
            [book closePath];
            [book moveToPoint:RBP(r, 0.50, 0.30)];
            [book addLineToPoint:RBP(r, 0.50, 0.84)];
            book.lineWidth = s * 0.075;
            book.lineJoinStyle = kCGLineJoinRound;
            [book stroke];
            return YES;
        }
        case RBIconTabs: {
            // Safari's Pages glyph: a page outline behind a solid front page.
            // RBPhoneToolbar writes the page count onto the front page.
            UIBezierPath *backPage = [UIBezierPath bezierPathWithRoundedRect:RBR(r, 0.10, 0.10, 0.56, 0.56)
                                                                cornerRadius:s * 0.07];
            backPage.lineWidth = s * 0.08;
            [backPage stroke];
            RBClear(context, [UIBezierPath bezierPathWithRoundedRect:RBR(r, 0.27, 0.27, 0.71, 0.71)
                                                        cornerRadius:s * 0.12]);
            [[UIBezierPath bezierPathWithRoundedRect:RBR(r, 0.34, 0.34, 0.56, 0.56)
                                        cornerRadius:s * 0.07] fill];
            return YES;
        }
        case RBIconMore: {
            for (int i = 0; i < 3; i++) {
                CGFloat x = 0.20 + 0.30 * i;
                [[UIBezierPath bezierPathWithOvalInRect:RBR(r, x - 0.095, 0.405, 0.19, 0.19)] fill];
            }
            return YES;
        }
        case RBIconReload: {
            CGPoint center = RBP(r, 0.48, 0.54);
            CGFloat radius = s * 0.29;
            CGFloat start = -40.0 * M_PI / 180.0;
            CGFloat end = 245.0 * M_PI / 180.0;
            UIBezierPath *arc = [UIBezierPath bezierPathWithArcCenter:center radius:radius
                                                           startAngle:start endAngle:end clockwise:YES];
            arc.lineWidth = s * 0.115;
            [arc stroke];
            CGPoint e = CGPointMake(center.x + radius * cos(end), center.y + radius * sin(end));
            CGPoint t = CGPointMake(-sin(end), cos(end));
            CGPoint n = CGPointMake(cos(end), sin(end));
            CGFloat length = s * 0.24, half = s * 0.17;
            UIBezierPath *head = [UIBezierPath bezierPath];
            [head moveToPoint:CGPointMake(e.x + t.x * length, e.y + t.y * length)];
            [head addLineToPoint:CGPointMake(e.x + n.x * half, e.y + n.y * half)];
            [head addLineToPoint:CGPointMake(e.x - n.x * half, e.y - n.y * half)];
            [head closePath];
            [head fill];
            return YES;
        }
        case RBIconStop:
        case RBIconClose: {
            CGFloat width = icon == RBIconStop ? 0.13 : 0.14;
            [RBLine(r, 0.25, 0.25, 0.75, 0.75, width) stroke];
            [RBLine(r, 0.75, 0.25, 0.25, 0.75, width) stroke];
            return YES;
        }
        case RBIconPlus: {
            UIBezierPath *vertical = RBLine(r, 0.50, 0.18, 0.50, 0.82, 0.15);
            UIBezierPath *horizontal = RBLine(r, 0.18, 0.50, 0.82, 0.50, 0.15);
            vertical.lineCapStyle = kCGLineCapSquare;
            horizontal.lineCapStyle = kCGLineCapSquare;
            [vertical stroke];
            [horizontal stroke];
            return YES;
        }
        case RBIconSearch: {
            UIBezierPath *lens = [UIBezierPath bezierPathWithOvalInRect:RBR(r, 0.14, 0.14, 0.52, 0.52)];
            lens.lineWidth = s * 0.10;
            [lens stroke];
            [RBLine(r, 0.62, 0.62, 0.84, 0.84, 0.15) stroke];
            return YES;
        }
        default:
            return NO;
    }
}

@implementation RBClassicSkin

// -------------------------------------------------------------------- bars

+ (NSArray *)barColorsDark:(BOOL)dark {
    if (dark) {
        return @[(id)[RBRGB(74, 74, 77) CGColor], (id)[RBRGB(31, 31, 33) CGColor],
                 (id)[RBRGB(13, 13, 14) CGColor], (id)[RBRGB(2, 2, 2) CGColor]];
    }
    return @[(id)[RBRGB(185, 199, 217) CGColor], (id)[RBRGB(91, 118, 153) CGColor]];
}

+ (NSArray *)barLocationsDark:(BOOL)dark {
    return dark ? @[@0.0, @0.5, @0.5, @1.0] : @[@0.0, @1.0];
}

+ (UIColor *)barRuleColorDark:(BOOL)dark {
    return dark ? RBRGB(0, 0, 0) : RBRGB(45, 60, 82);
}

+ (UIColor *)barSheenColorDark:(BOOL)dark {
    return dark ? RBRGBA(255, 255, 255, 0.20) : RBRGBA(226, 233, 242, 0.85);
}

+ (NSArray *)pagesBackgroundColors {
    return @[(id)[RBRGB(124, 132, 144) CGColor], (id)[RBRGB(86, 93, 103) CGColor],
             (id)[RBRGB(52, 57, 64) CGColor]];
}

// ------------------------------------------------------------------ glyphs

+ (UIImage *)maskForIcon:(RBIcon)icon size:(CGFloat)size {
    NSString *key = [NSString stringWithFormat:@"mask.%d.%.2f", (int)icon, size];
    UIImage *cached = [RBSkinCache() objectForKey:key];
    if (cached) return cached;
    __block BOOL drawn = NO;
    UIImage *image = RBSkinRender(nil, CGSizeMake(size, size), ^(CGContextRef context, CGSize canvas) {
        [[UIColor whiteColor] set];
        drawn = RBDrawClassicGlyph(context, icon, CGRectMake(0.0, 0.0, canvas.width, canvas.height));
    });
    if (!drawn) image = [RBTheme icon:icon size:size color:[UIColor whiteColor]];
    if (image) [RBSkinCache() setObject:image forKey:key];
    return image;
}

+ (UIImage *)glyph:(RBIcon)icon size:(CGFloat)size color:(UIColor *)color
       shadowColor:(UIColor *)shadowColor shadowOffset:(CGFloat)offsetY {
    NSString *key = [NSString stringWithFormat:@"glyph.%d.%.2f.%@.%@.%.1f", (int)icon, size,
                     RBColorKey(color), RBColorKey(shadowColor), offsetY];
    CGFloat pad = shadowColor ? ceil(fabs(offsetY)) : 0.0;
    return RBSkinRender(key, CGSizeMake(size, size + pad * 2.0), ^(CGContextRef context, CGSize canvas) {
        UIImage *mask = [RBClassicSkin maskForIcon:icon size:size];
        if (shadowColor) [RBTinted(mask, shadowColor) drawAtPoint:CGPointMake(0.0, pad + offsetY)];
        [RBTinted(mask, color) drawAtPoint:CGPointMake(0.0, pad)];
    });
}

+ (UIImage *)barGlyph:(RBIcon)icon size:(CGFloat)size dark:(BOOL)dark enabled:(BOOL)enabled {
    UIImage *glyph = [self glyph:icon size:size
                           color:dark ? RBRGB(236, 236, 238) : [UIColor whiteColor]
                     shadowColor:RBRGBA(0, 0, 0, dark ? 0.85 : 0.50)
                    shadowOffset:-1.0];
    if (enabled) return glyph;
    // UIKit fades the whole etched item, shadow included.
    NSString *key = [NSString stringWithFormat:@"bar-off.%d.%.2f.%d", (int)icon, size, dark];
    return RBFaded(key, glyph, dark ? 0.32 : 0.40);
}

// ----------------------------------------------------------------- buttons

static UIImage *RBGlossImage(NSString *key, CGFloat height, CGFloat radius, UIColor *border,
                             NSArray *upper, NSArray *lower, UIColor *innerSheen, UIColor *outerSheen) {
    height = MAX(radius * 2.0 + 4.0, roundf(height));
    CGFloat width = radius * 2.0 + 6.0;
    UIImage *image = RBSkinRender(key, CGSizeMake(width, height), ^(CGContextRef context, CGSize size) {
        CGRect body = CGRectMake(0.0, 0.0, size.width, size.height - 1.0);
        if (outerSheen) {
            [outerSheen setFill];
            [[UIBezierPath bezierPathWithRoundedRect:CGRectOffset(body, 0.0, 1.0) cornerRadius:radius] fill];
            RBClear(context, [UIBezierPath bezierPathWithRoundedRect:body cornerRadius:radius]);
        }
        [border setFill];
        [[UIBezierPath bezierPathWithRoundedRect:body cornerRadius:radius] fill];
        CGRect inner = CGRectInset(body, 1.0, 1.0);
        CGContextSaveGState(context);
        [[UIBezierPath bezierPathWithRoundedRect:inner cornerRadius:MAX(0.0, radius - 1.0)] addClip];
        if (lower) {
            CGRect top = inner;
            top.size.height = floorf(inner.size.height / 2.0);
            CGRect bottom = inner;
            bottom.origin.y = CGRectGetMaxY(top);
            bottom.size.height = CGRectGetMaxY(inner) - bottom.origin.y;
            RBFillGradient(context, top, upper, NULL);
            RBFillGradient(context, bottom, lower, NULL);
        } else {
            RBFillGradient(context, inner, upper, NULL);
        }
        if (innerSheen) {
            [innerSheen setFill];
            CGContextFillRect(context, CGRectMake(inner.origin.x, inner.origin.y, inner.size.width, 1.0));
        }
        CGContextRestoreGState(context);
    });
    // Stretch only the row just below the gloss split, so small height
    // differences never smear the highlight.
    CGFloat top = floorf((image.size.height - 1.0) / 2.0) + 1.0;
    CGFloat bottom = MAX(0.0, image.size.height - top - 1.0);
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(top, radius + 2.0, bottom, radius + 2.0)
                                 resizingMode:UIImageResizingModeStretch];
}

+ (UIImage *)buttonImage:(RBClassicButtonStyle)style height:(CGFloat)height
                  radius:(CGFloat)radius pressed:(BOOL)pressed dark:(BOOL)dark {
    NSString *key = [NSString stringWithFormat:@"button.%d.%.1f.%.1f.%d.%d", (int)style, height, radius,
                     pressed, dark];
    UIColor *border = nil, *innerSheen = nil, *outerSheen = nil;
    NSArray *upper = nil, *lower = nil;
    switch (style) {
        case RBClassicButtonBlue:
            border = RBRGB(30, 62, 138);
            upper = pressed ? @[RBRGB(84, 122, 202), RBRGB(54, 94, 186)]
                            : @[RBRGB(130, 169, 241), RBRGB(84, 135, 232)];
            lower = pressed ? @[RBRGB(36, 78, 178), RBRGB(30, 71, 170)]
                            : @[RBRGB(58, 113, 225), RBRGB(43, 102, 220)];
            innerSheen = RBRGBA(255, 255, 255, pressed ? 0.15 : 0.40);
            outerSheen = RBRGBA(255, 255, 255, dark ? 0.12 : 0.45);
            break;
        case RBClassicButtonSilver:
            if (pressed) {
                border = RBRGB(30, 62, 138);
                upper = @[RBRGB(92, 152, 246), RBRGB(54, 122, 237)];
                lower = @[RBRGB(26, 99, 231), RBRGB(21, 92, 223)];
                innerSheen = RBRGBA(255, 255, 255, 0.30);
            } else if (dark) {
                border = RBRGB(0, 0, 0);
                upper = @[RBRGB(112, 112, 116), RBRGB(88, 88, 92)];
                lower = @[RBRGB(74, 74, 78), RBRGB(62, 62, 66)];
                innerSheen = RBRGBA(255, 255, 255, 0.22);
            } else {
                border = RBRGB(128, 134, 145);
                upper = @[RBRGB(255, 255, 255), RBRGB(245, 246, 247)];
                lower = @[RBRGB(235, 236, 238), RBRGB(222, 224, 227)];
                innerSheen = RBRGBA(255, 255, 255, 1.0);
            }
            outerSheen = RBRGBA(255, 255, 255, dark ? 0.12 : 0.55);
            break;
        case RBClassicButtonBlack:
            border = RBRGB(8, 8, 10);
            upper = pressed ? @[RBRGB(62, 64, 69), RBRGB(38, 40, 44)]
                            : @[RBRGB(94, 96, 101), RBRGB(56, 58, 63)];
            lower = pressed ? @[RBRGB(28, 30, 34), RBRGB(14, 15, 18)]
                            : @[RBRGB(42, 44, 49), RBRGB(23, 25, 29)];
            innerSheen = RBRGBA(255, 255, 255, 0.22);
            outerSheen = RBRGBA(255, 255, 255, 0.12);
            break;
        case RBClassicButtonBar:
            if (dark) {
                border = RBRGB(0, 0, 0);
                upper = pressed ? @[RBRGB(52, 52, 54), RBRGB(14, 14, 15)]
                                : @[RBRGB(84, 84, 87), RBRGB(30, 30, 32)];
                innerSheen = RBRGBA(255, 255, 255, 0.18);
                outerSheen = RBRGBA(255, 255, 255, 0.12);
            } else {
                border = RBRGB(46, 62, 88);
                upper = pressed ? @[RBRGB(100, 122, 156), RBRGB(44, 72, 113)]
                                : @[RBRGB(146, 164, 190), RBRGB(70, 101, 141)];
                innerSheen = RBRGBA(255, 255, 255, pressed ? 0.12 : 0.28);
                outerSheen = RBRGBA(255, 255, 255, 0.28);
            }
            break;
        case RBClassicButtonBarDone:
            border = dark ? RBRGB(0, 0, 0) : RBRGB(36, 58, 110);
            upper = pressed ? @[RBRGB(80, 115, 192), RBRGB(25, 72, 175)]
                            : @[RBRGB(126, 162, 234), RBRGB(44, 103, 220)];
            innerSheen = RBRGBA(255, 255, 255, pressed ? 0.15 : 0.35);
            outerSheen = RBRGBA(255, 255, 255, dark ? 0.12 : 0.28);
            break;
        case RBClassicButtonRed:
            border = RBRGB(102, 12, 16);
            upper = pressed ? @[RBRGB(202, 102, 107), RBRGB(178, 52, 58)]
                            : @[RBRGB(242, 141, 146), RBRGB(214, 76, 82)];
            lower = pressed ? @[RBRGB(170, 26, 30), RBRGB(158, 20, 24)]
                            : @[RBRGB(206, 43, 46), RBRGB(195, 33, 37)];
            innerSheen = RBRGBA(255, 255, 255, 0.30);
            outerSheen = RBRGBA(255, 255, 255, dark ? 0.12 : 0.40);
            break;
    }
    return RBGlossImage(key, height, radius, border, upper, lower, innerSheen, outerSheen);
}

+ (void)styleButton:(UIButton *)button style:(RBClassicButtonStyle)style
             height:(CGFloat)height radius:(CGFloat)radius dark:(BOOL)dark {
    if (!button) return;
    button.backgroundColor = [UIColor clearColor];
    button.layer.cornerRadius = 0.0;
    button.layer.borderWidth = 0.0;
    button.showsTouchWhenHighlighted = NO;
    button.adjustsImageWhenHighlighted = NO;
    [button setBackgroundImage:[self buttonImage:style height:height radius:radius pressed:NO dark:dark]
                      forState:UIControlStateNormal];
    [button setBackgroundImage:[self buttonImage:style height:height radius:radius pressed:YES dark:dark]
                      forState:UIControlStateHighlighted];
    BOOL darkText = style == RBClassicButtonSilver && !dark;
    UIColor *title = darkText ? RBRGB(42, 50, 62) : [UIColor whiteColor];
    [button setTitleColor:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [button setTitleColor:[title colorWithAlphaComponent:0.45] forState:UIControlStateDisabled];
    [button setTitleShadowColor:darkText ? RBRGBA(255, 255, 255, 0.90) : RBRGBA(0, 0, 0, 0.50)
                       forState:UIControlStateNormal];
    [button setTitleShadowColor:RBRGBA(0, 0, 0, 0.45) forState:UIControlStateHighlighted];
    button.titleLabel.shadowOffset = darkText ? CGSizeMake(0.0, 1.0) : CGSizeMake(0.0, -1.0);
    // A silver button turns blue when pressed; its engraved title flips to
    // the embossed shadow of white text, as UIButtonTypeRoundedRect did.
    button.reversesTitleShadowWhenHighlighted = darkText;
}

+ (UIImage *)activeTabImageWithHeight:(CGFloat)height dark:(BOOL)dark {
    NSString *key = [NSString stringWithFormat:@"tab.%.1f.%d", height, dark];
    if (dark) {
        return RBGlossImage(key, height, 5.0, RBRGB(0, 0, 0),
                            @[RBRGB(128, 128, 132), RBRGB(80, 80, 84)], nil,
                            RBRGBA(255, 255, 255, 0.30), RBRGBA(255, 255, 255, 0.12));
    }
    return RBGlossImage(key, height, 5.0, RBRGB(50, 70, 100),
                        @[RBRGB(240, 243, 247), RBRGB(198, 208, 222)], nil,
                        RBRGBA(255, 255, 255, 1.0), RBRGBA(255, 255, 255, 0.30));
}

// ------------------------------------------------------------------ fields

+ (UIColor *)fieldFillColorDark:(BOOL)dark {
    return dark ? RBRGB(44, 44, 47) : [UIColor whiteColor];
}

static UIImage *RBFieldImage(NSString *key, CGFloat radius, CGFloat height, BOOL dark, UIColor *fill) {
    height = MAX(radius * 2.0 + 2.0, roundf(height));
    CGFloat width = radius * 2.0 + 6.0;
    UIImage *image = RBSkinRender(key, CGSizeMake(width, height), ^(CGContextRef context, CGSize size) {
        CGRect body = CGRectMake(0.0, 0.0, size.width, size.height);
        CGRect inner = CGRectInset(body, 1.0, 1.0);
        UIBezierPath *innerPath = [UIBezierPath bezierPathWithRoundedRect:inner
                                                             cornerRadius:MAX(0.0, radius - 1.0)];
        CGContextSaveGState(context);
        [innerPath addClip];
        if (fill) {
            [fill setFill];
            CGContextFillRect(context, inner);
        }
        // Inner shadow cast by the bar onto the field's top edge.
        RBFillGradient(context, CGRectMake(0.0, 1.0, size.width, 4.5),
                       @[RBRGBA(0, 0, 0, dark ? 0.60 : 0.32), RBRGBA(0, 0, 0, 0.0)], NULL);
        CGContextRestoreGState(context);
        UIBezierPath *ring = [UIBezierPath bezierPathWithRoundedRect:body cornerRadius:radius];
        [ring appendPath:innerPath];
        ring.usesEvenOddFillRule = YES;
        [(dark ? RBRGB(8, 8, 10) : RBRGB(93, 115, 142)) setFill];
        [ring fill];
    });
    CGFloat top = floorf(image.size.height / 2.0);
    CGFloat bottom = MAX(0.0, image.size.height - top - 1.0);
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(top, radius + 2.0, bottom, radius + 2.0)
                                 resizingMode:UIImageResizingModeStretch];
}

+ (UIImage *)fieldOverlayWithRadius:(CGFloat)radius height:(CGFloat)height dark:(BOOL)dark {
    NSString *key = [NSString stringWithFormat:@"field.%.1f.%.1f.%d", radius, height, dark];
    return RBFieldImage(key, radius, height, dark, nil);
}

+ (UIImage *)filledFieldImageWithRadius:(CGFloat)radius height:(CGFloat)height dark:(BOOL)dark {
    NSString *key = [NSString stringWithFormat:@"field-fill.%.1f.%.1f.%d", radius, height, dark];
    return RBFieldImage(key, radius, height, dark, [self fieldFillColorDark:dark]);
}

+ (NSArray *)progressColorsDark:(BOOL)dark {
    // iOS 6 Safari fills the address field itself with blue while loading.
    // The dark field keeps light text, so its fill is a deep blue instead.
    if (dark) return @[(id)[RBRGB(62, 100, 162) CGColor], (id)[RBRGB(34, 66, 124) CGColor]];
    return @[(id)[RBRGB(182, 214, 250) CGColor], (id)[RBRGB(116, 168, 238) CGColor]];
}

// ------------------------------------------------------------------ badges

+ (UIImage *)closeBadgeImageWithSide:(CGFloat)side {
    NSString *key = [NSString stringWithFormat:@"close-badge.%.1f", side];
    return RBSkinRender(key, CGSizeMake(side, side), ^(CGContextRef context, CGSize size) {
        CGRect ring = CGRectInset(CGRectMake(0.0, 0.0, size.width, size.height), 2.0, 2.0);
        CGContextSaveGState(context);
        CGContextSetShadowWithColor(context, CGSizeZero, 2.5, [RBRGBA(0, 0, 0, 0.65) CGColor]);
        [[UIColor whiteColor] setFill];
        [[UIBezierPath bezierPathWithOvalInRect:ring] fill];
        CGContextRestoreGState(context);
        CGRect face = CGRectInset(ring, 2.0, 2.0);
        CGContextSaveGState(context);
        [[UIBezierPath bezierPathWithOvalInRect:face] addClip];
        RBFillGradient(context, face, @[RBRGB(238, 88, 88), RBRGB(176, 18, 22)], NULL);
        CGRect gloss = face;
        gloss.size.height = floorf(face.size.height * 0.52);
        RBFillGradient(context, gloss, @[RBRGBA(255, 255, 255, 0.45), RBRGBA(255, 255, 255, 0.06)], NULL);
        CGContextRestoreGState(context);
        CGFloat c = size.width / 2.0, arm = side * 0.15;
        [[UIColor whiteColor] setStroke];
        UIBezierPath *cross = [UIBezierPath bezierPath];
        [cross moveToPoint:CGPointMake(c - arm, c - arm)];
        [cross addLineToPoint:CGPointMake(c + arm, c + arm)];
        [cross moveToPoint:CGPointMake(c + arm, c - arm)];
        [cross addLineToPoint:CGPointMake(c - arm, c + arm)];
        cross.lineWidth = MAX(2.0, side * 0.09);
        cross.lineCapStyle = kCGLineCapRound;
        [cross stroke];
    });
}

+ (UIImage *)activityTileWithIcon:(RBIcon)icon side:(CGFloat)side
                          enabled:(BOOL)enabled pressed:(BOOL)pressed {
    NSString *key = [NSString stringWithFormat:@"activity.%d.%.1f.%d", (int)icon, side, pressed];
    UIImage *tile = RBSkinRender(key, CGSizeMake(side, side), ^(CGContextRef context, CGSize size) {
        CGFloat radius = roundf(side * 0.18);
        CGRect body = CGRectMake(0.0, 0.0, size.width, size.height);
        CGContextSaveGState(context);
        [[UIBezierPath bezierPathWithRoundedRect:body cornerRadius:radius] addClip];
        RBFillGradient(context, body, @[RBRGB(238, 238, 240), RBRGB(146, 148, 153)], NULL);
        CGFloat rim = MAX(2.0, roundf(side * 0.045));
        CGRect face = CGRectInset(body, rim, rim);
        [[UIBezierPath bezierPathWithRoundedRect:face cornerRadius:MAX(1.0, radius - rim)] addClip];
        RBFillGradient(context, face, @[RBRGB(68, 69, 73), RBRGB(27, 28, 31)], NULL);
        // Perforated metal, as on the system Copy / Print / Bookmark icons.
        for (CGFloat y = face.origin.y + 2.0; y < CGRectGetMaxY(face); y += 4.0) {
            BOOL odd = ((int)((y - face.origin.y) / 4.0)) % 2;
            for (CGFloat x = face.origin.x + (odd ? 4.0 : 2.0); x < CGRectGetMaxX(face); x += 4.0) {
                [RBRGBA(0, 0, 0, 0.45) setFill];
                CGContextFillEllipseInRect(context, CGRectMake(x - 0.8, y - 0.8, 1.6, 1.6));
                [RBRGBA(255, 255, 255, 0.07) setFill];
                CGContextFillEllipseInRect(context, CGRectMake(x - 0.8, y + 0.2, 1.6, 1.2));
            }
        }
        [RBRGBA(255, 255, 255, 0.14) setFill];
        CGContextFillRect(context, CGRectMake(face.origin.x, face.origin.y, face.size.width, 1.0));
        CGContextRestoreGState(context);

        CGFloat glyphSide = roundf(side * 0.52);
        UIImage *mask = [RBClassicSkin maskForIcon:icon size:glyphSide];
        CGPoint origin = CGPointMake(roundf((size.width - glyphSide) / 2.0),
                                     roundf((size.height - glyphSide) / 2.0));
        [RBTinted(mask, RBRGBA(0, 0, 0, 0.80)) drawAtPoint:CGPointMake(origin.x, origin.y + 1.0)];
        [RBGradientTinted(mask, RBRGB(255, 255, 255), RBRGB(184, 186, 191)) drawAtPoint:origin];

        if (pressed) {
            [RBRGBA(0, 0, 0, 0.38) setFill];
            [[UIBezierPath bezierPathWithRoundedRect:body cornerRadius:radius] fill];
        }
    });
    if (enabled) return tile;
    return RBFaded([key stringByAppendingString:@".off"], tile, 0.35);
}

+ (UIImage *)sheetBackgroundImage {
    UIImage *image = RBSkinRender(@"sheet", CGSizeMake(4.0, 72.0), ^(CGContextRef context, CGSize size) {
        [RBRGBA(0, 0, 0, 0.70) setFill];
        CGContextFillRect(context, CGRectMake(0.0, 0.0, size.width, 1.0));
        [RBRGBA(255, 255, 255, 0.32) setFill];
        CGContextFillRect(context, CGRectMake(0.0, 1.0, size.width, 1.0));
        CGFloat locations[] = {0.0, 0.78, 1.0};
        RBFillGradient(context, CGRectMake(0.0, 2.0, size.width, size.height - 2.0),
                       @[RBRGBA(104, 106, 111, 0.97), RBRGBA(46, 47, 51, 0.97),
                         RBRGBA(38, 39, 43, 0.97)], locations);
    });
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(70.0, 1.0, 1.0, 1.0)
                                 resizingMode:UIImageResizingModeStretch];
}

+ (UIImage *)hudImageWithRadius:(CGFloat)radius {
    NSString *key = [NSString stringWithFormat:@"hud.%.1f", radius];
    CGFloat side = radius * 2.0 + 4.0;
    UIImage *image = RBSkinRender(key, CGSizeMake(side, side), ^(CGContextRef context, CGSize size) {
        CGRect body = CGRectMake(0.0, 0.0, size.width, size.height);
        UIBezierPath *outer = [UIBezierPath bezierPathWithRoundedRect:body cornerRadius:radius];
        CGContextSaveGState(context);
        [outer addClip];
        RBFillGradient(context, body, @[RBRGBA(46, 47, 50, 0.80), RBRGBA(4, 4, 5, 0.86)], NULL);
        CGContextRestoreGState(context);
        UIBezierPath *edge = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(body, 0.5, 0.5)
                                                        cornerRadius:MAX(0.0, radius - 0.5)];
        edge.lineWidth = 1.0;
        [RBRGBA(255, 255, 255, 0.24) setStroke];
        [edge stroke];
    });
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(radius + 1.0, radius + 1.0,
                                                               radius + 1.0, radius + 1.0)
                                 resizingMode:UIImageResizingModeStretch];
}

+ (UIImage *)cardImageWithRadius:(CGFloat)radius pressed:(BOOL)pressed dark:(BOOL)dark {
    NSString *key = [NSString stringWithFormat:@"card.%.1f.%d.%d", radius, pressed, dark];
    CGFloat width = radius * 2.0 + 6.0;
    CGFloat height = radius * 2.0 + 8.0;
    UIImage *image = RBSkinRender(key, CGSizeMake(width, height), ^(CGContextRef context, CGSize size) {
        CGRect body = CGRectMake(0.0, 0.0, size.width, size.height - 1.0);
        [RBRGBA(0, 0, 0, dark ? 0.45 : 0.16) setFill];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectOffset(body, 0.0, 1.0) cornerRadius:radius] fill];
        RBClear(context, [UIBezierPath bezierPathWithRoundedRect:body cornerRadius:radius]);
        [(dark ? RBRGBA(0, 0, 0, 0.85) : RBRGBA(0, 0, 0, 0.24)) setFill];
        [[UIBezierPath bezierPathWithRoundedRect:body cornerRadius:radius] fill];
        CGRect inner = CGRectInset(body, 1.0, 1.0);
        CGContextSaveGState(context);
        [[UIBezierPath bezierPathWithRoundedRect:inner cornerRadius:MAX(0.0, radius - 1.0)] addClip];
        NSArray *colors = pressed ? @[RBRGB(214, 228, 250), RBRGB(186, 206, 238)]
                        : dark ? @[RBRGB(72, 72, 76), RBRGB(50, 50, 54)]
                               : @[RBRGB(255, 255, 255), RBRGB(239, 240, 242)];
        RBFillGradient(context, inner, colors, NULL);
        [RBRGBA(255, 255, 255, dark ? 0.14 : 1.0) setFill];
        CGContextFillRect(context, CGRectMake(inner.origin.x, inner.origin.y, inner.size.width, 1.0));
        CGContextRestoreGState(context);
    });
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(radius + 2.0, radius + 2.0,
                                                               radius + 3.0, radius + 2.0)
                                 resizingMode:UIImageResizingModeStretch];
}

+ (UIImage *)iconTileWithColor:(UIColor *)color side:(CGFloat)side {
    NSString *key = [NSString stringWithFormat:@"icon-tile.%@.%.1f", RBColorKey(color), side];
    return RBSkinRender(key, CGSizeMake(side, side), ^(CGContextRef context, CGSize size) {
        CGFloat r = 0.0, g = 0.0, b = 0.0, a = 1.0;
        if (![color getRed:&r green:&g blue:&b alpha:&a]) r = g = b = 0.5;
        UIColor *light = [UIColor colorWithRed:MIN(1.0, r * 1.18 + 0.06) green:MIN(1.0, g * 1.18 + 0.06)
                                          blue:MIN(1.0, b * 1.18 + 0.06) alpha:1.0];
        UIColor *deep = [UIColor colorWithRed:r * 0.80 green:g * 0.80 blue:b * 0.80 alpha:1.0];
        CGRect body = CGRectMake(0.0, 0.0, size.width, size.height);
        CGFloat radius = roundf(side * 0.22);
        CGContextSaveGState(context);
        [[UIBezierPath bezierPathWithRoundedRect:body cornerRadius:radius] addClip];
        RBFillGradient(context, body, @[light, deep], NULL);
        // The arched gloss of an iOS 6 home screen icon.
        UIBezierPath *gloss = [UIBezierPath bezierPath];
        [gloss moveToPoint:CGPointMake(0.0, 0.0)];
        [gloss addLineToPoint:CGPointMake(size.width, 0.0)];
        [gloss addLineToPoint:CGPointMake(size.width, size.height * 0.42)];
        [gloss addQuadCurveToPoint:CGPointMake(0.0, size.height * 0.42)
                      controlPoint:CGPointMake(size.width / 2.0, size.height * 0.60)];
        [gloss closePath];
        [gloss addClip];
        RBFillGradient(context, CGRectMake(0.0, 0.0, size.width, size.height * 0.55),
                       @[RBRGBA(255, 255, 255, 0.55), RBRGBA(255, 255, 255, 0.10)], NULL);
        CGContextRestoreGState(context);
    });
}

// --------------------------------------------------------------- backdrops

+ (UIColor *)linenColorDark:(BOOL)dark {
    if (dark && [UIColor respondsToSelector:@selector(scrollViewTexturedBackgroundColor)]) {
        return [UIColor scrollViewTexturedBackgroundColor];
    }
    if (!dark && [UIColor respondsToSelector:@selector(underPageBackgroundColor)]) {
        return [UIColor underPageBackgroundColor];
    }
    return dark ? RBRGB(46, 47, 50) : [self pinstripeColor];
}

+ (UIColor *)pinstripeColor {
    return [UIColor groupTableViewBackgroundColor];
}

// -------------------------------------------------------------------- text

+ (void)styleLetterpressLabel:(UILabel *)label dark:(BOOL)dark {
    label.backgroundColor = [UIColor clearColor];
    label.textColor = dark ? RBRGB(224, 226, 230) : RBRGB(76, 86, 108);
    label.shadowColor = dark ? RBRGBA(0, 0, 0, 0.80) : RBRGBA(255, 255, 255, 0.80);
    label.shadowOffset = dark ? CGSizeMake(0.0, -1.0) : CGSizeMake(0.0, 1.0);
}

+ (void)styleBarTitleLabel:(UILabel *)label dark:(BOOL)dark {
    label.backgroundColor = [UIColor clearColor];
    label.textColor = dark ? RBRGB(216, 216, 218) : RBRGB(60, 70, 81);
    label.shadowColor = dark ? RBRGBA(0, 0, 0, 0.90) : RBRGBA(255, 255, 255, 0.55);
    label.shadowOffset = dark ? CGSizeMake(0.0, -1.0) : CGSizeMake(0.0, 1.0);
}

+ (void)styleEmbossedLabel:(UILabel *)label {
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.shadowColor = RBRGBA(0, 0, 0, 0.60);
    label.shadowOffset = CGSizeMake(0.0, -1.0);
}

@end

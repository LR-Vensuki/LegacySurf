#import <UIKit/UIKit.h>

#import "RBTheme.h"

// Legacy Surf: the iOS 6 (skeuomorphic) artwork. Every image is drawn with
// Core Graphics at runtime and cached, so the package ships no extra bitmaps
// and the artwork follows the screen scale. Colors were sampled from iOS 6
// Safari and UIKit. RBTheme and the browser views route here only while
// +[RBTheme usesClassicAppearance] is YES; iOS 7 and later keep Surf's flat UI.

typedef enum {
    RBClassicButtonBlue,    // default action: the alert / keyboard "Go" blue
    RBClassicButtonSilver,  // secondary action on light surfaces (action sheet)
    RBClassicButtonBlack,   // Cancel on a dark sheet
    RBClassicButtonBar,     // bordered UIBarButtonItem on a toolbar
    RBClassicButtonBarDone, // UIBarButtonItemStyleDone
    RBClassicButtonRed      // destructive
} RBClassicButtonStyle;

@interface RBClassicSkin : NSObject

// Toolbar and navigation bar body, for a CAGradientLayer.
+ (NSArray *)barColorsDark:(BOOL)dark;
+ (NSArray *)barLocationsDark:(BOOL)dark;
// 1pt dark rule on the page side of a bar, and the 1pt sheen opposite it.
+ (UIColor *)barRuleColorDark:(BOOL)dark;
+ (UIColor *)barSheenColorDark:(BOOL)dark;
// Slate backdrop of the iOS 6 Safari page switcher, for a CAGradientLayer.
+ (NSArray *)pagesBackgroundColors;

// White glyph mask: the classic solid shapes for the browser controls, the
// bundled Lucide font for everything else.
+ (UIImage *)maskForIcon:(RBIcon)icon size:(CGFloat)size;
// Solid glyph with an optional hard 1pt shadow (nil for none). The canvas is
// padded symmetrically so UIKit still centers the glyph itself.
+ (UIImage *)glyph:(RBIcon)icon size:(CGFloat)size color:(UIColor *)color
       shadowColor:(UIColor *)shadowColor shadowOffset:(CGFloat)offsetY;
// Toolbar glyph: white, etched with a dark shadow above it.
+ (UIImage *)barGlyph:(RBIcon)icon size:(CGFloat)size dark:(BOOL)dark enabled:(BOOL)enabled;

// Horizontally stretchable glossy button, drawn for an exact height.
+ (UIImage *)buttonImage:(RBClassicButtonStyle)style height:(CGFloat)height
                  radius:(CGFloat)radius pressed:(BOOL)pressed dark:(BOOL)dark;
+ (void)styleButton:(UIButton *)button style:(RBClassicButtonStyle)style
             height:(CGFloat)height radius:(CGFloat)radius dark:(BOOL)dark;
// Selected tab on the iPad rail (unselected tabs use the bordered bar button).
+ (UIImage *)activeTabImageWithHeight:(CGFloat)height dark:(BOOL)dark;
// Border and inner shadow of a Safari text field. The fill stays a view color
// so the loading progress can run underneath the shadow.
+ (UIImage *)fieldOverlayWithRadius:(CGFloat)radius height:(CGFloat)height dark:(BOOL)dark;
// The same field with its fill, for static search pills.
+ (UIImage *)filledFieldImageWithRadius:(CGFloat)radius height:(CGFloat)height dark:(BOOL)dark;
+ (UIColor *)fieldFillColorDark:(BOOL)dark;
+ (NSArray *)progressColorsDark:(BOOL)dark;

// iOS 6 Safari's red "close page" badge.
+ (UIImage *)closeBadgeImageWithSide:(CGFloat)side;
// Share-sheet activity icon: silver rim, perforated dark face, metal glyph.
+ (UIImage *)activityTileWithIcon:(RBIcon)icon side:(CGFloat)side
                          enabled:(BOOL)enabled pressed:(BOOL)pressed;
// Dark translucent sheet behind the activity tiles.
+ (UIImage *)sheetBackgroundImage;
// Translucent black HUD (toast, fullscreen controls).
+ (UIImage *)hudImageWithRadius:(CGFloat)radius;
// Glossy card for New Tab favorites and the pairing phrase.
+ (UIImage *)cardImageWithRadius:(CGFloat)radius pressed:(BOOL)pressed dark:(BOOL)dark;
// Glossy app-icon square in a solid color.
+ (UIImage *)iconTileWithColor:(UIColor *)color side:(CGFloat)side;

// Backdrops: the under-page linen behind Safari pages, dark linen, pinstripes.
+ (UIColor *)linenColorDark:(BOOL)dark;
+ (UIColor *)pinstripeColor;

// Letterpress text for linen and pinstripes, engraved text for bars, and the
// white embossed text of bar items and dark sheets.
+ (void)styleLetterpressLabel:(UILabel *)label dark:(BOOL)dark;
+ (void)styleBarTitleLabel:(UILabel *)label dark:(BOOL)dark;
+ (void)styleEmbossedLabel:(UILabel *)label;

@end

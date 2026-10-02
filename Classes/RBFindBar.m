#import "RBFindBar.h"
#import "RBClassicSkin.h"
#import "RBTheme.h"

#import <QuartzCore/QuartzCore.h>

#include <math.h>

@interface RBFindBar () <UITextFieldDelegate>
@property(nonatomic, strong) RBGradientBar *background;
@property(nonatomic, strong) UITextField *field;
@property(nonatomic, strong) UIButton *prevButton;
@property(nonatomic, strong) UIButton *nextButton;
@property(nonatomic, strong) UIButton *doneButton;
@property(nonatomic, strong) UILabel *stateLabel;
@end

@implementation RBFindBar

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.background = [[RBGradientBar alloc] initWithFrame:self.bounds];
        [self.background setHairlineAtTop:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)];
        self.background.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.background.userInteractionEnabled = NO;
        [self addSubview:self.background];

        self.field = [[UITextField alloc] initWithFrame:CGRectZero];
        self.field.delegate = self;
        self.field.borderStyle = UITextBorderStyleNone;
        self.field.backgroundColor = [RBTheme surfaceColor];
        self.field.layer.cornerRadius = 8.0;
        self.field.layer.borderWidth = 1.0;
        self.field.layer.borderColor = [[RBTheme mistColor] CGColor];
        self.field.font = [RBTheme fontOfSize:14.0 bold:NO];
        self.field.textColor = [RBTheme primaryTextColor];
        self.field.placeholder = @"Find on page";
        self.field.autocorrectionType = UITextAutocorrectionTypeNo;
        self.field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        self.field.returnKeyType = UIReturnKeySearch;
        self.field.clearButtonMode = UITextFieldViewModeWhileEditing;
        [self addSubview:self.field];

        self.prevButton = [RBTheme barButtonWithIcon:RBIconChevronUp target:self action:@selector(prevTapped:)];
        self.nextButton = [RBTheme barButtonWithIcon:RBIconChevronDown target:self action:@selector(nextTapped:)];
        [self addSubview:self.prevButton];
        [self addSubview:self.nextButton];

        self.stateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.stateLabel.backgroundColor = [UIColor clearColor];
        self.stateLabel.font = [RBTheme fontOfSize:12.0 bold:NO];
        self.stateLabel.textColor = [UIColor colorWithRed:0.72 green:0.24 blue:0.28 alpha:1.0];
        [self addSubview:self.stateLabel];

        self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.doneButton setTitle:@"Done" forState:UIControlStateNormal];
        [self.doneButton setTitleColor:[RBTheme iconColor] forState:UIControlStateNormal];
        [self.doneButton setTitleColor:[[RBTheme iconColor] colorWithAlphaComponent:0.4] forState:UIControlStateHighlighted];
        self.doneButton.titleLabel.font = [RBTheme displayFontOfSize:14.0];
        [self.doneButton addTarget:self action:@selector(doneTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.doneButton];

        if ([RBTheme usesClassicAppearance]) {
            // UIKit's own iOS 6 rounded field: white, inset, gray rim.
            self.field.borderStyle = UITextBorderStyleRoundedRect;
            self.field.layer.cornerRadius = 0.0;
            self.field.layer.borderWidth = 0.0;
            self.field.backgroundColor = nil;
            self.field.textColor = [UIColor blackColor];
            self.field.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            self.doneButton.titleLabel.font = [RBTheme displayFontOfSize:12.0];
            [self applyClassicStyle];
        }
    }
    return self;
}

- (void)applyClassicStyle {
    BOOL dark = [RBTheme isDarkMode];
    [RBClassicSkin styleButton:self.doneButton style:RBClassicButtonBarDone height:30.0 radius:5.0 dark:dark];
    self.stateLabel.textColor = dark ? [UIColor colorWithRed:1.0 green:0.55 blue:0.55 alpha:1.0]
                                     : [UIColor colorWithRed:0.45 green:0.08 blue:0.10 alpha:1.0];
    self.stateLabel.shadowColor = dark ? [UIColor colorWithWhite:0.0 alpha:0.8]
                                       : [UIColor colorWithWhite:1.0 alpha:0.5];
    self.stateLabel.shadowOffset = dark ? CGSizeMake(0.0, -1.0) : CGSizeMake(0.0, 1.0);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat y = floorf((h - 28.0) / 2.0);
    BOOL compact = w < 520.0;
    CGFloat buttonW = compact ? 36.0 : 40.0;
    CGFloat doneW = compact ? 52.0 : 56.0;
    CGFloat margin = compact ? 6.0 : 8.0;
    CGFloat doneX = w - doneW - margin;
    CGFloat fieldW = compact
        ? MAX(80.0, doneX - margin - buttonW * 2.0 - 6.0 - margin)
        : MIN(320.0, w * 0.42);
    self.field.frame = CGRectMake(margin, y, fieldW, 28.0);
    CGFloat x = CGRectGetMaxX(self.field.frame) + 4.0;
    self.prevButton.frame = CGRectMake(x, 0.0, buttonW, h);
    self.nextButton.frame = CGRectMake(x + buttonW, 0.0, buttonW, h);
    CGFloat stateX = x + buttonW * 2.0 + 8.0;
    self.stateLabel.hidden = compact;
    self.stateLabel.frame = CGRectMake(stateX, 0.0, MAX(0.0, doneX - stateX - 6.0), h);
    self.doneButton.frame = CGRectMake(doneX, 0.0, doneW, h);
    if ([RBTheme usesClassicAppearance]) {
        // Bar buttons are 30pt keys centred on the bar, not full-height hit areas.
        self.doneButton.frame = CGRectMake(doneX, floorf((h - 30.0) / 2.0), doneW, 30.0);
    }
}

- (void)focusField {
    [self.field becomeFirstResponder];
    [self.field selectAll:nil];
}

- (void)setPageBoundaryAtTop:(BOOL)top {
    [self.background setHairlineAtTop:top];
}

- (BOOL)editing {
    return [self.field isFirstResponder];
}

- (void)setFound:(BOOL)found {
    self.stateLabel.text = found ? @"" : @"Not found";
}

- (void)applyAppearance {
    [self.background setTopColor:[RBTheme barTopColor]
                     bottomColor:[RBTheme barBottomColor]
                       lineColor:[RBTheme barLineColor]];
    self.field.backgroundColor = [RBTheme surfaceColor];
    self.field.textColor = [RBTheme primaryTextColor];
    [RBTheme styleKeyboard:self.field];
    self.field.layer.borderColor = [[RBTheme mistColor] CGColor];
    [RBTheme styleBarButton:self.prevButton icon:RBIconChevronUp];
    [RBTheme styleBarButton:self.nextButton icon:RBIconChevronDown];
    if ([RBTheme usesClassicAppearance]) {
        self.field.backgroundColor = nil;
        self.field.textColor = [UIColor blackColor];
        [self applyClassicStyle];
        return;
    }
    [self.doneButton setTitleColor:[RBTheme iconColor] forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[[RBTheme iconColor] colorWithAlphaComponent:0.4]
                           forState:UIControlStateHighlighted];
}

- (void)searchDirection:(NSInteger)direction {
    NSString *query = [self.field.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![query length]) return;
    self.stateLabel.text = @"";
    [self.delegate findBar:self search:query direction:direction];
}

- (void)prevTapped:(id)sender { [self searchDirection:-1]; }
- (void)nextTapped:(id)sender { [self searchDirection:1]; }

- (void)doneTapped:(id)sender {
    [self.field resignFirstResponder];
    [self.delegate findBarDone:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self searchDirection:1];
    [textField resignFirstResponder];
    return NO;
}

@end

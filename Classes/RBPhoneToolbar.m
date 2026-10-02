#import "RBPhoneToolbar.h"

#import <QuartzCore/QuartzCore.h>

@interface RBPhoneToolbar ()
@property(nonatomic, strong) UIButton *backButton;
@property(nonatomic, strong) UIButton *forwardButton;
@property(nonatomic, strong, readwrite) UIButton *shareButton;
@property(nonatomic, strong, readwrite) UIButton *pagesButton;
@property(nonatomic, strong, readwrite) UIButton *moreButton;
@property(nonatomic, strong) UILabel *tabCountLabel;
@end

@implementation RBPhoneToolbar

@synthesize shareButton = _shareButton;
@synthesize pagesButton = _pagesButton;
@synthesize moreButton = _moreButton;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backButton = [RBTheme barButtonWithIcon:RBIconBack target:self action:@selector(backTapped:)];
        self.forwardButton = [RBTheme barButtonWithIcon:RBIconForward target:self action:@selector(forwardTapped:)];
        self.shareButton = [RBTheme barButtonWithIcon:RBIconShare target:self action:@selector(shareTapped:)];
        self.pagesButton = [RBTheme barButtonWithIcon:RBIconTabs target:self action:@selector(pagesTapped:)];
        self.moreButton = [RBTheme barButtonWithIcon:RBIconMore target:self action:@selector(moreTapped:)];
        self.backButton.enabled = NO;
        self.forwardButton.enabled = NO;
        NSArray *buttons = @[self.backButton, self.forwardButton, self.shareButton,
                             self.pagesButton, self.moreButton];
        NSArray *labels = @[@"Back", @"Forward", @"Share", @"Tabs", @"More"];
        for (NSUInteger i = 0; i < [buttons count]; i++) {
            UIButton *button = [buttons objectAtIndex:i];
            button.accessibilityLabel = [labels objectAtIndex:i];
            [self addSubview:button];
        }

        self.tabCountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.tabCountLabel.backgroundColor = [RBTheme deepTideColor];
        self.tabCountLabel.textColor = [UIColor whiteColor];
        self.tabCountLabel.font = [RBTheme fontOfSize:9.0 bold:YES];
        self.tabCountLabel.textAlignment = NSTextAlignmentCenter;
        self.tabCountLabel.layer.cornerRadius = 7.5;
        self.tabCountLabel.layer.borderWidth = 1.0;
        self.tabCountLabel.layer.borderColor = [[RBTheme foamColor] CGColor];
        self.tabCountLabel.layer.masksToBounds = YES;
        self.tabCountLabel.userInteractionEnabled = NO;
        [self.pagesButton addSubview:self.tabCountLabel];
        if ([RBTheme usesClassicAppearance]) {
            // An iOS 6 toolbar: dark rule along the page, and Safari writes
            // the page count onto the front page of its Pages glyph.
            [self setHairlineAtTop:YES];
            self.tabCountLabel.font = [RBTheme fontOfSize:11.0 bold:YES];
            self.tabCountLabel.adjustsFontSizeToFitWidth = YES;
            self.tabCountLabel.minimumScaleFactor = 0.6;
            self.tabCountLabel.layer.cornerRadius = 0.0;
            self.tabCountLabel.layer.borderWidth = 0.0;
            self.tabCountLabel.layer.masksToBounds = NO;
            [self applyClassicCountStyle];
        }
        [self setTabCount:0];
    }
    return self;
}

- (void)applyClassicCountStyle {
    BOOL dark = [RBTheme isDarkMode];
    self.tabCountLabel.backgroundColor = [UIColor clearColor];
    self.tabCountLabel.textColor = dark ? [UIColor colorWithWhite:0.10 alpha:1.0]
                                        : [UIColor colorWithRed:0.24 green:0.29 blue:0.36 alpha:1.0];
    self.tabCountLabel.shadowColor = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat buttonW = self.bounds.size.width / 5.0;
    NSArray *buttons = @[self.backButton, self.forwardButton, self.shareButton,
                         self.pagesButton, self.moreButton];
    for (NSUInteger i = 0; i < [buttons count]; i++) {
        CGFloat x0 = floorf(buttonW * i);
        CGFloat x1 = floorf(buttonW * (i + 1));
        ((UIButton *)[buttons objectAtIndex:i]).frame = CGRectMake(x0, 0.0, x1 - x0, self.bounds.size.height);
    }
    if ([RBTheme usesClassicAppearance]) {
        // Front page of the 22pt Pages glyph: x/y 0.34-0.90 of the glyph,
        // whose image carries 1pt of shadow padding above and below.
        [self.pagesButton layoutIfNeeded];
        CGRect glyph = self.pagesButton.imageView.frame;
        CGFloat side = 22.0;
        CGFloat originX = CGRectGetMinX(glyph) + floorf((glyph.size.width - side) / 2.0);
        CGFloat originY = CGRectGetMinY(glyph) + floorf((glyph.size.height - side) / 2.0);
        self.tabCountLabel.frame = CGRectMake(originX + side * 0.34, originY + side * 0.34 + 0.5,
                                              side * 0.56, side * 0.56);
        return;
    }
    self.tabCountLabel.frame = CGRectMake(floorf(self.pagesButton.bounds.size.width / 2.0 + 4.0),
                                           4.0, 20.0, 15.0);
}

- (void)setCanGoBack:(BOOL)back forward:(BOOL)forward {
    self.backButton.enabled = back;
    self.forwardButton.enabled = forward;
}

- (void)setTabCount:(NSUInteger)count {
    self.tabCountLabel.text = count > 99 ? @"99+" : [NSString stringWithFormat:@"%u", (unsigned int)count];
    self.tabCountLabel.hidden = count == 0;
    self.pagesButton.accessibilityValue = [NSString stringWithFormat:@"%u open", (unsigned int)count];
}

- (void)applyAppearance {
    [self setTopColor:[RBTheme barTopColor]
          bottomColor:[RBTheme barBottomColor]
            lineColor:[RBTheme barLineColor]];
    [RBTheme styleBarButton:self.backButton icon:RBIconBack];
    [RBTheme styleBarButton:self.forwardButton icon:RBIconForward];
    [RBTheme styleBarButton:self.shareButton icon:RBIconShare];
    [RBTheme styleBarButton:self.pagesButton icon:RBIconTabs];
    [RBTheme styleBarButton:self.moreButton icon:RBIconMore];
    if ([RBTheme usesClassicAppearance]) {
        [self applyClassicCountStyle];
        [self setNeedsLayout];
        return;
    }
    self.tabCountLabel.backgroundColor = [RBTheme deepTideColor];
    self.tabCountLabel.layer.borderColor = [[RBTheme foamColor] CGColor];
}

- (void)backTapped:(id)sender { [self.delegate phoneToolbarBack:self]; }
- (void)forwardTapped:(id)sender { [self.delegate phoneToolbarForward:self]; }
- (void)shareTapped:(id)sender { [self.delegate phoneToolbar:self shareFromButton:self.shareButton]; }
- (void)pagesTapped:(id)sender { [self.delegate phoneToolbar:self pagesFromButton:self.pagesButton]; }
- (void)moreTapped:(id)sender { [self.delegate phoneToolbar:self moreFromButton:self.moreButton]; }

@end

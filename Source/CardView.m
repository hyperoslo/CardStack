#import "CardView.h"
#import "Masonry.h"

static const CGFloat CardTitleBarHeight = 44.0f;
static const CGFloat CardCornerRadius = 4.0f;
static const CGFloat CardShadowImageViewVerticalOffset = -13.0f;
static const CGFloat CardStackTitleBarShineImageHeight = 1.0f;

@interface CardView ()

@property (nonatomic) UIViewController *viewController;
@property (nonatomic) UIView *contentView;
@property (nonatomic) UIView *titleBarView;
@property (nonatomic) UIView *titleBarDecorationView;
@property (nonatomic) UIImageView *titleBarShadowImageView;
@property (nonatomic) UIImageView *titleBarShineImageView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UITapGestureRecognizer *tapRecognizer;

@property (nonatomic) MASConstraint *titleBarHeightConstraint;
@property (nonatomic) MASConstraint *titleLabelTopConstraint;

@end

@implementation CardView

@synthesize titleColor = _titleColor;
@synthesize titleFont = _titleFont;
@synthesize titleBarDecorationColor = _titleBarDecorationColor;

+ (CardView *)cardWithViewController:(UIViewController *)viewController {
    CardView *card = [[CardView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    card.viewController = viewController;
    return card;
}

+ (NSArray *)cardsWithViewControllers:(NSArray *)viewControllers {
    NSMutableArray *cards = [NSMutableArray array];

    for (UIViewController *viewController in viewControllers) {
        [cards addObject:[CardView cardWithViewController:viewController]];
    }

    return [NSArray arrayWithArray:cards];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.titleBarHeight = CardTitleBarHeight;

    [self addSubview:self.titleBarShadowImageView];
    [self addSubview:self.contentView];
    [self.contentView addSubview:self.titleBarView];
    [self.titleBarView addSubview:self.titleBarDecorationView];
    [self.titleBarView addSubview:self.titleBarShineImageView];
    [self.titleBarView addSubview:self.titleLabel];

    [self.titleBarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_left);
        make.right.equalTo(self.contentView.mas_right);
        make.top.equalTo(self.contentView.mas_top);
        self.titleBarHeightConstraint = make.height.equalTo(@(self.titleBarHeight));
    }];

    [self.titleBarDecorationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.titleBarView);
        make.size.equalTo(self.titleBarView);
    }];

    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        self.titleLabelTopConstraint = make.top.equalTo(self.titleBarView.mas_top).with.offset(self.titleLabelVerticalOffset);
        make.centerX.equalTo(self.titleBarView.mas_centerX);
        make.width.equalTo(self.titleBarView);
        make.height.equalTo(self.titleBarView);
    }];

    // using shadows drops frame rate noticeably even on an iPhone 6
    // self.layer.shadowColor = [[UIColor blackColor] CGColor];
    // self.layer.shadowOpacity = 0.5;

    return self;
}

#pragma mark - Getters

- (UIColor *)titleBarBackgroundColor {
    return self.titleBarView.backgroundColor;
}

- (UIColor *)titleBarDecorationColor {
    if (_titleBarDecorationColor) return _titleBarDecorationColor;

    _titleBarDecorationColor = [UIColor clearColor];

    return _titleBarDecorationColor;
}

- (UIColor *)titleColor {
    if (_titleColor) return _titleColor;

    _titleColor = [UIColor whiteColor];

    return _titleColor;
}

- (UIFont *)titleFont {
    if (_titleFont) return _titleFont;

    _titleFont = [UIFont boldSystemFontOfSize:18.0f];

    return _titleFont;
}

- (UIView *)contentView {
    if (_contentView) return _contentView;

    _contentView = [[UIView alloc] initWithFrame:self.bounds];
    _contentView.layer.cornerRadius = CardCornerRadius;
    _contentView.clipsToBounds = YES;

    return _contentView;
}

- (UIView *)titleBarView {
    if (_titleBarView) return _titleBarView;

    _titleBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.titleBarHeight)];
    _titleBarView.backgroundColor = self.titleBarBackgroundColor;
    _titleBarView.userInteractionEnabled = YES;
    _titleBarView.layer.cornerRadius = CardCornerRadius;
    _titleBarView.clipsToBounds = YES;
    [_titleBarView addGestureRecognizer:self.tapRecognizer];
    [_titleBarView addGestureRecognizer:self.panRecognizer];

    return _titleBarView;
}

- (UIView *)titleBarDecorationView {
    if (_titleBarDecorationView) return _titleBarDecorationView;

    _titleBarDecorationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.titleBarHeight)];
    _titleBarDecorationView.backgroundColor = self.titleBarDecorationColor;

    return _titleBarDecorationView;
}

- (UIImageView *)titleBarShadowImageView {
    if (_titleBarShadowImageView) return _titleBarShadowImageView;

    _titleBarShadowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, CardShadowImageViewVerticalOffset, self.bounds.size.width, self.titleBarHeight)];

    return _titleBarShadowImageView;
}

- (UIImageView *)titleBarShineImageView {
    if (_titleBarShineImageView) return _titleBarShineImageView;

    _titleBarShineImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, CardStackTitleBarShineImageHeight)];

    return _titleBarShineImageView;
}

- (UILabel *)titleLabel {
    if (_titleLabel) return _titleLabel;

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.titleBarView.bounds.size.width, self.titleBarHeight)];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.textColor = self.titleColor;
    _titleLabel.font = self.titleFont;

    return _titleLabel;
}

- (UITapGestureRecognizer *)tapRecognizer {
    if (_tapRecognizer) return _tapRecognizer;

    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];

    return _tapRecognizer;
}

- (UIPanGestureRecognizer *)panRecognizer {
    if (_panRecognizer) return _panRecognizer;

    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];

    return _panRecognizer;
}

#pragma mark - Setters

- (void)setScale:(CGFloat)scale {
    _scale = scale;
    self.layer.transform = CATransform3DMakeScale(self.scale, self.scale, 1.0);
}

- (void)setTitleBarBackgroundColor:(UIColor *)titleBarBackgroundColor {
    self.titleBarView.backgroundColor = titleBarBackgroundColor;
}

- (void)setTitleBarDecorationColor:(UIColor *)titleBarDecorationColor {
    _titleBarDecorationColor = titleBarDecorationColor;
    self.titleBarDecorationView.backgroundColor = titleBarDecorationColor;
    
    if (titleBarDecorationColor) {
        CGFloat alpha;
        [titleBarDecorationColor getRed:nil green:nil blue:nil alpha:&alpha];
        self.titleBarShineImageView.alpha = alpha;
    }
}

- (void)setTitleBarShadowImage:(UIImage *)titleBarShadowImage {
    _titleBarShadowImage = titleBarShadowImage;
    self.titleBarShadowImageView.image = titleBarShadowImage;
}

- (void)setTitleBarShineImage:(UIImage *)titleBarShineImage {
    _titleBarShineImage = titleBarShineImage;
    self.titleBarShineImageView.image = titleBarShineImage;
}

- (void)setTitleColor:(UIColor *)titleColor {
    _titleColor = titleColor;
    self.titleLabel.textColor = titleColor;
}

- (void)setTitleFont:(UIFont *)titleFont {
    _titleFont = titleFont;
    self.titleLabel.font = titleFont;
}

- (void)setTitle:(NSString *)title {
    _title = title;
    self.titleLabel.text = title;
}

- (void)setTitleBarHeight:(CGFloat)titleBarHeight {
    _titleBarHeight = titleBarHeight;

    if (self.titleBarHeightConstraint) {
        self.titleBarHeightConstraint.offset(titleBarHeight);
    }
}

- (void)setTitleLabelVerticalOffset:(CGFloat)titleLabelVerticalOffset {
    _titleLabelVerticalOffset = titleLabelVerticalOffset;

    if (self.titleLabelTopConstraint) {
        self.titleLabelTopConstraint.offset(titleLabelVerticalOffset);
    }
}

- (void)setViewController:(UIViewController *)viewController {
    _viewController = viewController;
    [self.contentView addSubview:viewController.view];
    [self.contentView bringSubviewToFront:self.titleBarView];
}

#pragma mark - Gesture recognizers

- (void)tapAction:(UITapGestureRecognizer *)tapRecognizer {
    if ([self.delegate respondsToSelector:@selector(cardTitleTapped:)]) {
        [self.delegate cardTitleTapped:self];
    }
}

- (void)panAction:(UIPanGestureRecognizer *)panRecognizer {
    static CGPoint originalPoint;

    switch (panRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            originalPoint = [panRecognizer locationInView:self.superview];
            if ([self.delegate respondsToSelector:@selector(cardTitlePanDidStart:)]) {
                [self.delegate cardTitlePanDidStart:self];
            }
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint point = [panRecognizer locationInView:self.superview];
            CGPoint delta = CGPointMake(point.x - originalPoint.x, point.y - originalPoint.y);
            if ([self.delegate respondsToSelector:@selector(card:titlePannedByDelta:)]) {
                [self.delegate card:self titlePannedByDelta:delta];
            }
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
            if ([self.delegate respondsToSelector:@selector(cardTitlePanDidFinish:withVelocity:)]) {
                [self.delegate cardTitlePanDidFinish:self withVelocity:[panRecognizer velocityInView:self.superview]];
            }
            break;
        case UIGestureRecognizerStatePossible:
        case UIGestureRecognizerStateFailed:
            break;
    }
}

#pragma mark - Other methods

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ (%@)", self.title, self.viewController];
}

@end

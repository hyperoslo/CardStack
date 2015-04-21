#import "CardView.h"

static const CGFloat CardTitleBarHeight = 44.0f;

@interface CardView ()

@property (nonatomic) UIViewController *viewController;
@property (nonatomic) UIView *contentView;
@property (nonatomic) UIView *titleBarView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UISwipeGestureRecognizer *swipeRightRecognizer;

@end

@implementation CardView

@synthesize titleColor = _titleColor;
@synthesize titleFont = _titleFont;

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

    [self addSubview:self.contentView];
    [self.contentView addSubview:self.titleBarView];
    [self.titleBarView addSubview:self.titleLabel];

    // using shadows drops frame rate noticeably even on an iPhone 6
    // self.layer.shadowColor = [[UIColor blackColor] CGColor];
    // self.layer.shadowOpacity = 0.5;

    return self;
}

#pragma mark - Getters

- (CGFloat)titleBarHeight {
    return CardTitleBarHeight;
}

- (UIColor *)titleBarBackgroundColor {
    return self.titleBarView.backgroundColor;
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
    _contentView.layer.cornerRadius = 4.0f;
    _contentView.clipsToBounds = YES;

    return _contentView;
}

- (UIView *)titleBarView {
    if (_titleBarView) return _titleBarView;

    _titleBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.titleBarHeight)];
    _titleBarView.backgroundColor = [UIColor orangeColor];
    _titleBarView.userInteractionEnabled = YES;
    [_titleBarView addGestureRecognizer:self.swipeRightRecognizer];
    [_titleBarView addGestureRecognizer:self.panRecognizer];

    return _titleBarView;
}

- (UILabel *)titleLabel {
    if (_titleLabel) return _titleLabel;

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.titleBarView.bounds.size.width, self.titleBarHeight)];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.textColor = self.titleColor;
    _titleLabel.font = self.titleFont;

    return _titleLabel;
}

- (UISwipeGestureRecognizer *)swipeRightRecognizer {
    if (_swipeRightRecognizer) return _swipeRightRecognizer;

    _swipeRightRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRightAction:)];
    _swipeRightRecognizer.direction = UISwipeGestureRecognizerDirectionRight;

    return _swipeRightRecognizer;
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

- (void)setViewController:(UIViewController *)viewController {
    _viewController = viewController;
    [self.contentView addSubview:viewController.view];
    [self.contentView bringSubviewToFront:self.titleBarView];
}

#pragma mark - Gesture recognizers

- (void)swipeRightAction:(UISwipeGestureRecognizer *)swipeRightRecognizer {
    if ([self.delegate respondsToSelector:@selector(cardRemoveRequested:)]) {
        [self.delegate cardRemoveRequested:self];
    }
}

- (void)panAction:(UIPanGestureRecognizer *)panRecognizer {
    static CGPoint originalPoint;

    if (panRecognizer.state == UIGestureRecognizerStateBegan) {
        originalPoint = [panRecognizer locationInView:self.superview];
        if ([self.delegate respondsToSelector:@selector(cardTitlePanDidStart:)]) {
            [self.delegate cardTitlePanDidStart:self];
        }
    } else if (panRecognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint point = [panRecognizer locationInView:self.superview];
        CGPoint delta = CGPointMake(point.x - originalPoint.x, point.y - originalPoint.y);
        if ([self.delegate respondsToSelector:@selector(card:titlePannedByDelta:)]) {
            [self.delegate card:self titlePannedByDelta:delta];
        }
    } else if (panRecognizer.state == UIGestureRecognizerStateCancelled || panRecognizer.state == UIGestureRecognizerStateEnded) {
        if ([self.delegate respondsToSelector:@selector(cardTitlePanDidFinish:withVerticalVelocity:)]) {
            [self.delegate cardTitlePanDidFinish:self withVerticalVelocity:[panRecognizer velocityInView:self.superview].y];
        }
    }
}

#pragma mark - Other methods

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ (%@)", self.title, self.viewController];
}

@end

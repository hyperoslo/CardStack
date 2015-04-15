#import "Card.h"

@interface Card ()

@property (nonatomic) UIImageView *titleBarImageView;
@property (nonatomic) CGFloat titleBarHeight;
@property (nonatomic) UITapGestureRecognizer *tapRecognizer;

@end

@implementation Card

+ (NSArray *)cardsWithViewControllers:(NSArray *)viewControllers
                       titleBarHeight:(CGFloat)titleBarHeight
                        titleBarImage:(UIImage *)titleBarImage
          titleBarImageVerticalOffset:(CGFloat)titleBarImageVerticalOffset
                           titleColor:(UIColor *)titleColor
                            titleFont:(UIFont *)titleFont
{
    NSMutableArray *cards = [NSMutableArray array];

    for (UIViewController *viewController in viewControllers) {
        Card *card = [Card new];

        card.viewController = viewController;

        card.titleBarHeight = titleBarHeight;

        card.titleBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, viewController.view.bounds.size.width, titleBarHeight)];
        card.titleBarView.backgroundColor = [UIColor orangeColor];
        card.titleBarView.userInteractionEnabled = YES;
        card.titleBarView.layer.cornerRadius = 4.0f;
        card.titleBarView.layer.shadowColor = [[UIColor blackColor] CGColor];
        card.titleBarView.layer.shadowOpacity = 0.5;
        [card.titleBarView addGestureRecognizer:card.tapRecognizer];
        [card.viewController.view addSubview:card.titleBarView];

        card.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, card.titleBarView.bounds.size.width, titleBarHeight)];
        card.titleLabel.textAlignment = NSTextAlignmentCenter;
        card.titleLabel.textColor = titleColor;
        card.titleLabel.font = titleFont;
        card.titleLabel.text = card.viewController.title;
        [card.titleBarView addSubview:card.titleLabel];

        [cards addObject:card];
    }

    return [NSArray arrayWithArray:cards];
}

#pragma mark - Getters

- (UITapGestureRecognizer *)tapRecognizer
{
    if (_tapRecognizer) return _tapRecognizer;

    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];

    return _tapRecognizer;
}

#pragma mark - Gesture recognizers

- (void)tapAction:(UITapGestureRecognizer *)tapRecognizer
{
    [self.delegate cardTitleTapped:self];
}

#pragma mark - Other methods

- (CGFloat)scaledTitleBarHeight
{
    return self.scale * (self.titleBarHeight);
}

@end

#import "Card.h"

@interface Card ()

@property (nonatomic) UIImageView *titleBarImageView;
@property (nonatomic) CGFloat titleBarHeight;
@property (nonatomic) UITapGestureRecognizer *tapRecognizer;

@end

@implementation Card

+ (NSArray *)cardsWithViewControllers:(NSArray *)viewControllers
                        titleBarImage:(UIImage *)titleBarImage
          titleBarImageVerticalOffset:(CGFloat)titleBarImageVerticalOffset
                           titleColor:(UIColor *)titleColor
                            titleFont:(UIFont *)titleFont
{
    NSMutableArray *cards = [NSMutableArray array];

    for (UIViewController *viewController in viewControllers) {
        Card *card = [Card new];

        card.viewController = viewController;

        card.titleBarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, titleBarImageVerticalOffset, viewController.view.bounds.size.width, titleBarImage.size.height)];
        card.titleBarImageView.image = [titleBarImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, 100, 0, 100)];
        card.titleBarImageView.userInteractionEnabled = YES;
        [card.titleBarImageView addGestureRecognizer:card.tapRecognizer];
        [card.viewController.view addSubview:card.titleBarImageView];

        card.titleBarHeight = titleBarImage.size.height + titleBarImageVerticalOffset;

        card.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -titleBarImageVerticalOffset, card.titleBarImageView.bounds.size.width, card.titleBarHeight)];
        card.titleLabel.textAlignment = NSTextAlignmentCenter;
        card.titleLabel.textColor = titleColor;
        card.titleLabel.font = titleFont;
        card.titleLabel.text = card.viewController.title;
        [card.titleBarImageView addSubview:card.titleLabel];

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

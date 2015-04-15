#import "CardStackController.h"
#import "Card.h"

@interface CardStackController () <CardDelegate>

@property (nonatomic) NSArray *cards;
@property (nonatomic) BOOL isAnimating;
@property (nonatomic) BOOL isOpen;

@end

@implementation CardStackController

#pragma mark - Setters

- (void)setViewControllers:(NSArray *)viewControllers
{
#warning TODO: remove old title bar image views
#warning TODO: remove old title labels
#warning TODO: remove old cards

    for (Card *card in self.cards) {
        [card.viewController.view removeFromSuperview];
    }

    self.cards = [Card cardsWithViewControllers:viewControllers
                                  titleBarImage:self.titleBarImage
                    titleBarImageVerticalOffset:self.titleBarImageVerticalOffset
                                     titleColor:self.titleColor
                                      titleFont:self.titleFont];

    NSUInteger index = 0;
    for (Card *card in self.cards) {
        card.delegate = self;

        [self.view addSubview:card.viewController.view];

        card.scale = 1.0 - (viewControllers.count - (index + 1)) * 0.04;
        card.viewController.view.layer.transform = CATransform3DMakeScale(card.scale, card.scale, 1.0);

        // avoid initial incorrect position caused by scaling
        CGRect frame = card.viewController.view.frame;
        frame.origin.y = 0;
        card.viewController.view.frame = frame;

        ++index;
    }
}

#pragma mark - Getters

- (UIColor *)titleColor
{
    if (_titleColor) return _titleColor;

    _titleColor = [UIColor whiteColor];

    return _titleColor;
}

- (UIFont *)titleFont
{
    if (_titleFont) return _titleFont;

    _titleFont = [UIFont boldSystemFontOfSize:18.0f];

    return _titleFont;
}

#pragma mark - CardDelegate

- (void)cardTitleTapped:(Card *)card
{
    if (self.isOpen) {
        [self closeStackAnimated:YES withCompletion:^{
            [self.delegate cardStackControllerDidClose:self];
        }];
    } else {
        [self openStackAnimated:YES withCompletion:^{
            [self.delegate cardStackControllerDidOpen:self];
        }];
    }
}

#pragma mark - Other methods

- (void)openStackAnimated:(BOOL)animated
           withCompletion:(void(^)())completion
{
    if (self.isAnimating) {
        return;
    }

    self.isAnimating = YES;
    [UIView animateWithDuration:0.5 animations:^{
        CGFloat previousTitleBarHeights = 0.0f;
        for (NSUInteger i = 0; i < self.cards.count; i++) {
            Card *card = [self.cards objectAtIndex:i];
            UIViewController *viewController = card.viewController;

            CGRect frame = viewController.view.frame;
            frame.origin.y = previousTitleBarHeights + 10;
            viewController.view.frame = frame;

            previousTitleBarHeights += [card scaledTitleBarHeight];
        }
    } completion:^(BOOL finished) {
        self.isAnimating = NO;
        self.isOpen = YES;
        if (completion) {
            completion();
        }
    }];
}

- (void)closeStackAnimated:(BOOL)animated
            withCompletion:(void(^)())completion
{
    if (self.isAnimating) {
        return;
    }

    self.isAnimating = YES;
    [UIView animateWithDuration:0.5 animations:^{
        for (NSUInteger i = 0; i < self.cards.count; i++) {
            UIViewController *viewController = ((Card *)[self.cards objectAtIndex:i]).viewController;
            CGRect frame = viewController.view.frame;
            frame.origin.y = 0;
            viewController.view.frame = frame;
        }
    } completion:^(BOOL finished) {
        self.isAnimating = NO;
        self.isOpen = NO;
        if (completion) {
            completion();
        }
    }];
}

- (void)updateTitles
{
    for (Card *card in self.cards) {
        card.titleLabel.text = card.viewController.title;
    }
}

@end

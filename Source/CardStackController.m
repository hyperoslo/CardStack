#import "CardStackController.h"
#import "CardView.h"

static const CGFloat CardStackTitleBarBackgroundColorOffset = 1.0f / 16.0f;
static const CGFloat CardStackTopMargin = 10.0f;
static const CGFloat CardStackDepthOffset = 0.04f;
static const CGFloat CardStackTitleBarHeightWhenSearchIsShown = 8.0f;

@interface CardStackController () <CardViewDelegate>

@property (nonatomic) BOOL isAnimating;
@property (nonatomic) BOOL isOpen;

@end

@implementation CardStackController

@synthesize titleBarBackgroundColor = _titleBarBackgroundColor;
@synthesize titleFont = _titleFont;

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    self.isSeachViewControllerHidden = YES;

    return self;
}

#pragma mark - Setters

- (void)setViewControllers:(NSArray *)viewControllers {
    _viewControllers = [viewControllers copy];

    [self.cards makeObjectsPerformSelector:@selector(removeFromSuperview)];

    self.cards = [CardView cardsWithViewControllers:viewControllers];
    for (CardView *card in self.cards) {
        card.delegate = self;
        card.titleFont = self.titleFont;
        [self.view addSubview:card];
    }

    // make sure cards' title bar background colors have the depth effect
    [self updateCardTitleBarBackgroundColors];

    self.currentCardIndex = self.cards.count - 1;
}

- (void)setCurrentCardIndex:(NSUInteger)currentCardIndex {
    _currentCardIndex = currentCardIndex;

    [self updateCardScales];
    [self updateCardLocations];
}

- (void)setTitleBarBackgroundColor:(UIColor *)titleBarBackgroundColor {
    _titleBarBackgroundColor = titleBarBackgroundColor;
    [self updateCardTitleBarBackgroundColors];
}

- (void)setCurrentCardIndex:(NSUInteger)currentCardIndex
                   animated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.5 animations:^{
            self.currentCardIndex = currentCardIndex;
        } completion:nil];
    } else {
        self.currentCardIndex = currentCardIndex;
    }
}

- (void)setTitleFont:(UIFont *)titleFont {
    _titleFont = titleFont;
    for (CardView *card in self.cards) {
        card.titleFont = titleFont;
    }
}

- (void)setSearchViewController:(UIViewController *)searchViewController {
    [_searchViewController.view removeFromSuperview];

    _searchViewController = searchViewController;
    [self.view addSubview:searchViewController.view];

    CGRect frame = searchViewController.view.frame;
    frame.origin.y = -searchViewController.view.frame.size.height;
    searchViewController.view.frame = frame;
}

- (void)setIsSeachViewControllerHidden:(BOOL)isSeachViewControllerHidden {
    [self setIsSeachViewControllerHidden:isSeachViewControllerHidden
                                animated:NO
                          withCompletion:nil];
}

- (void)setIsSeachViewControllerHidden:(BOOL)isSeachViewControllerHidden
                              animated:(BOOL)animated
                        withCompletion:(void(^)())completion {
    if (!isSeachViewControllerHidden && !self.searchViewController) {
        return;
    }

    _isSeachViewControllerHidden = isSeachViewControllerHidden;
    if (animated) {
        [UIView animateWithDuration:0.5 animations:^{
            [self updateCardLocations];
        } completion:^(BOOL finished) {
            if (completion) {
                completion();
            }
        }];
    } else {
        [self updateCardLocations];
        if (completion) {
            completion();
        }
    }
}

- (void)setIsOpen:(BOOL)isOpen {
    _isOpen = isOpen;
    if (isOpen && !self.isSeachViewControllerHidden) {
        _isSeachViewControllerHidden = YES;
    }
}

#pragma mark - Getters

- (UIColor *)titleBarBackgroundColor {
    if (_titleBarBackgroundColor) return _titleBarBackgroundColor;

    _titleBarBackgroundColor = [UIColor orangeColor];

    return _titleBarBackgroundColor;
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

#pragma mark - CardDelegate

- (void)cardTitleTapped:(CardView *)card {
    NSUInteger index = 0;
    for (CardView *c in self.cards) {
        if ([c isEqual:card]) {
            break;
        }
        ++index;
    }

    if (index == self.currentCardIndex) {
        if (index > 0) {
            if (self.isOpen) {
                [self closeStackAnimated:YES withCompletion:nil];
            } else {
                [self openStackAnimated:YES withCompletion:nil];
            }
        }
    } else {
        if (index < self.cards.count - 1) {
            self.isOpen = NO;
        } else {
            self.isOpen = YES;
        }
        [self setCurrentCardIndex:index animated:YES];
    }
}

- (void)cardRemoveRequested:(CardView *)card {
    if (self.cards.count < 2) {
        return;
    }

    NSUInteger index = 0;
    for (CardView *c in self.cards) {
        if ([c isEqual:card]) {
            break;
        }
        ++index;
    }

    [self removeCardAtIndex:index
                   animated:YES
             withCompletion:nil];
}

- (void)cardTitleSwipeUp:(CardView *)card {
    if (!self.isSeachViewControllerHidden) {
        if (self.isOpen) {
            _isOpen = NO;
        }
        [self setIsSeachViewControllerHidden:YES
                                    animated:YES
                              withCompletion:nil];
    } else {
        if (self.isOpen) {
            [self closeStackAnimated:YES
                      withCompletion:nil];
        }
    }
}

- (void)cardTitleSwipeDown:(CardView *)card {
    if (!self.isOpen) {
        [self openStackAnimated:YES
                 withCompletion:nil];
    } else {
        if (self.isSeachViewControllerHidden) {
            [self setIsSeachViewControllerHidden:NO
                                        animated:YES
                                  withCompletion:nil];
        }
    }
}

#pragma mark - Other methods

- (void)openStackAnimated:(BOOL)animated
           withCompletion:(void(^)())completion {
    if (self.isAnimating) {
        return;
    }

    self.isOpen = YES;
    if ([self.delegate respondsToSelector:@selector(cardStackControllerWillOpen:)]) {
        [self.delegate cardStackControllerWillOpen:self];
    }

    if (animated) {
        self.isAnimating = YES;
        [UIView animateWithDuration:0.5 animations:^{
            [self updateCardLocations];
        } completion:^(BOOL finished) {
            self.isAnimating = NO;
            if ([self.delegate respondsToSelector:@selector(cardStackControllerDidOpen:)]) {
                [self.delegate cardStackControllerDidOpen:self];
            }
            if (completion) {
                completion();
            }
        }];
    } else {
        [self updateCardLocations];
        if ([self.delegate respondsToSelector:@selector(cardStackControllerDidOpen:)]) {
            [self.delegate cardStackControllerDidOpen:self];
        }
        if (completion) {
            completion();
        }
    }
}

- (void)closeStackAnimated:(BOOL)animated
            withCompletion:(void(^)())completion {
    if (self.isAnimating) {
        return;
    }

    self.isOpen = NO;
    if ([self.delegate respondsToSelector:@selector(cardStackControllerWillClose:)]) {
        [self.delegate cardStackControllerWillClose:self];
    }

    if (animated) {
        self.isAnimating = YES;
        [UIView animateWithDuration:0.5 animations:^{
            [self updateCardLocations];
        } completion:^(BOOL finished) {
            self.isAnimating = NO;
            if ([self.delegate respondsToSelector:@selector(cardStackControllerDidClose:)]) {
                [self.delegate cardStackControllerDidClose:self];
            }
            if (completion) {
                completion();
            }
        }];
    } else {
        [self updateCardLocations];
        if ([self.delegate respondsToSelector:@selector(cardStackControllerDidClose:)]) {
            [self.delegate cardStackControllerDidClose:self];
        }
        if (completion) {
            completion();
        }
    }
}

- (void)insertCardWithViewController:(UIViewController *)viewController
                           withTitle:(NSString *)title
                 aboveViewController:(UIViewController *)aboveViewController
                         makeCurrent:(BOOL)makeCurrent
                            animated:(BOOL)animated
                      withCompletion:(void(^)())completion {
    NSUInteger index = 0;
    for (UIViewController *v in self.viewControllers) {
        if ([v isEqual:aboveViewController]) {
            break;
        }
        ++index;
    }
    if (index == self.viewControllers.count) {
        return;
    }

    NSMutableArray *mutableViewControllers = [self.viewControllers mutableCopy];
    [mutableViewControllers insertObject:viewController atIndex:index];

    // don't user setter to avoid full rebuild
    _viewControllers = [mutableViewControllers copy];

    CardView *aboveCard = [self.cards objectAtIndex:index];
    CardView *card = [CardView cardWithViewController:viewController];
    card.delegate = self;
    card.title = title;
    card.titleFont = self.titleFont;
    card.titleBarBackgroundColor = self.titleBarBackgroundColor;
    NSMutableArray *mutableCards = [self.cards mutableCopy];
    [mutableCards insertObject:card atIndex:index];
    self.cards = [mutableCards copy];
    [self.view insertSubview:card belowSubview:aboveCard];

    // this will make the new card appear from beneath the old card (if the stack is open)
    card.frame = aboveCard.frame;

    if (animated) {
        [UIView animateWithDuration:0.5 animations:^{
            [self updateCardScales];
            [self updateCardLocations];
            [self updateCardTitleBarBackgroundColors];
            if (!makeCurrent) {
                self.currentCardIndex = index + 1;
            }
        } completion:^(BOOL finished) {
            if (completion) {
                completion();
            }
        }];
    } else {
        [self updateCardScales];
        [self updateCardLocations];
        [self updateCardTitleBarBackgroundColors];
        if (!makeCurrent) {
            self.currentCardIndex = index + 1;
        }
        if (completion) {
            completion();
        }
    }
}

- (void)insertCardWithViewController:(UIViewController *)viewController
                           withTitle:(NSString *)title
                 belowViewController:(UIViewController *)belowViewController
                         makeCurrent:(BOOL)makeCurrent
                            animated:(BOOL)animated
                      withCompletion:(void(^)())completion {
    NSUInteger index = 0;
    for (UIViewController *v in self.viewControllers) {
        if ([v isEqual:belowViewController]) {
            break;
        }
        ++index;
    }
    if (index == self.viewControllers.count) {
        return;
    }

    NSMutableArray *mutableViewControllers = [self.viewControllers mutableCopy];
    [mutableViewControllers insertObject:viewController atIndex:index + 1];

    // don't user setter to avoid full rebuild
    _viewControllers = [mutableViewControllers copy];

    CardView *belowCard = [self.cards objectAtIndex:index];
    CardView *card = [CardView cardWithViewController:viewController];
    card.delegate = self;
    card.title = title;
    card.titleFont = self.titleFont;
    card.titleBarBackgroundColor = self.titleBarBackgroundColor;
    NSMutableArray *mutableCards = [self.cards mutableCopy];
    [mutableCards insertObject:card atIndex:index + 1];
    self.cards = [mutableCards copy];
    [self.view insertSubview:card aboveSubview:belowCard];
    if (index == self.currentCardIndex && makeCurrent && animated) {
        // make sure the card animation starts outside of the screen
        CGRect frame = card.frame;
        frame.origin.y = self.view.bounds.size.height;
        card.frame = frame;
    }

    if (animated) {
        [UIView animateWithDuration:0.5 animations:^{
            [self updateCardScales];
            [self updateCardLocations];
            [self updateCardTitleBarBackgroundColors];
            if (makeCurrent) {
                self.currentCardIndex = index + 1;
            }
        } completion:^(BOOL finished) {
            if (completion) {
                completion();
            }
        }];
    } else {
        [self updateCardScales];
        [self updateCardLocations];
        [self updateCardTitleBarBackgroundColors];
        if (makeCurrent) {
            self.currentCardIndex = index + 1;
        }
        if (completion) {
            completion();
        }
    }
}

- (void)removeCardAtIndex:(NSUInteger)index
                 animated:(BOOL)animated
           withCompletion:(void(^)())completion {
    if (self.cards.count < 2 || index > self.cards.count - 1) {
        return;
    }

    // avoid unwanted animation if the topmost card is removed
    if (!self.isOpen) {
        animated = NO;
    }

    NSMutableArray *mutableViewControllers = [self.viewControllers mutableCopy];
    [mutableViewControllers removeObjectAtIndex:index];

    // don't user setter to avoid full rebuild
    _viewControllers = [mutableViewControllers copy];

    __block CardView *card = [self.cards objectAtIndex:index];

    NSMutableArray *mutableCards = [self.cards mutableCopy];
    [mutableCards removeObjectAtIndex:index];
    self.cards = [mutableCards copy];

    if (animated) {
        [UIView animateWithDuration:0.5 animations:^{
            if (self.cards.count == 1 && self.isOpen) {
                self.isOpen = NO;
            }
            [self updateCardScales];
            [self updateCardLocations];
            [self updateCardTitleBarBackgroundColors];
            if (self.currentCardIndex > 0 && self.currentCardIndex > self.cards.count - 1) {
                self.currentCardIndex = self.cards.count - 1;
            }

            CGRect frame = card.frame;
            frame.origin.x = frame.origin.x + self.view.bounds.size.width;
            card.frame = frame;
        } completion:^(BOOL finished) {
            // removal is diferred, so a proper removal animation could be executed
            [card removeFromSuperview];

            if (completion) {
                completion();
            }
        }];
    } else {
        if (self.cards.count == 1 && self.isOpen) {
            self.isOpen = NO;
        }
        [self updateCardScales];
        [self updateCardLocations];
        [self updateCardTitleBarBackgroundColors];
        if (self.currentCardIndex > 0 && self.currentCardIndex > self.cards.count - 1) {
            self.currentCardIndex = self.cards.count - 1;
        }
        [card removeFromSuperview];
        if (completion) {
            completion();
        }
    }
}

- (void)updateCardScales {
    NSUInteger index = 0;
    for (CardView *card in self.cards) {
        CGFloat scale = 1.0f;
        if (index < self.currentCardIndex) {
            NSInteger relativeIndex = index - self.currentCardIndex;
            scale = 1.0 + relativeIndex * CardStackDepthOffset;
        }
        card.scale = scale;
        ++index;
    }
}

- (void)updateCardTitleBarBackgroundColors {
    UIColor *titleBarBackgroundColor = self.titleBarBackgroundColor;
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    [titleBarBackgroundColor getRed:&red green:&green blue:&blue alpha:nil];

    for (NSUInteger i = 0; i < self.cards.count; i++) {
        NSInteger offset = (i - self.cards.count + 1);
        CGFloat colorOffset = offset * CardStackTitleBarBackgroundColorOffset;
        UIColor *modifiedColor = [UIColor colorWithRed:red + colorOffset green:green + colorOffset blue:blue + colorOffset alpha:1.0];
        CardView *card = [self.cards objectAtIndex:i];
        card.titleBarBackgroundColor = modifiedColor;
    }
}

- (void)updateCardLocations {
    if (self.isSeachViewControllerHidden) {
        CGRect frame = self.searchViewController.view.frame;
        frame.origin.y = -self.searchViewController.view.bounds.size.height;
        self.searchViewController.view.frame = frame;

        if (self.isOpen) {
            CGFloat previousTitleBarHeights = 0.0f;
            for (NSUInteger i = 0; i < self.cards.count; i++) {
                CardView *card = [self.cards objectAtIndex:i];

                CGRect frame = card.frame;
                if (i <= self.currentCardIndex) {
                    frame.origin.y = previousTitleBarHeights + CardStackTopMargin;
                } else {
                    frame.origin.y = self.view.bounds.size.height - card.titleBarHeight;
                }
                card.frame = frame;

                // -1.0f is used to avoid area below the title bar to become slightly visible is some cases (due to rounding errors)
                previousTitleBarHeights += (card.titleBarHeight * card.scale - 1.0f);
            }
        } else {
            for (NSUInteger i = 0; i < self.cards.count; i++) {
                CardView *card = [self.cards objectAtIndex:i];

                CGRect frame = card.frame;
                if (i <= self.currentCardIndex) {
                    frame.origin.y = 0;
                } else {
                    frame.origin.y = self.view.bounds.size.height - card.titleBarHeight;
                }
                card.frame = frame;
            }
        }
    } else {
        CGRect frame = self.searchViewController.view.frame;
        frame.origin.y = 0.0f;
        self.searchViewController.view.frame = frame;

        CGFloat previousTitleBarHeights = 0.0f;
        for (NSUInteger i = 0; i < self.cards.count; i++) {
            CardView *card = [self.cards objectAtIndex:i];

            CGRect frame = card.frame;
            if (i <= self.currentCardIndex) {
                frame.origin.y = self.searchViewController.view.bounds.size.height + previousTitleBarHeights + CardStackTopMargin;
            } else {
                frame.origin.y = self.searchViewController.view.bounds.size.height + self.view.bounds.size.height - card.titleBarHeight;
            }
            card.frame = frame;

            previousTitleBarHeights += CardStackTitleBarHeightWhenSearchIsShown;
        }
    }
}

@end

#import "CardStackController.h"
#import "CardView.h"
#import "POP.h"

static const CGFloat CardStackTopMargin = 10.0f;
static const CGFloat CardStackDepthOffset = 0.04f;
static const CGFloat CardStackOpenIfLargeThanPercent = 0.8f;
static const CGFloat CardStackVerticalVelocityLimitWhenMakingCardCurrent = 100.0f;
static const CGFloat CardStackOffsetToAvoidAreaBelowTheTitleToBecomeVisible = 1.0f;
static const CGFloat CardStackMaximumVisibleTitleBarProportion = 1.3f;
static const CGFloat CardStackMinimumSearchViewControllerHeightPropotion = 0.5f;
static const CGFloat CardStackTitleBarHeightProportionWhenSearchViewControllerIsVisible = 0.2f;
static const CGFloat CardStackTitleBarHeight = 44.0f;
static const CGFloat CardStackDefaultSpringBounciness = 8.0f;

@interface CardStackController () <CardViewDelegate>

@property (nonatomic) BOOL isAnimating;
@property (nonatomic) BOOL isOpen;
@property (nonatomic) CGRect originalCardFrame;
@property (nonatomic) CGFloat maximumTotalTitleBarHeightBeforeSearchAppears;
@property (nonatomic) POPSpringAnimation *searchControllerOpeningAnimation;

@end

@implementation CardStackController

@synthesize titleBarBackgroundColor = _titleBarBackgroundColor;
@synthesize titleFont = _titleFont;

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _isSeachViewControllerHidden = YES;
    _titleBarHeight = CardStackTitleBarHeight;

    return self;
}

#pragma mark - Setters

- (void)setCards:(NSArray *)cards {
    _cards = cards;

    for (NSUInteger i = 0; i < cards.count; i++) {
        CardView *card = [cards objectAtIndex:i];
        card.tag = i;
    }
}

- (void)setViewControllers:(NSArray *)viewControllers {
    _viewControllers = [viewControllers copy];

    [self.cards makeObjectsPerformSelector:@selector(removeFromSuperview)];

    self.cards = [CardView cardsWithViewControllers:viewControllers];
    for (CardView *card in self.cards) {
        card.delegate = self;
        card.titleFont = self.titleFont;
        card.titleBarHeight = self.titleBarHeight;
        [self.view addSubview:card];
    }

    self.currentCardIndex = self.cards.count - 1;

    // make sure cards' title bar background colors have the depth effect
    [self updateCardTitleBarBackgroundColors];
}

- (void)setCurrentCardIndex:(NSUInteger)currentCardIndex {
    [self setCurrentCardIndex:currentCardIndex animated:NO];
}

- (void)setCurrentCardIndex:(NSUInteger)currentCardIndex animated:(BOOL)animated {
    _currentCardIndex = currentCardIndex;

    [self updateCardScales];
    [self updateCardLocationsAnimated:animated];
}

- (void)setTitleBarBackgroundColor:(UIColor *)titleBarBackgroundColor {
    _titleBarBackgroundColor = titleBarBackgroundColor;
    [self updateCardTitleBarBackgroundColors];
}

- (void)setTitleFont:(UIFont *)titleFont {
    _titleFont = titleFont;
    for (CardView *card in self.cards) {
        card.titleFont = titleFont;
    }
}

- (void)setTitleBarHeight:(CGFloat)titleBarHeight {
    _titleBarHeight = titleBarHeight;
    for (CardView *card in self.cards) {
        card.titleBarHeight = titleBarHeight;
    }
}

- (void)setTitleLabelVerticalOffset:(CGFloat)titleLabelVerticalOffset {
    _titleLabelVerticalOffset = titleLabelVerticalOffset;
    for (CardView *card in self.cards) {
        card.titleLabelVerticalOffset = titleLabelVerticalOffset;
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
    if (isSeachViewControllerHidden) {
        self.isOpen = NO;
    }

    POPSpringAnimation *springAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
    CGRect frame = self.searchViewController.view.frame;
    frame.origin.y = isSeachViewControllerHidden ? -self.searchViewController.view.frame.size.height : 0;
    springAnimation.toValue = [NSValue valueWithCGRect:frame];
    springAnimation.springBounciness = CardStackDefaultSpringBounciness;
    springAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
        if (completion) {
            completion();
        }
    };
    [self.searchViewController.view pop_addAnimation:springAnimation forKey:@"frame"];

    [self updateCardLocationsAnimated:animated];
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
    if (card.tag != self.currentCardIndex) {
        self.isOpen = NO;
        if (card.tag == self.cards.count - 1) {
            [self undockCardsWithVerticalVelocity:0];
        } else {
            [self setCurrentCardIndex:card.tag
                             animated:YES];
        }
    }
}

- (void)cardTitlePanDidStart:(CardView *)card {
    self.originalCardFrame = card.frame;
}

- (void)card:(CardView *)card titlePannedByDelta:(CGPoint)delta {
    self.maximumTotalTitleBarHeightBeforeSearchAppears = 0;
    for (NSUInteger index = 0; index < self.currentCardIndex; index++) {
        CardView *card = [self.cards objectAtIndex:index];
        self.maximumTotalTitleBarHeightBeforeSearchAppears += (card.titleBarHeight * card.scale - CardStackOffsetToAvoidAreaBelowTheTitleToBecomeVisible) * CardStackMaximumVisibleTitleBarProportion;
    }

    if ((card.tag != self.currentCardIndex &&
        card.tag != self.cards.count - 1) ||
        self.cards.count == 1) {
        return;
    }

    CGFloat y = self.originalCardFrame.origin.y + delta.y;
    if (y >= 0.0f) {
        CGRect frame = self.originalCardFrame;
        frame.origin.y = y;
        card.frame = frame;
        [self updateCardLocationsWhileOpening];

        BOOL shouldConsiderOpeningSearchController = (self.searchViewController &&
                                                      self.isSeachViewControllerHidden &&
                                                      card.tag == self.currentCardIndex);
        if (shouldConsiderOpeningSearchController) {
            CGFloat topOfPreviousCard = CardStackTopMargin;
            if (self.currentCardIndex > 0) {
                CardView *previousCard = [self.cards objectAtIndex:self.currentCardIndex - 1];
                topOfPreviousCard = previousCard.frame.origin.y;
            }

            BOOL shouldRevealSearchController = (y > self.maximumTotalTitleBarHeightBeforeSearchAppears);
            if (shouldRevealSearchController) {
                CGRect frame = self.searchViewController.view.frame;
                frame.origin.y = ((y - self.maximumTotalTitleBarHeightBeforeSearchAppears) - frame.size.height);
                if (frame.origin.y <= 0) {
                    self.searchViewController.view.frame = frame;
                }
            }
        }
    }
}

- (void)cardTitlePanDidFinish:(CardView *)card withVelocity:(CGPoint)velocity {
    if ((card.tag != self.currentCardIndex &&
         card.tag != self.cards.count - 1) ||
        self.cards.count == 1) {
        return;
    }

    if (card.tag == self.currentCardIndex) {
        if (velocity.y < 0.0f) {
            self.isOpen = NO;

            BOOL shouldCloseSearchController = (self.searchViewController &&
                                                !self.isSeachViewControllerHidden &&
                                                card.tag == self.currentCardIndex);
            if (shouldCloseSearchController) {
                _isSeachViewControllerHidden = YES;
                POPSpringAnimation *springAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
                CGRect frame = self.searchViewController.view.frame;
                frame.origin.y = -self.searchViewController.view.frame.size.height;
                springAnimation.toValue = [NSValue valueWithCGRect:frame];
                springAnimation.springBounciness = CardStackDefaultSpringBounciness;
                [self.searchViewController.view pop_addAnimation:springAnimation forKey:@"frame"];
            }
        } else {
            CGFloat heightAboveCurrentCardWhenOpen = CardStackTopMargin;
            if (self.currentCardIndex > 0) {
                for (NSUInteger i = 0; i < self.currentCardIndex - 1; i++) {
                    CardView *card = [self.cards objectAtIndex:i];
                    heightAboveCurrentCardWhenOpen += card.titleBarHeight * card.scale;
                }
            }
            self.isOpen = (card.frame.origin.y > heightAboveCurrentCardWhenOpen * CardStackOpenIfLargeThanPercent);

            if (self.searchViewController) {
                CGFloat heightOfVisiblePortionOfSearchViewController = (self.searchViewController.view.frame.origin.y + self.searchViewController.view.frame.size.height);
                _isSeachViewControllerHidden = (heightOfVisiblePortionOfSearchViewController < self.searchViewController.view.frame.size.height * CardStackMinimumSearchViewControllerHeightPropotion);
            }
        }
        [self updateCardLocationsAnimatedWithVerticalVelocity:velocity.y];
        [self updateSearchViewControllerLocationAnimatedWithVerticalVelocity:velocity.y];
    } else if (card.tag == self.cards.count - 1) {
        if (velocity.y < 0.0f &&
            fabs(velocity.y) > CardStackVerticalVelocityLimitWhenMakingCardCurrent) {
            [self undockCardsWithVerticalVelocity:velocity.y];
        } else {
            [self updateCardLocationsAnimated:YES];
        }
    }
}

#pragma mark - Other methods

- (CardView *)cardViewForViewController:(UIViewController *)viewController {
    CardView *card;

    for (NSUInteger index = 0; index < self.viewControllers.count; index++) {
        if ([[self.viewControllers objectAtIndex:index] isEqual:viewController]) {
            card = [self.cards objectAtIndex:index];
            break;
        }
    }

    return card;
}

- (NSUInteger)indexForViewController:(UIViewController *)viewController {
    __block NSInteger foundIndex = NSNotFound;
    [self.viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        *stop = [obj isEqual:viewController];
        if (*stop) {
            foundIndex = idx;
        }
    }];

    return foundIndex;
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
    card.titleBarHeight = self.titleBarHeight;
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
    card.titleBarHeight = self.titleBarHeight;
    NSMutableArray *mutableCards = [self.cards mutableCopy];
    [mutableCards insertObject:card atIndex:index + 1];
    self.cards = [mutableCards copy];
    [self.view insertSubview:card aboveSubview:belowCard];
    BOOL cardAnimationShouldStartOutsideOfTheScreen = (index == self.currentCardIndex && makeCurrent && animated);
    if (cardAnimationShouldStartOutsideOfTheScreen) {
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

    BOOL shouldAvoidUnwantedAnimationIfTopmostCardIsRemoved = (!self.isOpen);
    if (shouldAvoidUnwantedAnimationIfTopmostCardIsRemoved) {
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
            // removal from superview is diferred to make sure a proper removal animation is visible
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
    for (NSUInteger i = 0; i < self.cards.count; i++) {
        CardView *card = [self.cards objectAtIndex:i];
        card.titleBarBackgroundColor = self.titleBarBackgroundColor;
        if ([self.dataSource respondsToSelector:@selector(cardStackController:titleBarDecorationColorForCardAtIndex:)]) {
            card.titleBarDecorationColor = [self.dataSource cardStackController:self titleBarDecorationColorForCardAtIndex:i];
        }
        if ([self.dataSource respondsToSelector:@selector(cardStackController:titleBarShadowImageForCardAtIndex:)]) {
            card.titleBarShadowImage = [self.dataSource cardStackController:self titleBarShadowImageForCardAtIndex:i];
        }
        if ([self.dataSource respondsToSelector:@selector(cardStackController:titleBarShineImageForCardAtIndex:)]) {
            card.titleBarShineImage = [self.dataSource cardStackController:self titleBarShineImageForCardAtIndex:i];
        }
    }
}

- (void)updateCardLocations {
    [self updateCardLocationsAnimated:NO];
}

- (void)updateCardLocationsAnimated:(BOOL)animated {
    if (animated) {
        [self updateCardLocationsAnimatedWithVerticalVelocity:0.0f];
    } else {
        for (NSUInteger i = 0; i < self.cards.count; i++) {
            CardView *card = [self.cards objectAtIndex:i];
            card.frame = [self frameForCardAtIndex:i];
        }
    }
}

- (void)updateCardLocationsAnimatedWithVerticalVelocity:(CGFloat)verticalVelocity {
    for (NSUInteger i = 0; i < self.cards.count; i++) {
        CardView *card = [self.cards objectAtIndex:i];
        POPSpringAnimation *springAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
        CGRect frame = [self frameForCardAtIndex:i];
        springAnimation.toValue = [NSValue valueWithCGRect:frame];
        springAnimation.springBounciness = CardStackDefaultSpringBounciness;
        BOOL shouldScaleDownVelocityForUpperCardsAvoidingSpringEffectForCardsNearToTheTop = (verticalVelocity > 0.0f && i <= self.currentCardIndex);
        if (shouldScaleDownVelocityForUpperCardsAvoidingSpringEffectForCardsNearToTheTop) {
            CGFloat springVelocity = (verticalVelocity * card.scale) * ((CGFloat)i / (CGFloat)(self.currentCardIndex + 1));
            if (self.searchViewController && !self.isSeachViewControllerHidden) {
                springVelocity *= CardStackTitleBarHeightProportionWhenSearchViewControllerIsVisible;
            }
            springAnimation.velocity = [NSValue valueWithCGRect:CGRectMake(0, springVelocity, 0, 0)];
        }
        [card pop_addAnimation:springAnimation forKey:@"frame"];
    }
}

- (void)updateCardLocationsWhileOpening {
    if (self.currentCardIndex > 0) {
        CGFloat startY = CardStackTopMargin;
        if (self.searchViewController) {
            startY += self.searchViewController.view.frame.origin.y + self.searchViewController.view.frame.size.height;
        }
        CardView *currentCard = [self.cards objectAtIndex:self.currentCardIndex];
        CGFloat endY = currentCard.frame.origin.y;
        CGFloat currentY = startY;
        CGFloat incrementY = (endY - startY) / self.currentCardIndex;
        for (NSUInteger i = 0; i < self.currentCardIndex; i++) {
            currentCard = [self.cards objectAtIndex:i];
            CGRect frame = currentCard.frame;
            frame.origin.y = currentY;
            currentCard.frame = frame;
            currentY = currentY + incrementY;
        }
    }
}

- (void)updateSearchViewControllerLocationAnimatedWithVerticalVelocity:(CGFloat)verticalVelocity {
    if (self.searchViewController) {
        POPSpringAnimation *springAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
        CGRect frame = self.searchViewController.view.frame;
        frame.origin.y = (self.isSeachViewControllerHidden ? -self.searchViewController.view.frame.size.height : 0);
        springAnimation.toValue = [NSValue valueWithCGRect:frame];
        springAnimation.springBounciness = CardStackDefaultSpringBounciness;
        [self.searchViewController.view pop_addAnimation:springAnimation forKey:@"frame"];
    }
}

- (CGRect)frameForCardAtIndex:(NSUInteger)index {
    CGRect frame;

    // Note: Cards at the bottom but behind the last card will be positioned
    // outside of the visible area, so their title bar won't show up when the
    // last card is being moved.
    BOOL shouldCardRemainInvisibleEvenIfLastCardIsMoved = (index > self.currentCardIndex && index < self.cards.count - 1);
    if (index <= self.currentCardIndex) {
        if (self.isOpen) {
            CGFloat previousTitleBarHeights = CardStackTopMargin;
            if (self.searchViewController && !self.isSeachViewControllerHidden) {
                previousTitleBarHeights += self.searchViewController.view.frame.size.height;
            }
            for (NSUInteger i = 0; i < index; i++) {
                CardView *card = [self.cards objectAtIndex:i];
                CGFloat titleBarHeight = (card.titleBarHeight * card.scale - CardStackOffsetToAvoidAreaBelowTheTitleToBecomeVisible);
                if (self.searchViewController && !self.isSeachViewControllerHidden) {
                    titleBarHeight *= CardStackTitleBarHeightProportionWhenSearchViewControllerIsVisible;
                }
                previousTitleBarHeights += titleBarHeight;
            }

            CardView *card = [self.cards objectAtIndex:index];
            frame = card.frame;
            frame.origin.y = previousTitleBarHeights;
        } else {
            CardView *card = [self.cards objectAtIndex:index];
            frame = card.frame;
            frame.origin.y = 0;
            if (self.searchViewController && !self.isSeachViewControllerHidden) {
                frame.origin.y += self.searchViewController.view.frame.size.height;
            }
        }
    } else if (shouldCardRemainInvisibleEvenIfLastCardIsMoved) {
        CardView *card = [self.cards objectAtIndex:index];
        frame = card.frame;
        frame.origin.y = self.view.bounds.size.height;
    } else {
        CardView *card = [self.cards objectAtIndex:index];
        frame = card.frame;
        frame.origin.y = self.view.bounds.size.height - card.titleBarHeight;
    }

    return frame;
}

- (void)moveCard:(CardView *)card
         toFrame:(CGRect)frame
springBounciness:(CGFloat)bounciness
        velocity:(CGPoint)velocity
  withCompletion:(void(^)())completion {
    POPSpringAnimation *springAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
    springAnimation.toValue = [NSValue valueWithCGRect:frame];
    springAnimation.springBounciness = bounciness;
    springAnimation.velocity = [NSValue valueWithCGRect:CGRectMake(velocity.x, velocity.y, 0, 0)];
    springAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
        if (completion) {
            completion();
        }
    };
    [card pop_addAnimation:springAnimation forKey:@"frame"];
}

- (void)undockCardsWithVerticalVelocity:(CGFloat)verticalVelocity {
    CardView *card = [self.cards lastObject];
    CGRect frame = [self frameForCardAtIndex:card.tag];
    frame.origin.y = 0;
    [self moveCard:card toFrame:frame springBounciness:8.0f velocity:CGPointMake(0, verticalVelocity) withCompletion:^{
        self.isOpen = NO;
        self.currentCardIndex = self.cards.count - 1;
        [self updateCardScales];
        [self updateCardLocations];
        if ([self.delegate respondsToSelector:@selector(cardStackControllerDidUndockCards:)]) {
            [self.delegate cardStackControllerDidUndockCards:self];
        }
    }];
}

@end

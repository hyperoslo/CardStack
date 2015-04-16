#import "CardStackController.h"
#import "CardView.h"

static const CGFloat CardStackTitleBarBackgroundColorOffset = 1.0f / 16.0f;
static const CGFloat CardStackTopMargin = 10.0f;
static const CGFloat CardStackDepthOffset = 0.04f;

@interface CardStackController () <CardViewDelegate>

@property (nonatomic) BOOL isAnimating;
@property (nonatomic) BOOL isOpen;

@end

@implementation CardStackController

@synthesize titleBarBackgroundColor = _titleBarBackgroundColor;

#pragma mark - Setters

- (void)setViewControllers:(NSArray *)viewControllers
{
    [self.cards makeObjectsPerformSelector:@selector(removeFromSuperview)];

    self.cards = [CardView cardsWithViewControllers:viewControllers];
    for (CardView *card in self.cards) {
        card.delegate = self;
        [self.view addSubview:card];
    }

    // make sure cards' title bar background colors have the depth effect
    [self updateCardTitleBarBackgroundColors];

    self.currentCardIndex = self.cards.count - 1;
}

- (void)setCurrentCardIndex:(NSUInteger)currentCardIndex
{
    _currentCardIndex = currentCardIndex;

    [self updateCardScales];
    [self updateCardLocations];
}

- (void)setTitleBarBackgroundColor:(UIColor *)titleBarBackgroundColor
{
    _titleBarBackgroundColor = titleBarBackgroundColor;
    [self updateCardTitleBarBackgroundColors];
}

- (void)setCurrentCardIndex:(NSUInteger)currentCardIndex
                   animated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.5 animations:^{
            self.currentCardIndex = currentCardIndex;
        } completion:nil];
    } else {
        self.currentCardIndex = currentCardIndex;
    }
}

#pragma mark - Getters

- (UIColor *)titleBarBackgroundColor
{
    if (_titleBarBackgroundColor) return _titleBarBackgroundColor;

    _titleBarBackgroundColor = [UIColor orangeColor];

    return _titleBarBackgroundColor;
}

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

- (void)cardTitleTapped:(CardView *)card
{
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

#pragma mark - Other methods

- (void)openStackAnimated:(BOOL)animated
           withCompletion:(void(^)())completion
{
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
            withCompletion:(void(^)())completion
{
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

- (void)updateCardScales
{
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

- (void)updateCardLocations
{
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

            previousTitleBarHeights += card.titleBarHeight * card.scale;
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
}

@end

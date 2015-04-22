@import Foundation;
@import UIKit;

@protocol CardViewDelegate;

@interface CardView : UIView

@property (weak, nonatomic) id<CardViewDelegate> delegate;

@property (nonatomic) CGFloat scale;
@property (nonatomic) UIColor *titleBarBackgroundColor;
@property (nonatomic) UIColor *titleColor;
@property (nonatomic) UIFont *titleFont;
@property (nonatomic) NSString *title;
@property (nonatomic) UIPanGestureRecognizer *panRecognizer;

@property (nonatomic, readonly) CGFloat titleBarHeight;

+ (CardView *)cardWithViewController:(UIViewController *)viewController;
+ (NSArray *)cardsWithViewControllers:(NSArray *)viewControllers;

@end

@protocol CardViewDelegate <NSObject>

@optional
- (void)cardTitleTapped:(CardView *)card;
- (void)cardTitlePanDidStart:(CardView *)card;
- (void)card:(CardView *)card titlePannedByDelta:(CGPoint)delta;
- (void)cardTitlePanDidFinish:(CardView *)card withVelocity:(CGPoint)velocity;

@end

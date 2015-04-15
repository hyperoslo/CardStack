@import Foundation;

@protocol CardDelegate;

@interface Card : NSObject

@property (weak, nonatomic) id<CardDelegate> delegate;
@property (nonatomic) CGFloat scale;
@property (nonatomic) UIViewController *viewController;
@property (nonatomic) UILabel *titleLabel;

+ (NSArray *)cardsWithViewControllers:(NSArray *)viewControllers
                        titleBarImage:(UIImage *)titleBarImage
          titleBarImageVerticalOffset:(CGFloat)titleBarImageVerticalOffset
                           titleColor:(UIColor *)titleColor
                            titleFont:(UIFont *)titleFont;

- (CGFloat)scaledTitleBarHeight;

@end

@protocol CardDelegate <NSObject>

- (void)cardTitleTapped:(Card *)card;

@end

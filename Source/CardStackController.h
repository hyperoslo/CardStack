@import UIKit;

@protocol CardStackControllerDelegate;

@interface CardStackController : UIViewController

@property (weak, nonatomic) id<CardStackControllerDelegate> delegate;

@property (nonatomic) NSArray *viewControllers;

@property (nonatomic) NSUInteger currentCardIndex;

@property (nonatomic) UIImage *titleBarImage;
@property (nonatomic) CGFloat titleBarImageVerticalOffset;
@property (nonatomic) UIColor *titleColor;
@property (nonatomic) UIFont *titleFont;

- (void)openStackAnimated:(BOOL)animated
           withCompletion:(void(^)())completion;
- (void)closeStackAnimated:(BOOL)animated
            withCompletion:(void(^)())completion;

- (void)updateTitles;

@end

@protocol CardStackControllerDelegate <NSObject>

- (void)cardStackControllerDidOpen:(CardStackController *)cardStackController;
- (void)cardStackControllerDidClose:(CardStackController *)cardStackController;

@end

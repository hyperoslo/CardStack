@import UIKit;
#import "CardView.h"

@protocol CardStackControllerDelegate;

@interface CardStackController : UIViewController

@property (weak, nonatomic) id<CardStackControllerDelegate> delegate;

@property (nonatomic) NSArray *cards;
@property (nonatomic) NSArray *viewControllers;
@property (nonatomic) NSUInteger currentCardIndex;
@property (nonatomic) UIColor *titleBarBackgroundColor;
@property (nonatomic) UIColor *titleColor;
@property (nonatomic) UIFont *titleFont;

- (void)insertCardWithViewController:(UIViewController *)viewController
                           withTitle:(NSString *)title
                 aboveViewController:(UIViewController *)aboveViewController
                         makeCurrent:(BOOL)makeCurrent
                            animated:(BOOL)animated
                      withCompletion:(void(^)())completion;
- (void)insertCardWithViewController:(UIViewController *)viewController
                           withTitle:(NSString *)title
                 belowViewController:(UIViewController *)belowViewController
                         makeCurrent:(BOOL)makeCurrent
                            animated:(BOOL)animated
                      withCompletion:(void(^)())completion;
- (void)removeCardAtIndex:(NSUInteger)index
                 animated:(BOOL)animated
           withCompletion:(void(^)())completion;

@end

@protocol CardStackControllerDelegate <NSObject>

@optional
- (void)cardStackControllerWillOpen:(CardStackController *)cardStackController;
- (void)cardStackControllerWillClose:(CardStackController *)cardStackController;
- (void)cardStackControllerDidOpen:(CardStackController *)cardStackController;
- (void)cardStackControllerDidClose:(CardStackController *)cardStackController;

@end

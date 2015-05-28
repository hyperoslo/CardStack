#import "ResizeableViewController.h"

@implementation ResizeableViewController

- (void)setContentHeight:(CGFloat)contentHeight {
    CGRect frame = self.view.frame;
    frame.size.height = contentHeight;
    self.view.frame = frame;
}

@end

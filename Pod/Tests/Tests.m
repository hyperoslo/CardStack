@import UIKit;
@import XCTest;
#import "CardStackController.h"

@interface PodTests : XCTestCase

@end

@implementation PodTests

- (void)testIndexForViewController {
    CardStackController *cardStackController = [CardStackController new];
    
    UIViewController *viewController1 = [UIViewController new];
    UIViewController *viewController2 = [UIViewController new];
    UIViewController *viewController3 = [UIViewController new];
    cardStackController.viewControllers = @[viewController1, viewController2];
    
    XCTAssertEqual([cardStackController indexForViewController:viewController1], 0);
    XCTAssertEqual([cardStackController indexForViewController:viewController2], 1);
    XCTAssertEqual([cardStackController indexForViewController:viewController3], NSNotFound);
}

@end

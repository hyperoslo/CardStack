#import "AppDelegate.h"
#import "CardStackController.h"

@interface AppDelegate () <CardStackControllerDelegate>

@property (nonatomic) CardStackController *cardStackController;

@property (nonatomic) UIViewController *vc1;
@property (nonatomic) UIViewController *vc2;
@property (nonatomic) UIViewController *vc3;
@property (nonatomic) UIViewController *vc4;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    self.vc1 = [[UIViewController alloc] init];
    self.vc1.title = @"One";
    self.vc1.view.backgroundColor = [UIColor clearColor];

    self.vc2 = [[UIViewController alloc] init];
    self.vc2.title = @"Two";
    self.vc2.view.backgroundColor = [UIColor clearColor];

    self.vc3 = [[UIViewController alloc] init];
    self.vc3.title = @"Three";
    self.vc3.view.backgroundColor = [UIColor clearColor];

    self.vc4 = [[UIViewController alloc] init];
    self.vc4.title = @"Tap to open stack";
    self.vc4.view.backgroundColor = [UIColor clearColor];

    self.cardStackController = [CardStackController new];
    self.cardStackController.delegate = self;
    self.cardStackController.titleBarImage = [UIImage imageNamed:@"titleBar.png"];
    self.cardStackController.titleBarImageVerticalOffset = -8.0f;
    self.cardStackController.viewControllers = @[self.vc1, self.vc2, self.vc3, self.vc4];

    self.window.rootViewController = self.cardStackController;
    self.window.backgroundColor = [UIColor clearColor];

    return YES;
}

#pragma mark - CardStackControllerDelegate

- (void)cardStackControllerDidOpen:(CardStackController *)cardStackController
{
    self.vc4.title = @"Four";
    [cardStackController updateTitles];
}

- (void)cardStackControllerDidClose:(CardStackController *)cardStackController
{
}

@end

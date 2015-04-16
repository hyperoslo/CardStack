#import "AppDelegate.h"
#import "CardStackController.h"

static const NSUInteger ExampleNumberOfInitialCards = 4;

@interface AppDelegate () <CardStackControllerDelegate>

@property (nonatomic) CardStackController *cardStackController;
@property (nonatomic) NSMutableArray *viewControllers;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    self.viewControllers = [NSMutableArray new];
    for (NSUInteger i = 0; i < ExampleNumberOfInitialCards; i++) {
        [self.viewControllers addObject:[self createNewTestViewController]];
    }

    self.cardStackController = [CardStackController new];
    self.cardStackController.delegate = self;
    self.cardStackController.viewControllers = self.viewControllers;
    for (NSUInteger i = 0; i < self.cardStackController.cards.count; i++) {
        CardView *card = [self.cardStackController.cards objectAtIndex:i];
        if (i < self.cardStackController.cards.count - 1) {
            card.title = [NSString stringWithFormat:@"#%ld", (long)i + 1];
        } else {
            card.title = @"Tap to open stack";
        }
    }

    self.window.rootViewController = self.cardStackController;
    self.window.backgroundColor = [UIColor clearColor];

    return YES;
}

#pragma mark - CardStackControllerDelegate

- (void)cardStackControllerWillOpen:(CardStackController *)cardStackController
{
    CardView *card = [self.cardStackController.cards lastObject];
    card.title = [NSString stringWithFormat:@"#%ld", (long)self.cardStackController.cards.count];
}

#pragma mark - Other methods

- (UIViewController *)createNewTestViewController {
    UIViewController *viewController = [[UIViewController alloc] init];

    viewController.view.backgroundColor = [UIColor whiteColor];

    return viewController;
}

@end

#import "AppDelegate.h"
#import "CardStackController.h"
#import "Masonry.h"

static const NSUInteger ExampleNumberOfInitialCards = 4;
static const CGFloat ExampleButtonWidth = 320.0f;
static const CGFloat ExampleButtonHeight = 44.0f;
static const CGFloat ExampleTopMargin = 64.0f;
static const CGFloat ExampleMargin = 10.0f;

@interface AppDelegate () <CardStackControllerDelegate>

@property (nonatomic) CardStackController *cardStackController;
@property (nonatomic) NSMutableArray *viewControllers;
@property (nonatomic) NSUInteger numberOfCardsCreated;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    self.viewControllers = [NSMutableArray new];
    for (NSUInteger i = 0; i < ExampleNumberOfInitialCards; i++) {
        [self.viewControllers addObject:[self createNewTestViewControllerWithTag:i]];
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

- (void)cardStackControllerWillOpen:(CardStackController *)cardStackController {
    CardView *card = [self.cardStackController.cards lastObject];
    if ([card.title isEqualToString:@"Tap to open stack"]) {
        card.title = [NSString stringWithFormat:@"#%ld", (long)self.cardStackController.cards.count];
    }
}

#pragma mark - Other methods

- (UIViewController *)createNewTestViewControllerWithTag:(NSInteger)tag {
    UIViewController *viewController = [[UIViewController alloc] init];

    viewController.view.backgroundColor = [UIColor whiteColor];
    viewController.view.tag = tag;

    UIButton *insertAboveButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, ExampleButtonWidth, ExampleButtonHeight)];
    [insertAboveButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [insertAboveButton setTitle:@"Insert card above" forState:UIControlStateNormal];
    [insertAboveButton addTarget:self action:@selector(insertAboveAction:) forControlEvents:UIControlEventTouchUpInside];
    [viewController.view addSubview:insertAboveButton];
    [insertAboveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(viewController.view.mas_top).with.offset(ExampleTopMargin);
        make.centerX.equalTo(viewController.view.mas_centerX);
    }];

    UIButton *insertBelowButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, ExampleButtonWidth, ExampleButtonHeight)];
    [insertBelowButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [insertBelowButton setTitle:@"Insert card below" forState:UIControlStateNormal];
    [insertBelowButton addTarget:self action:@selector(insertBelowAction:) forControlEvents:UIControlEventTouchUpInside];
    [viewController.view addSubview:insertBelowButton];
    [insertBelowButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(insertAboveButton.mas_bottom).with.offset(ExampleMargin);
        make.centerX.equalTo(viewController.view.mas_centerX);
    }];

    UIButton *removeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, ExampleButtonWidth, ExampleButtonHeight)];
    [removeButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [removeButton setTitle:@"Remove this card" forState:UIControlStateNormal];
    [removeButton addTarget:self action:@selector(removeAction:) forControlEvents:UIControlEventTouchUpInside];
    [viewController.view addSubview:removeButton];
    [removeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(insertBelowButton.mas_bottom).with.offset(ExampleMargin);
        make.centerX.equalTo(viewController.view.mas_centerX);
    }];

    self.numberOfCardsCreated = self.numberOfCardsCreated + 1;

    return viewController;
}

- (void)insertAboveAction:(UIButton *)button {
    NSInteger index = button.superview.tag;
    UIViewController *aboveViewController = [self.viewControllers objectAtIndex:index];
    UIViewController *viewController = [self createNewTestViewControllerWithTag:self.viewControllers.count];
    [self.viewControllers insertObject:viewController atIndex:index];
    NSString *title = [NSString stringWithFormat:@"#%ld", (long)self.numberOfCardsCreated];
    [self.cardStackController insertCardWithViewController:viewController
                                                 withTitle:title
                                       aboveViewController:aboveViewController
                                               makeCurrent:NO
                                                  animated:YES
                                            withCompletion:^{
                                                for (NSUInteger i = 0; i < self.viewControllers.count; i++) {
                                                    UIViewController *viewController = [self.viewControllers objectAtIndex:i];
                                                    viewController.view.tag = i;
                                                }
                                                NSLog(@"self.cardStackController.cards = %@", self.cardStackController.cards);
                                            }];
}

- (void)insertBelowAction:(UIButton *)button {
    NSInteger index = button.superview.tag;
    UIViewController *belowViewController = [self.viewControllers objectAtIndex:index];
    UIViewController *viewController = [self createNewTestViewControllerWithTag:self.viewControllers.count];
    [self.viewControllers insertObject:viewController atIndex:index + 1];
    NSString *title = [NSString stringWithFormat:@"#%ld", (long)self.numberOfCardsCreated];
    [self.cardStackController insertCardWithViewController:viewController
                                                 withTitle:title
                                       belowViewController:belowViewController
                                               makeCurrent:NO
                                                  animated:YES
                                            withCompletion:^{
                                                for (NSUInteger i = 0; i < self.viewControllers.count; i++) {
                                                    UIViewController *viewController = [self.viewControllers objectAtIndex:i];
                                                    viewController.view.tag = i;
                                                }
                                                NSLog(@"self.cardStackController.cards = %@", self.cardStackController.cards);
                                            }];
}

- (void)removeAction:(UIButton *)button {
    NSInteger index = button.superview.tag;
    [self.viewControllers removeObjectAtIndex:index];
    [self.cardStackController removeCardAtIndex:index
                                       animated:YES
                                 withCompletion:^{
                                     for (NSUInteger i = 0; i < self.viewControllers.count; i++) {
                                         UIViewController *viewController = [self.viewControllers objectAtIndex:i];
                                         viewController.view.tag = i;
                                     }
                                     NSLog(@"self.cardStackController.cards = %@", self.cardStackController.cards);
                                 }];
}

@end

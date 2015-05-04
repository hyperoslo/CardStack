#import "AppDelegate.h"
#import "CardStackController.h"
#import "Masonry.h"

static const NSUInteger ExampleNumberOfInitialCards = 4;
static const CGFloat ExampleButtonWidth = 320.0f;
static const CGFloat ExampleButtonHeight = 44.0f;
static const CGFloat ExampleTopMargin = 64.0f;
static const CGFloat ExampleMargin = 10.0f;
static const CGFloat ExampleSearchViewControllerHeight = 100.0f;

@interface AppDelegate () <CardStackControllerDelegate, CardStackControllerDataSource>

@property (nonatomic) CardStackController *cardStackController;
@property (nonatomic) NSMutableArray *viewControllers;
@property (nonatomic) NSUInteger numberOfCardsCreated;

@property (nonatomic) UIViewController *searchViewController;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    self.viewControllers = [NSMutableArray new];
    for (NSUInteger i = 0; i < ExampleNumberOfInitialCards; i++) {
        [self.viewControllers addObject:[self createNewTestViewControllerWithTag:i]];
    }

    self.cardStackController = [CardStackController new];
    self.cardStackController.delegate = self;
    self.cardStackController.dataSource = self;
    self.cardStackController.titleBarBackgroundColor = [UIColor orangeColor];
    self.cardStackController.viewControllers = self.viewControllers;
    for (NSUInteger i = 0; i < self.cardStackController.cards.count; i++) {
        CardView *card = [self.cardStackController.cards objectAtIndex:i];
        card.title = [NSString stringWithFormat:@"#%ld", (long)i + 1];
    }

    self.searchViewController = [[UIViewController alloc] init];
    self.searchViewController.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, ExampleSearchViewControllerHeight);
    self.searchViewController.view.backgroundColor = [UIColor redColor];

    UILabel *searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, ExampleButtonHeight)];
    searchLabel.text = @"Search view controller here";
    searchLabel.textColor = [UIColor whiteColor];
    searchLabel.font = [UIFont systemFontOfSize:16.0f];
    searchLabel.textAlignment = NSTextAlignmentCenter;
    [self.searchViewController.view addSubview:searchLabel];
    [searchLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.searchViewController.view);
    }];

    self.cardStackController.searchViewController = self.searchViewController;

    self.window.rootViewController = self.cardStackController;
    self.window.backgroundColor = [UIColor clearColor];
    [self.window makeKeyAndVisible];

    return YES;
}

#pragma mark - CardStackControllerDataSource

- (UIColor *)cardStackController:(CardStackController *)cardStackController titleBarDecorationColorForCardAtIndex:(NSUInteger)index {
    return [UIColor colorWithRed:1 green:0 blue:0 alpha:(CGFloat)index / (CGFloat)cardStackController.cards.count];
}

- (UIImage *)cardStackController:(CardStackController *)cardStackController titleBarShadowImageForCardAtIndex:(NSUInteger)index {
    return [UIImage imageNamed:@"card_shadow.png"];
}

- (UIImage *)cardStackController:(CardStackController *)cardStackController titleBarShineImageForCardAtIndex:(NSUInteger)index {
    return [UIImage imageNamed:@"card_shine.png"];
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
    [removeButton setTitle:@"Remove card" forState:UIControlStateNormal];
    [removeButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [removeButton addTarget:self action:@selector(removeAction:) forControlEvents:UIControlEventTouchUpInside];
    [viewController.view addSubview:removeButton];
    [removeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(insertBelowButton.mas_bottom).with.offset(ExampleMargin);
        make.centerX.equalTo(viewController.view.mas_centerX);
    }];

    UILabel *openLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, ExampleButtonWidth, ExampleButtonHeight)];
    openLabel.text = @"Pull down on title bar to open stack";
    openLabel.textAlignment = NSTextAlignmentCenter;
    openLabel.font = [UIFont systemFontOfSize:13.0f];
    openLabel.textColor = [UIColor darkGrayColor];
    [viewController.view addSubview:openLabel];
    [openLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(removeButton.mas_bottom).with.offset(3 * ExampleMargin);
        make.centerX.equalTo(viewController.view.mas_centerX);
    }];

    UILabel *tapLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, ExampleButtonWidth, ExampleButtonHeight)];
    tapLabel.text = @"Tap on title bar to select";
    tapLabel.textAlignment = NSTextAlignmentCenter;
    tapLabel.font = [UIFont systemFontOfSize:13.0f];
    tapLabel.textColor = [UIColor darkGrayColor];
    [viewController.view addSubview:tapLabel];
    [tapLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(openLabel.mas_bottom).with.offset(2 * ExampleMargin);
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
                                               makeCurrent:YES
                                                  animated:YES
                                            withCompletion:^{
                                                for (NSUInteger i = 0; i < self.viewControllers.count; i++) {
                                                    UIViewController *viewController = [self.viewControllers objectAtIndex:i];
                                                    viewController.view.tag = i;
                                                }
                                            }];
}

- (void)removeAction:(UIButton *)button {
    NSInteger index = button.superview.tag;
    [self.cardStackController removeCardAtIndex:index
                                       animated:YES
                                 withCompletion:^{
                                     for (NSUInteger i = 0; i < self.viewControllers.count; i++) {
                                         UIViewController *viewController = [self.viewControllers objectAtIndex:i];
                                         viewController.view.tag = i;
                                     }
                                 }];
}

@end

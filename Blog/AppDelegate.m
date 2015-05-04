//
//  AppDelegate.m
//  Blog
//
//  Created by Sami Samhuri on 2014-10-18.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

#import <dyci/SFDynamicCodeInjection.h>
#import "AppDelegate.h"
#import "PostsViewController.h"
#import "EditorViewController.h"
#import "BlogService.h"
#import "YapDatabase.h"
#import "ModelStore.h"
#import "JSONHTTPClient.h"
#import "BlogController.h"
#import "Functions.h"

@interface AppDelegate () <UISplitViewControllerDelegate>

@property (nonatomic, readonly, strong) BlogController *blogController;
@property (nonatomic, readonly, strong) PostsViewController *postsViewController;
@property (nonatomic, readonly, strong) EditorViewController *editorViewController;

@end

@implementation AppDelegate

@synthesize blogController = _blogController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setupCodeInjection];
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = splitViewController.viewControllers.lastObject;
    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    splitViewController.delegate = self;
    self.postsViewController.blogController = self.blogController;
    self.editorViewController.blogController = self.blogController;
    return YES;
}

- (void)setupCodeInjection {
    __block BOOL codeInjectionEnabled = NO;
    [[[NSProcessInfo processInfo] arguments] enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        if ([obj isEqual:@"EnableCodeInjection"]) {
            codeInjectionEnabled = YES;
        }
    }];
    if (!codeInjectionEnabled) {
        [NSClassFromString(@"SFDynamicCodeInjection") performSelector:@selector(disable)];
    }
}

- (BlogController *)blogController {
    if (!_blogController) {
        NSString *cachesPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
        NSString *dbPath = [cachesPath stringByAppendingPathComponent:@"blog.sqlite"];
        ModelStore *store = [self newModelStoreWithPath:dbPath];
        _blogController = [self newBlogControllerWithModelStore:store rootURL:@"http://ocean.samhuri.net:6706/"];
    }
    return _blogController;
}

- (PostsViewController *)postsViewController {
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = splitViewController.viewControllers.firstObject;
    PostsViewController *postsViewController = (PostsViewController *)navigationController.viewControllers.firstObject;
    return postsViewController;
}

- (EditorViewController *)editorViewController {
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = splitViewController.viewControllers.firstObject;
    navigationController = navigationController.viewControllers.lastObject;
    EditorViewController *editorViewController = (EditorViewController *)navigationController.viewControllers.firstObject;
    return editorViewController;
}

- (ModelStore *)newModelStoreWithPath:(NSString *)dbPath {
    YapDatabase *database = [[YapDatabase alloc] initWithPath:dbPath];
    YapDatabaseConnection *connection = [database newConnection];
    ModelStore *store = [[ModelStore alloc] initWithConnection:connection];
    return store;
}

- (BlogController *)newBlogControllerWithModelStore:(ModelStore *)store rootURL:(NSString *)rootURL {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    JSONHTTPClient *client = [[JSONHTTPClient alloc] initWithSession:session];
    client.defaultHeaders = [self defaultBlogHeaders];
    BlogService *service = [[BlogService alloc] initWithRootURL:rootURL client:client];
    BlogController *blogController = [[BlogController alloc] initWithService:service store:store];
    return blogController;
}

- (NSDictionary *)defaultBlogHeaders {
    NSString *authPath = [[NSBundle mainBundle] pathForResource:@"auth.json" ofType:nil];
    if (authPath.length) {
        NSData *data = [NSData dataWithContentsOfFile:authPath];
        NSError *error = nil;
        NSDictionary *auth = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (auth) {
            return @{@"Auth" : [NSString stringWithFormat:@"%@|%@", auth[@"username"], auth[@"password"]]};
        }
        NSLog(@"auth.json: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        NSLog(@"[ERROR] Failed to parse auth.json: %@ %@", error.localizedDescription, error.userInfo);
    }
    NSLog(@"[WARNING] No auth.json found. Blog will be read-only.");
    return nil;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
    // TODO: version
    NSLog(@"should restore state with coder %@", coder);
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder {
    // TODO: version
    NSLog(@"should save application state with coder %@", coder);
    return YES;
}

- (void)application:(UIApplication *)application willEncodeRestorableStateWithCoder:(NSCoder *)coder {
    NSLog(@"will encode restorable state with coder %@", coder);
}

- (void)application:(UIApplication *)application didDecodeRestorableStateWithCoder:(NSCoder *)coder {
    NSLog(@"did decode restorable state with coder %@", coder);
}


#pragma mark - UISplitViewDelegate methods

- (BOOL) splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    UINavigationController *navigationController = [secondaryViewController isKindOfClass:[UINavigationController class]]
                                                   ? (UINavigationController *)secondaryViewController
                                                   : nil;
    EditorViewController *editorViewController = navigationController.topViewController ? safeCast(navigationController.topViewController, [EditorViewController class]) : nil;
    if (!editorViewController.post) {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    }
    else {
        return NO;
    }
}

@end

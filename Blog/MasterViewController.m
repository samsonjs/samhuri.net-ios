//
//  MasterViewController.m
//  Blog
//
//  Created by Sami Samhuri on 2014-10-18.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "Post.h"
#import "BlogController.h"
#import "ModelStore.h"
#import "BlogService.h"
#import "YapDatabaseConnection.h"
#import "YapDatabase.h"
#import "JSONHTTPClient.h"

@interface MasterViewController ()

@property (strong, nonatomic) NSMutableArray *posts;
@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *publishButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (strong, nonatomic) BlogController *blogController;

@end

@implementation MasterViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    NSString *cachesPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
    NSString *path = [cachesPath stringByAppendingPathComponent:@"blog.sqlite"];
    YapDatabase *database = [[YapDatabase alloc] initWithPath:path];
    YapDatabaseConnection *connection = [database newConnection];
    ModelStore *store = [[ModelStore alloc] initWithConnection:connection];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    JSONHTTPClient *client = [[JSONHTTPClient alloc] initWithSession:session];
    BlogService *service = [[BlogService alloc] initWithRootURL:@"http://ocean.samhuri.net:6706/" client:client];
    self.blogController = [[BlogController alloc] initWithService:service store:store];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UINavigationController *detailNavController = self.splitViewController.viewControllers.lastObject;
    self.detailViewController = (DetailViewController *)detailNavController.topViewController;
}

- (void)viewWillAppear:(BOOL)animated;
{
    [super viewWillAppear:animated];
    if (!self.posts) {
        [self requestDrafts];
    }
}

- (void)requestDrafts {
    // TODO: show a spinner
    [self.blogController requestDrafts].then(^(NSArray *drafts) {
        return [self.blogController requestPublishedPosts].then(^(NSArray *posts) {
            NSLog(@"drafts = %@", drafts);
            NSLog(@"posts = %@", posts);
            self.posts = [drafts mutableCopy];
            [self.posts addObjectsFromArray:posts];
            [self.tableView reloadData];
        });
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)insertNewObject:(id)sender {
    Post *post = [[Post alloc] initWithDictionary:@{@"draft": @(YES)} error:nil];
    [self.posts insertObject:post atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (IBAction)publish:(id)sender {
    NSLog(@"publish");
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Post *post = self.posts[indexPath.row];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        [controller setPost:post];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.posts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    Post *post = self.posts[indexPath.row];
    // FIXME: unique title
    cell.textLabel.text = post.title ?: @"Untitled";
    cell.detailTextLabel.text = post.draft ? @"Draft" : post.formattedDate;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.posts removeObjectAtIndex:indexPath.row];
        // TODO: delete from server
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

@end

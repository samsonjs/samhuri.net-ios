//
//  PostsViewController.m
//  Blog
//
//  Created by Sami Samhuri on 2014-10-18.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

#import <PromiseKit/Promise.h>
#import "PostsViewController.h"
#import "EditorViewController.h"
#import "Post.h"
#import "BlogController.h"
#import "PostCell.h"
#import "BlogStatus.h"
#import "NSDate+marshmallows.h"

@interface PostsViewController ()

@property (strong, nonatomic) NSMutableArray *posts;
@property (strong, nonatomic) EditorViewController *editorViewController;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *publishButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (weak, nonatomic) UILabel *titleLabel;
@property (weak, nonatomic) UILabel *statusLabel;
@property (copy, nonatomic) NSString *blogStatusText;
@property (strong, nonatomic) NSDate *blogStatusDate;
@property (strong, nonatomic) NSTimer *blogStatusTimer;

@end

@implementation PostsViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }

    [self setupTitleView];
}

- (void)setupTitleView;
{
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 44)];
    titleView.userInteractionEnabled = YES;
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(requestStatusWithoutCaching)];
    recognizer.numberOfTapsRequired = 2;
    [titleView addGestureRecognizer:recognizer];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.text = self.navigationItem.title;
    [titleLabel sizeToFit];
    titleLabel.center = CGPointMake(150, 3 + (CGRectGetHeight(titleLabel.bounds) / 2));
    [titleView addSubview:titleLabel];
    self.titleLabel = titleLabel;
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    subtitleLabel.font = [UIFont systemFontOfSize:11];
    subtitleLabel.textColor = [UIColor whiteColor];
    [titleView addSubview:subtitleLabel];
    self.statusLabel = subtitleLabel;
    self.navigationItem.titleView = titleView;
}

- (void)setupBlogStatusTimer
{
    self.blogStatusTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(updateBlogStatus) userInfo:nil repeats:YES];
}

- (void)teardownBlogStatusTimer
{
    [self.blogStatusTimer invalidate];
    self.blogStatusTimer = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UINavigationController *detailNavController = self.splitViewController.viewControllers.lastObject;
    self.editorViewController = (EditorViewController *)detailNavController.topViewController;
}

- (void)updateStatusLabel:(NSString *)blogStatus;
{
    if (self.statusLabel && ![self.statusLabel.text isEqualToString:blogStatus]) {
        self.statusLabel.text = blogStatus;
        [self.statusLabel sizeToFit];
        self.statusLabel.center = CGPointMake(150, CGRectGetMaxY(self.titleLabel.frame) + 3 + (CGRectGetHeight(self.statusLabel.bounds) / 2));
    }
}

- (void)updateBlogStatus;
{
    [self updateStatusLabel:[NSString stringWithFormat:@"%@ as of %@", self.blogStatusText, [self.blogStatusDate mm_relativeToNow]]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupBlogStatusTimer];
    [self requestStatusWithCaching:YES];
    if (!self.posts) {
        [self requestPostsWithCaching:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated;
{
    [super viewWillDisappear:animated];
    [self teardownBlogStatusTimer];
}

- (IBAction)refresh:(id)sender {
    [self requestStatusWithCaching:NO];
    [self requestPostsWithCaching:NO].finally(^{
        [self.refreshControl endRefreshing];
    });
}

- (PMKPromise *)requestStatusWithoutCaching {
    return [self requestStatusWithCaching:NO];
}

- (PMKPromise *)requestStatusWithCaching:(BOOL)useCache {
    [self teardownBlogStatusTimer];
    [self updateStatusLabel:@"Checking status"];
    return [self.blogController requestBlogStatusWithCaching:useCache].then(^(BlogStatus *status) {
        self.blogStatusDate = status.date;
        if (status.dirty) {
            self.blogStatusText = @"Dirty";
        }
        else {
            self.blogStatusText = @"Everything published";
        }
        [self setupBlogStatusTimer];
        [self updateBlogStatus];
        return status;
    }).catch(^(NSError *error) {
        [self updateStatusLabel:@"Failed to check status"];
        return error;
    });
}

- (PMKPromise *)requestPostsWithCaching:(BOOL)useCache;
{
    return [self.blogController requestAllPostsWithCaching:useCache].then(^(NSArray *posts) {
        self.posts = [posts mutableCopy];
        [self.tableView reloadData];
        return posts;
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
    if ([segue.identifier isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Post *post = self.posts[indexPath.row];
        EditorViewController *controller = (EditorViewController *)[[segue destinationViewController] topViewController];
        controller.blogController = self.blogController;
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
    PostCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    Post *post = self.posts[indexPath.row];
    // FIXME: unique title
    NSString *title = post.title ?: @"Untitled";
    NSString *date = post.draft ? @"Draft" : post.formattedDate;
    [cell configureWithTitle:title date:date];
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

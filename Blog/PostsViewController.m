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
#import "UIColor+Hex.h"
#import "PostCollection.h"

@interface PostsViewController ()

@property (strong, nonatomic) NSArray *postCollections;
@property (strong, readonly, nonatomic) NSMutableArray *drafts;
@property (strong, readonly, nonatomic) NSMutableArray *posts;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *publishButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (weak, nonatomic) UILabel *titleLabel;
@property (weak, nonatomic) UILabel *statusLabel;
@property (copy, nonatomic) NSString *blogStatusText;
@property (strong, nonatomic) NSDate *blogStatusDate;
@property (strong, nonatomic) NSTimer *blogStatusTimer;

@end

static const NSUInteger SectionDrafts = 0;
static const NSUInteger SectionPublished = 1;

@implementation PostsViewController

@dynamic drafts, posts;

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }

    [self setupTitleView];
    self.refreshControl.tintColor = [UIColor whiteColor];
}

- (void)setupTitleView {
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
    [titleView addSubview:titleLabel];
    self.titleLabel = titleLabel;
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    subtitleLabel.font = [UIFont systemFontOfSize:11];
    subtitleLabel.textColor = [UIColor whiteColor];
    [titleView addSubview:subtitleLabel];
    self.statusLabel = subtitleLabel;
    self.navigationItem.titleView = titleView;
    [self.view setNeedsLayout];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [UIView animateWithDuration:0.3 animations:^{
        CGFloat width = CGRectGetWidth(self.titleLabel.superview.bounds);
        self.titleLabel.center = CGPointMake(width / 2, 3 + (CGRectGetHeight(self.titleLabel.bounds) / 2));
        self.statusLabel.center = CGPointMake(width / 2, CGRectGetMaxY(self.titleLabel.frame) + 3 + (CGRectGetHeight(self.statusLabel.bounds) / 2));
    }];
}

- (void)setupBlogStatusTimer {
    self.blogStatusTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(updateBlogStatus) userInfo:nil repeats:YES];
}

- (void)teardownBlogStatusTimer {
    [self.blogStatusTimer invalidate];
    self.blogStatusTimer = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UINavigationController *detailNavController = self.splitViewController.viewControllers.lastObject;
}

- (void)updateStatusLabel:(NSString *)blogStatus {
    if (self.statusLabel && ![self.statusLabel.text isEqualToString:blogStatus]) {
        self.statusLabel.text = blogStatus;
        [UIView animateWithDuration:0.3 animations:^{
            [self.statusLabel sizeToFit];
        }];
        [self.view setNeedsLayout];
    }
}

- (void)updateBlogStatus {
    [self updateStatusLabel:[NSString stringWithFormat:@"%@ as of %@", self.blogStatusText, [self.blogStatusDate mm_relativeToNow]]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupBlogStatusTimer];
    [self requestStatusWithCaching:YES];
    if (!self.postCollections) {
        [self requestPostsWithCaching:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
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

- (PMKPromise *)requestPostsWithCaching:(BOOL)useCache {
    return [self.blogController requestAllPostsWithCaching:useCache].then(^(NSArray *results) {
        self.postCollections = @[
                [PostCollection postCollectionWithTitle:@"Drafts" posts:results.firstObject],
                [PostCollection postCollectionWithTitle:@"Published" posts:results.lastObject],
        ];
        [self.tableView reloadData];
        return results;
    });
}

- (PostCollection *)postCollectionForSection:(NSInteger)section {
    return self.postCollections[section];
}

- (Post *)postForIndexPath:(NSIndexPath *)indexPath {
    return [self postCollectionForSection:indexPath.section].posts[indexPath.row];
}

- (NSMutableArray *)drafts {
    return [self postCollectionForSection:SectionDrafts].posts;
}

- (NSMutableArray *)posts {
    return [self postCollectionForSection:SectionPublished].posts;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)insertNewObject:(id)sender {
    NSString *title = [UIPasteboard generalPasteboard].string;
    NSURL *url = [UIPasteboard generalPasteboard].URL;
    // TODO: image, anything else interesting
    Post *post = [Post newDraftWithTitle:title body:nil url:url];
    [self.drafts insertObject:post atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:SectionDrafts];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    [self performSegueWithIdentifier:@"showDetail" sender:sender];
}

- (IBAction)publish:(id)sender {
    NSLog(@"publish");
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Post *post = [self postForIndexPath:indexPath];
        EditorViewController *controller = (EditorViewController *)[[segue destinationViewController] topViewController];
        controller.blogController = self.blogController;
        controller.post = post;
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        controller.postUpdatedBlock = ^(Post *post) {
            BOOL (^isThisPost)(Post *, NSUInteger, BOOL *) = ^BOOL(Post *p, NSUInteger idx, BOOL *stop) {
                        return [p.objectID isEqualToString:post.objectID];
                    };
            NSUInteger section = SectionDrafts;
            NSUInteger row = [self.drafts indexOfObjectPassingTest:isThisPost];
            if (row == NSNotFound) {
                section = SectionPublished;
                row = [self.posts indexOfObjectPassingTest:isThisPost];
            }
            if (row != NSNotFound) {
                PostCollection *collection = [self postCollectionForSection:section];
                [collection.posts replaceObjectAtIndex:row withObject:post];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        };
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.postCollections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self postCollectionForSection:section].posts.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self postCollectionForSection:section].title;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [super tableView:tableView viewForHeaderInSection:section];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *headerView = [view isKindOfClass:[UITableViewHeaderFooterView class]] ? (UITableViewHeaderFooterView *)view : nil;
    headerView.textLabel.textColor = [UIColor mm_colorFromInteger:0xF7F7F7];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PostCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    Post *post = [self postForIndexPath:indexPath];
    NSString *title = post.title.length ? post.title : @"Untitled";
    NSString *date = post.draft ? @"" : post.formattedDate;
    [cell configureWithTitle:title date:date];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        PostCollection *collection = [self postCollectionForSection:indexPath.section];
        [collection.posts removeObjectAtIndex:indexPath.row];
        // TODO: delete from server
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

@end

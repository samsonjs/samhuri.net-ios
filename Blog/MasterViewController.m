//
//  MasterViewController.m
//  Blog
//
//  Created by Sami Samhuri on 2014-10-18.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

#import <PromiseKit/Promise.h>
#import "MasterViewController.h"
#import "DetailViewController.h"
#import "Post.h"
#import "BlogController.h"
#import "PostCell.h"

@interface MasterViewController ()

@property (strong, nonatomic) NSMutableArray *posts;
@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *publishButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addButton;

@end

@implementation MasterViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
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
            self.posts = [drafts mutableCopy];
            for (Post *post in [posts reverseObjectEnumerator]) {
                [self.posts addObject:post];
            }
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
    if ([segue.identifier isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Post *post = self.posts[indexPath.row];
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
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

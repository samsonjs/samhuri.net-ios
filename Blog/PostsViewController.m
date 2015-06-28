//
//  PostsViewController.m
//  Blog
//
//  Created by Sami Samhuri on 2014-10-18.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

#import <PromiseKit/Promise.h>
#import <ObjectiveSugar/NSArray+ObjectiveSugar.h>
#import <FontAwesome+iOS/NSString+FontAwesome.h>
#import "PostsViewController.h"
#import "EditorViewController.h"
#import "Post.h"
#import "BlogController.h"
#import "PostCell.h"
#import "BlogStatus.h"
#import "NSDate+marshmallows.h"
#import "UIColor+Hex.h"
#import "PostCollection.h"
#import "ModelStore.h"
#import "UIImage+FontAwesome.h"
#import "NSString+marshmallows.h"
#import "MBProgressHUD.h"
#import "CommonUI.h"

@interface PostsViewController () <UISearchBarDelegate>

@property (nonatomic, strong) NSArray *filteredPostCollections;
@property (nonatomic, strong) NSArray *postCollections;
@property (nonatomic, readonly, strong) NSMutableArray *drafts;
@property (nonatomic, readonly, strong) NSMutableArray *publishedPosts;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *publishButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *addButton;
@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) UILabel *statusLabel;
@property (nonatomic, copy) NSString *blogStatusText;
@property (nonatomic, strong) NSDate *blogStatusDate;
@property (nonatomic, strong) NSTimer *blogStatusTimer;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, weak) NSLayoutConstraint *titleViewWidthConstraint;
@property (nonatomic, weak) NSLayoutConstraint *titleViewHeightConstraint;
@property (nonatomic, weak) NSLayoutConstraint *titleLabelTopConstraint;
@property(nonatomic, assign) BOOL hasAppeared;

@end

static const NSUInteger SectionDrafts = 0;
static const NSUInteger SectionPublished = 1;

@interface TitleView : UIView @end
@implementation TitleView
- (void)addConstraint:(NSLayoutConstraint *)constraint {
    if (![@"NSAutoresizingMaskLayoutConstraint" isEqualToString:NSStringFromClass([constraint class])]) {
        [super addConstraint:constraint];
    }
}
@end

@implementation PostsViewController

@dynamic drafts, publishedPosts;

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupTitleView];
    [self setupFontAwesomeIcons];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self setupBlogNotifications];
}

- (void)dealloc {
    [self teardownBlogNotifications];
}

- (void)setupTitleView {
    TitleView *titleView = [[TitleView alloc] initWithFrame:CGRectZero];
    titleView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:titleView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0];
    [titleView addConstraint:widthConstraint];
    self.titleViewWidthConstraint = widthConstraint;
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:titleView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0];
    [titleView addConstraint:heightConstraint];
    self.titleViewHeightConstraint = heightConstraint;
    titleView.translatesAutoresizingMaskIntoConstraints = NO;
    titleView.clipsToBounds = YES;
    titleView.userInteractionEnabled = YES;
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(requestStatusWithoutCaching)];
    recognizer.numberOfTapsRequired = 2;
    [titleView addGestureRecognizer:recognizer];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.font = [UIFont fontWithName:@"MuseoSans-300" size:16];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.text = self.navigationItem.title;
    [titleLabel sizeToFit];
    [titleView addSubview:titleLabel];
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:titleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:titleView attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    [titleView addConstraint:topConstraint];
    self.titleLabelTopConstraint = topConstraint;
    [titleView addConstraint:[NSLayoutConstraint constraintWithItem:titleLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:titleView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    self.titleLabel = titleLabel;
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    subtitleLabel.font = [UIFont systemFontOfSize:11];
    subtitleLabel.textColor = [UIColor whiteColor];
    [subtitleLabel sizeToFit];
    [titleView addSubview:subtitleLabel];
    [titleView addConstraint:[NSLayoutConstraint constraintWithItem:subtitleLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:titleView attribute:NSLayoutAttributeBottom multiplier:1 constant:-9]];
    [titleView addConstraint:[NSLayoutConstraint constraintWithItem:subtitleLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:titleView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    self.statusLabel = subtitleLabel;
    self.navigationItem.titleView = titleView;
}

- (void)updateTitleViewConstraints;
{
    self.titleViewWidthConstraint.constant = CGRectGetWidth(self.view.bounds);
    CGFloat height = CGRectGetHeight(self.navigationController.navigationBar.bounds);
    CGFloat top = 5;
    // This is more reliable than checking if it's portrait.
    if (!UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation))
    {
        // status bar
        height += 20;
        top += 15;
    }
    self.titleViewHeightConstraint.constant = height;
    self.titleLabelTopConstraint.constant = top;
    [self.titleLabel.superview setNeedsUpdateConstraints];
}

- (void)updateOnClassInjection {
    [self.titleLabel.constraints each:^(NSLayoutConstraint *constraint) {
        [constraint.secondItem removeConstraint:constraint];
    }];
    [self.statusLabel.constraints each:^(NSLayoutConstraint *constraint) {
        [constraint.secondItem removeConstraint:constraint];
    }];
    [self setupTitleView];
}

- (void)setupFontAwesomeIcons {
    UIImage *image = [UIImage imageWithIcon:@"fa-rss" backgroundColor:[UIColor clearColor] iconColor:[UIColor mm_colorFromInteger:0xAA0000] fontSize:20];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(publish:) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    self.publishButton.customView = button;
}

- (void)setupBlogStatusTimer {
    // Just make sure everything is cleaned up in case we get called twice.
    [self teardownBlogStatusTimer];
    self.blogStatusTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateBlogStatus) userInfo:nil repeats:YES];
}

- (void)teardownBlogStatusTimer {
    [self.blogStatusTimer invalidate];
    self.blogStatusTimer = nil;
}

- (void)updateStatusLabel:(NSString *)blogStatus animated:(BOOL)animated {
    if (self.statusLabel && ![self.statusLabel.text isEqualToString:blogStatus]) {
        self.statusLabel.text = blogStatus;
        [self.statusLabel sizeToFit];
        UIView *titleView = self.statusLabel.superview;
        CGFloat x = CGRectGetWidth(titleView.bounds) / 2;
        CGFloat y = 50 + CGRectGetHeight(self.statusLabel.frame) / 2;
        self.statusLabel.center = CGPointMake(x, y);
        self.statusLabel.alpha = 0;
        void (^animate)() = ^{
            CGRect frame = self.statusLabel.frame;
            frame.origin.y = CGRectGetMaxY(self.titleLabel.frame) + 3;
            self.statusLabel.frame = frame;
            self.statusLabel.alpha = 1;
        };
        if (animated) {
            [UIView animateWithDuration:0.3 animations:animate];
        }
        else {
            animate();
        }
    }
}

- (void)updateBlogStatus {
    [self updateStatusLabel:[NSString stringWithFormat:@"%@ as of %@", self.blogStatusText, [self.blogStatusDate mm_relativeToNow]] animated:NO];
}

- (void)updateBlogStatusAnimated:(BOOL)animated {
    [self updateStatusLabel:[NSString stringWithFormat:@"%@ as of %@", self.blogStatusText, [self.blogStatusDate mm_relativeToNow]] animated:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self requestStatusWithCaching:YES];
    PMKPromise *postP = self.postCollections ? [PMKPromise promiseWithValue:self.postCollections] : [self requestPostsWithCaching:YES];
    postP.then(^{
        if (self.selectedIndexPath && [self postForIndexPath:self.selectedIndexPath]) {
            [self.tableView selectRowAtIndexPath:self.selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
            self.selectedIndexPath = nil;
        }
        if (self.clearsSelectionOnViewWillAppear && self.tableView.indexPathForSelectedRow) {
            [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
        }
    });
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setupKeyboardNotifications];
    [self setupBlogStatusTimer];

    if (!self.hasAppeared) {
        self.hasAppeared = YES;
        [self hideSearchBarAnimated:YES];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self teardownKeyboardNotifications];
    [self teardownBlogStatusTimer];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateTitleViewConstraints];
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
    [self updateStatusLabel:@"Checking status" animated:YES];
    return [self.blogController requestBlogStatusWithCaching:useCache].then(^(BlogStatus *status) {
        self.blogStatusDate = status.date;
        if (status.dirty) {
            self.blogStatusText = @"Dirty";
        }
        else {
            self.blogStatusText = @"Everything published";
        }
        [self updateBlogStatusAnimated:YES];
        return status;
    }).catch(^(NSError *error) {
        [self updateStatusLabel:@"Failed to check status" animated:NO];
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
    NSArray *collections = [self collectionsForTableView];
    if (section < collections.count) {
        return collections[section];
    }
    return nil;
}

- (Post *)postForIndexPath:(NSIndexPath *)indexPath {
    PostCollection *collection = [self postCollectionForSection:indexPath.section];
    if (indexPath.row < collection.posts.count) {
        return collection.posts[indexPath.row];
    }
    return nil;
}

- (NSMutableArray *)drafts {
    PostCollection *collection = self.postCollections[SectionDrafts];
    return collection.posts;
}

- (NSMutableArray *)publishedPosts {
    PostCollection *collection = self.postCollections[SectionPublished];
    return collection.posts;
}

- (IBAction)insertNewObject:(id)sender {
    NSURL *url = [UIPasteboard generalPasteboard].URL;
    NSString *title = [[UIPasteboard generalPasteboard].string mm_stringByTrimmingWhitespace];
    if ([title hasPrefix:@"http"]) {
        if (!url) {
            url = [NSURL URLWithString:title];
        }
        title = nil;
    }
    Post *post = [Post newDraftWithTitle:title body:nil url:url];
    [self.drafts insertObject:post atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:SectionDrafts];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    [self performSegueWithIdentifier:@"showDetail" sender:sender];
}

- (IBAction)publish:(id)sender {
    __weak typeof(self) welf = self;
    void (^publish)(NSString *, PMKPromise *) = ^(NSString *message, PMKPromise *promise) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view.window animated:YES];
        hud.dimBackground = YES;
        hud.labelText = message;
        typeof(self) self = welf;
        promise.then(^{
            [self requestStatusWithoutCaching];
            hud.mode = MBProgressHUDModeCustomView;
            hud.customView = NewFontAwesomeHUDView([NSString fontAwesomeIconStringForEnum:FACheck]);
            hud.labelText = @"All good";
            [hud hide:YES afterDelay:1];
        }).catch(^(NSError *error) {
            hud.mode = MBProgressHUDModeCustomView;
            hud.customView = NewFontAwesomeHUDView([NSString fontAwesomeIconStringForEnum:FATimes]);
            hud.labelText = @"Fail";
            hud.detailsLabelText = error.localizedDescription;
            [hud hide:YES afterDelay:3];
            NSLog(@"fail %@ %@", error, error.userInfo);
        });
    };
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Publish" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"samhuri.net" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
        publish(@"samhuri.net", [self.blogController requestPublishToProductionEnvironment]);
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"beta.samhuri.net" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
        publish(@"beta.samhuri.net", [self.blogController requestPublishToStagingEnvironment]);
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Push to GitHub" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
        publish(@"Pushing", [self.blogController requestSync]);
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Keyboard notifications

- (void)setupKeyboardNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)teardownKeyboardNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [notificationCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)note {
    NSValue *keyboardFrame = note.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = keyboardFrame.CGRectValue.size.height;
    [self adjustTableViewBottomInsets:keyboardHeight];
}

- (void)keyboardWillHide:(NSNotification *)note {
    [self adjustTableViewBottomInsets:0];
}

- (void)adjustTableViewBottomInsets:(CGFloat)bottom {
    UIEdgeInsets inset = self.tableView.contentInset;
    inset.bottom = bottom;
    self.tableView.contentInset = inset;
    inset = self.tableView.scrollIndicatorInsets;
    inset.bottom = bottom;
    self.tableView.scrollIndicatorInsets = inset;
}

#pragma mark - Blog notificitons

- (void)setupBlogNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(postUpdated:) name:PostUpdatedNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(draftAdded:) name:DraftAddedNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(draftRemoved:) name:DraftRemovedNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(publishedPostAdded:) name:PublishedPostAddedNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(publishedPostRemoved:) name:PublishedPostRemovedNotification object:nil];
}

- (void)teardownBlogNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:PostUpdatedNotification object:nil];
    [notificationCenter removeObserver:self name:DraftAddedNotification object:nil];
    [notificationCenter removeObserver:self name:DraftRemovedNotification object:nil];
    [notificationCenter removeObserver:self name:PublishedPostAddedNotification object:nil];
    [notificationCenter removeObserver:self name:PublishedPostRemovedNotification object:nil];
}

- (void)addPost:(Post *)post toSection:(NSUInteger)section {
    PostCollection *collection = self.postCollections[section];
    NSInteger row = 0;
    [collection.posts insertObject:post atIndex:row];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)removePost:(Post *)post fromSection:(NSUInteger)section {
    BOOL (^isThisPost)(Post *, NSUInteger, BOOL *) = ^BOOL(Post *p, NSUInteger idx, BOOL *stop) {
        return [p.path isEqualToString:post.path];
    };
    PostCollection *collection = [self postCollectionForSection:section];
    NSUInteger row = [collection.posts indexOfObjectPassingTest:isThisPost];
    if (row != NSNotFound) {
        [collection.posts removeObjectAtIndex:row];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else {
        NSLog(@"cannot find removed post %@", post);
    }
}

- (void)postUpdated:(NSNotification *)note {
    Post *post = note.userInfo[PostUserInfoKey];
    BOOL (^isThisPost)(Post *, NSUInteger, BOOL *) = ^BOOL(Post *p, NSUInteger idx, BOOL *stop) {
        return [p.path isEqualToString:post.path];
    };
    NSUInteger section = SectionDrafts;
    NSUInteger row = [self.drafts indexOfObjectPassingTest:isThisPost];
    if (row == NSNotFound) {
        section = SectionPublished;
        row = [self.publishedPosts indexOfObjectPassingTest:isThisPost];
    }
    if (row != NSNotFound) {
        PostCollection *collection = [self postCollectionForSection:section];
        [collection.posts replaceObjectAtIndex:row withObject:post];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else {
        NSLog(@"cannot find updated post %@", post);
    }
}

- (void)draftAdded:(NSNotification *)note {
    // New drafts may already be here, because we insert newly created drafts that are unsaved.
    // Once saved this triggers, and we have to make sure we replace the existing one instead of
    // adding a duplicate.
    Post *post = note.userInfo[PostUserInfoKey];
    NSInteger row = [self.drafts indexOfObjectPassingTest:^BOOL(Post *p, NSUInteger idx, BOOL *stop) {
        return [post.path isEqualToString:p.path];
    }];
    if (row == NSNotFound)
    {
        [self addPost:post toSection:SectionDrafts];
    }
    else
    {
        self.drafts[row] = post;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:SectionDrafts]] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)draftRemoved:(NSNotification *)note {
    Post *post = note.userInfo[PostUserInfoKey];
    [self removePost:post fromSection:SectionDrafts];
}

- (void)publishedPostAdded:(NSNotification *)note {
    Post *post = note.userInfo[PostUserInfoKey];
    [self addPost:post toSection:SectionPublished];
}

- (void)publishedPostRemoved:(NSNotification *)note {
    Post *post = note.userInfo[PostUserInfoKey];
    [self removePost:post fromSection:SectionPublished];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Post *post = [self postForIndexPath:indexPath];
        EditorViewController *controller = (EditorViewController *)[[segue destinationViewController] topViewController];
        controller.blogController = self.blogController;
        [controller configureWithPost:post];
    }
}

#pragma mark - State restoration

static NSString *const StateRestorationBlogStatusDateKey = @"blogStatusDate";
static NSString *const StateRestorationBlogStatusTextKey = @"blogStatusText";
static NSString *const StateRestorationTableViewSelectedIndexPathKey = @"tableView.indexPathForSelectedRow";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder  {
    [coder encodeObject:self.blogStatusDate forKey:StateRestorationBlogStatusDateKey];
    [coder encodeObject:self.blogStatusText forKey:StateRestorationBlogStatusTextKey];
    [coder encodeObject:self.tableView.indexPathForSelectedRow forKey:StateRestorationTableViewSelectedIndexPathKey];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    self.blogStatusDate = [coder decodeObjectForKey:StateRestorationBlogStatusDateKey];
    self.blogStatusText = [coder decodeObjectForKey:StateRestorationBlogStatusTextKey];
    self.selectedIndexPath = [coder decodeObjectForKey:StateRestorationTableViewSelectedIndexPathKey];
    [super decodeRestorableStateWithCoder:coder];
}

#pragma mark - Table View

- (NSArray *)collectionsForTableView {
    return self.filteredPostCollections ?: self.postCollections;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self collectionsForTableView].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self postCollectionForSection:section].posts.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self postCollectionForSection:section].title;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 58;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *headerView = [view isKindOfClass:[UITableViewHeaderFooterView class]] ? (UITableViewHeaderFooterView *)view : nil;
    headerView.textLabel.textColor = [UIColor mm_colorFromInteger:0xF7F7F7];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PostCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    Post *post = [self postForIndexPath:indexPath];
    NSString *prefix = post.link ? @"→ " : @"";
    NSString *title = [NSString stringWithFormat:@"%@%@", prefix, post.title.length ? post.title : @"Untitled"];
    [cell configureWithTitle:title date:post.date];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        PostCollection *collection = [self postCollectionForSection:indexPath.section];
        Post *post = [self postForIndexPath:indexPath];
        // TODO: activity indicator
        [self.blogController requestDeletePost:post].then(^{
            [collection.posts removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        });
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // TODO: determine when this is called and see if we actually need it
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

#pragma mark - UISearchBarDelegate methods

- (void)hideSearchBarAnimated:(BOOL)animated {
    [self.tableView setContentOffset:CGPointMake(0, CGRectGetHeight(self.searchBar.bounds)) animated:animated];
}

- (void)filterPosts:(NSString *)text {
    NSMutableArray *collections = nil;
    if (text.length) {
        collections = [NSMutableArray new];
        for (PostCollection *collection in self.postCollections) {
            PostCollection *filteredCollection = [[PostCollection alloc] initWithTitle:collection.title posts:@[]];
            for (Post *post in collection.posts) {
                BOOL titleMatches = [post.title rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound;
                BOOL bodyMatches = [post.body rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound;
                if (titleMatches || bodyMatches) {
                    [filteredCollection.posts addObject:post];
                }
            }
            if (filteredCollection.posts.count) {
                [collections addObject:filteredCollection];
            }
        }
    }
    self.filteredPostCollections = collections;
    [self.tableView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self filterPosts:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self filterPosts:self.searchBar.text];
    [self.searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self filterPosts:nil];
    [self hideSearchBarAnimated:YES];
    [self.searchBar resignFirstResponder];
}

@end

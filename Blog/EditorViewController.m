//
//  EditorViewController.m
//  Blog
//
//  Created by Sami Samhuri on 2014-10-18.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

#import <PromiseKit/Promise.h>
#import "EditorViewController.h"
#import "BlogController.h"
#import "Post.h"
#import "PreviewViewController.h"
#import "ChangeTitleViewController.h"
#import "ModelStore.h"
#import "UIImage+FontAwesome.h"
#import "NSString+FontAwesome.h"
#import "UIColor+Hex.h"

@interface EditorViewController () <UITextViewDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *titleLabelTopConstraint;
@property (nonatomic, weak) IBOutlet UIView *linkView;
@property (nonatomic, weak) IBOutlet UIButton *linkIconButton;
@property (nonatomic, weak) IBOutlet UIButton *linkButton;
@property (nonatomic, weak) IBOutlet UIButton *removeLinkButton;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *publishBarButtonItem;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *saveBarButtonItem;
@property (nonatomic, strong) Post *modifiedPost;
@property (nonatomic, readonly, assign, getter=isDirty) BOOL dirty;
@property (nonatomic, strong) PMKPromise *savePromise;

@end

@implementation EditorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupFontAwesomeIcons];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSAssert(self.blogController, @"blogController is required");
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(configureLinkView) name:UIPasteboardChangedNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(postDeleted:) name:DraftRemovedNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(postDeleted:) name:PublishedPostRemovedNotification object:nil];
    [self configureView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [notificationCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter removeObserver:self name:UIPasteboardChangedNotification object:nil];
    [notificationCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [notificationCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [notificationCenter removeObserver:self name:DraftRemovedNotification object:nil];
    [notificationCenter removeObserver:self name:PublishedPostRemovedNotification object:nil];
    if (self.post) {
        [self savePost];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"showPreview"]) {
        PreviewViewController *previewViewController = segue.destinationViewController;
        previewViewController.promise = [self savePost];
        previewViewController.initialRequest = [self.blogController previewRequestWithPath:self.modifiedPost.path];
        return;
    }
}

#pragma mark - Managing the detail item

- (void)configureWithPost:(Post *)post {
    if (!(post && [post isEqual:self.post])) {
        self.post = post;
        self.modifiedPost = post;
        [self configureView];
    }
}

- (void)updateOnClassInjection {
    [self configureView];
}

- (void)configureView {
    [self configureTitleView];
    [self configureLinkView];
    [self configureBodyView];
    [self configureToolbar];
}

- (void)configureTitleView {
    if (!self.post) {
        self.title = nil;
        self.titleLabel.text = nil;
        return;
    }

    self.title = [self statusText];
    NSString *prefix = self.modifiedPost.link ? @"→ " : @"";
    NSString *title = self.modifiedPost.title.length ? self.modifiedPost.title : @"Untitled";
    self.titleLabel.text = [NSString stringWithFormat:@"%@%@", prefix, title];
}

- (NSString *)statusText {
    return self.modifiedPost.draft ? @"Draft" : self.modifiedPost.date;
}

- (void)configureLinkView {
    static const CGFloat TitleLabelTopMargin = 8;
    NSURL *url = self.modifiedPost.url;
    if (self.post && (url || [self pasteboardHasLink])) {
        NSString *title = url ? url.absoluteString : @"Add Link from Pasteboard";
        [self.linkButton setTitle:title forState:UIControlStateNormal];
        self.removeLinkButton.hidden = !url;
        const CGFloat titleLabelTop = TitleLabelTopMargin + CGRectGetMaxY(self.linkView.frame);
        if (self.titleLabelTopConstraint.constant <= titleLabelTop) {
            self.linkView.alpha = 1;
            self.linkButton.alpha = 0;
            [UIView animateWithDuration:0.3 animations:^{
                self.linkButton.alpha = 1;
                self.titleLabelTopConstraint.constant = titleLabelTop;
            }];
        }
    }
    else if (self.titleLabelTopConstraint.constant > TitleLabelTopMargin) {
        [UIView animateWithDuration:0.3 animations:^{
            self.linkView.alpha = 0;
            self.titleLabelTopConstraint.constant = TitleLabelTopMargin;
        }];
    }
}

- (void)configureBodyView {
    NSString *body = nil;
    CGPoint scrollOffset = CGPointZero;
    Post *post = self.modifiedPost;
    if (post) {
        body = post.body;
        // TODO: restore scroll offset for this post ... user defaults?
    }
    self.textView.text = body;
    self.textView.contentOffset = scrollOffset;
}

- (void)configureToolbar {
    BOOL toolbarEnabled = self.modifiedPost != nil;
    [self.toolbar.items enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger idx, BOOL *stop) {
        item.enabled = toolbarEnabled;
    }];
    self.publishBarButtonItem.title = self.modifiedPost.draft ? @"Publish" : @"Unpublish";
    [self configureSaveButton];
}

- (void)configureSaveButton {
    self.saveBarButtonItem.enabled = self.dirty;
    self.saveBarButtonItem.title = self.dirty ? @"Save" : nil;
    [self.toolbar setItems:self.toolbar.items animated:YES];
}

- (void)setupFontAwesomeIcons {
    [self.linkIconButton setTitle:[NSString fontAwesomeIconStringForEnum:FALink] forState:UIControlStateNormal];
    [self.removeLinkButton setTitle:[NSString fontAwesomeIconStringForEnum:FATimesCircle] forState:UIControlStateNormal];
}

#pragma mark - Notification handlers

- (void)applicationWillResignActive:(NSNotification *)note {
    if (self.post) {
        [self savePost];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)note {
    if (self.post) {
        [self configureView];
    }
}

- (void)keyboardWillShow:(NSNotification *)note {
    if (self.textView.isFirstResponder) {
        // This notification is called inside an animation block, but we don't want animation here.
        // Dispatch to break out of the animation.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showHideKeyboardButton];
        });
    }
}

- (void)keyboardWillHide:(NSNotification *)note {
    [self hideHideKeyboardButton];
}

- (void)postDeleted:(NSNotification *)note {
    NSString *path = note.userInfo[PostPathUserInfoKey];
    if ([path isEqualToString:self.post.path]) {
        [self configureWithPost:nil];
    }
}

#pragma mark - State restoration

static NSString *const StateRestorationPostKey = @"post";
static NSString *const StateRestorationModifiedPostKey = @"modifiedPost";

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    NSLog(@"%@ encode restorable state with coder %@", self, coder);
    [coder encodeObject:self.post forKey:StateRestorationPostKey];
    [coder encodeObject:self.modifiedPost forKey:StateRestorationModifiedPostKey];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    NSLog(@"%@ decode restorable state with coder %@", self, coder);
    self.post = [coder decodeObjectForKey:StateRestorationPostKey];
    self.modifiedPost = [coder decodeObjectForKey:StateRestorationModifiedPostKey];
    [super decodeRestorableStateWithCoder:coder];
}

#pragma mark -

- (void)showHideKeyboardButton;
{
    UIImage *image = [UIImage imageWithIcon:@"fa-chevron-down" backgroundColor:[UIColor clearColor] iconColor:[UIColor mm_colorFromInteger:0xAA0000] fontSize:20];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    [button setImage:image forState:UIControlStateNormal];
    [button addTarget:self.textView action:@selector(resignFirstResponder) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *hideKeyboardItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.rightBarButtonItem = hideKeyboardItem;
}

- (void)hideHideKeyboardButton;
{
    self.navigationItem.rightBarButtonItem = nil;
}

- (BOOL)isDirty;
{
    return self.post && (self.modifiedPost.new || ![self.modifiedPost isEqualToPost:self.post]);
}

- (PMKPromise *)savePost {
    if (self.savePromise) {
        return self.savePromise;
    }

    // TODO: persist on disk before going to the network
    NSAssert(self.post, @"post is required");
    [self updatePostBody];
    if (!self.post.new && [self.modifiedPost isEqualToPost:self.post]) {
        return [PMKPromise promiseWithValue:self.post];
    }

    self.textView.editable = NO;

    Post *newPost = self.modifiedPost;
    NSString *path = newPost.path;
    PMKPromise *savePromise;
    NSString *verb;
    if (newPost.new) {
        verb = @"create";
        savePromise = [self.blogController requestCreateDraft:newPost publishImmediately:NO];
    }
    else {
        verb = @"update";
        savePromise = [self.blogController requestUpdatePost:newPost];
    }
    self.savePromise = savePromise;

    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [indicatorView startAnimating];
    UIBarButtonItem *indicatorItem = [[UIBarButtonItem alloc] initWithCustomView:indicatorView];
    NSMutableArray *items = [self.toolbar.items mutableCopy];
    UIBarButtonItem *saveItem = self.saveBarButtonItem; // get a strong reference since the property is weak and we're removing it
    [items replaceObjectAtIndex:[items indexOfObject:saveItem] withObject:indicatorItem];
    [self.toolbar setItems:items animated:NO];

    __weak __typeof__(self) welf = self;
    return savePromise.then(^{
        __typeof__(self) self = welf;
        NSLog(@"%@ post at path %@", verb, path);

        // update our post because "new" may have changed, which is essential to correct operation
        [self configureWithPost:newPost];
        return newPost;
    }).catch(^(NSError *error) {
        NSLog(@"Failed to %@ post at path %@: %@ %@", verb, path, error.localizedDescription, error.userInfo);
        return error;
    }).finally(^{
        __typeof__(self) self = welf;
        self.textView.editable = YES;
        self.savePromise = nil;
        [items replaceObjectAtIndex:[items indexOfObject:indicatorItem] withObject:saveItem];
        [self.toolbar setItems:items animated:NO];
    });
}

- (void)updatePostBody {
    self.modifiedPost = [self.modifiedPost copyWithBody:self.textView.text];
    [self configureSaveButton];
}

- (void)updatePostTitle:(NSString *)title {
    self.modifiedPost = [self.modifiedPost copyWithTitle:title];
    [self configureTitleView];
}

- (void)updatePostURL:(NSURL *)url {
    self.modifiedPost = [self.modifiedPost copyWithURL:url];
    [self configureLinkView];
}

- (IBAction)publishOrUnpublish:(id)sender {
    // TODO: prevent changes while publishing
    __weak __typeof__(self) welf = self;
    [self savePost].then(^{
        __typeof__(self) self = welf;
        PMKPromise *promise = nil;
        Post *post = self.modifiedPost;
        if (post.draft) {
            promise = [self.blogController requestPublishDraft:post];
        }
        else {
            promise = [self.blogController requestUnpublishPost:post];
        }
        promise.then(^(Post *post) {
            self.post = post;
            self.modifiedPost = post;
            [self configureView];
        });
    });
}

- (IBAction)save:(id)sender {
    [self savePost];
}

- (IBAction)presentChangeTitle:(id)sender {
    if (self.presentedViewController) {
        return;
    }

    ChangeTitleViewController *changeTitleViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Change Title View Controller"];
    changeTitleViewController.modalPresentationStyle = UIModalPresentationPopover;
    changeTitleViewController.preferredContentSize = CGSizeMake(320, 60);
    changeTitleViewController.articleTitle = self.modifiedPost.title;
    UIPopoverPresentationController *presentationController = changeTitleViewController.popoverPresentationController;
    presentationController.delegate = self;
    presentationController.sourceView = self.view;
    presentationController.sourceRect = CGRectMake(CGRectGetWidth(self.view.bounds) / 2, CGRectGetMaxY(self.titleLabel.frame), 1, 1);
    presentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
    __weak __typeof__(changeTitleViewController) weakChangeTitleViewController = changeTitleViewController;
    changeTitleViewController.dismissBlock = ^{
        __typeof__(changeTitleViewController) changeTitleViewController = weakChangeTitleViewController;
        NSString *title = changeTitleViewController.articleTitle;
        [self updatePostTitle:title];
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    [self presentViewController:changeTitleViewController animated:YES completion:nil];
}

#pragma mark - UIPopoverPresentationControllerDelegate methods

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    UIViewController *dismissedVC = popoverPresentationController.presentedViewController;
    if ([dismissedVC isKindOfClass:[ChangeTitleViewController class]]) {
        ChangeTitleViewController *changeTitleViewController = (ChangeTitleViewController *)dismissedVC;
        NSString *title = changeTitleViewController.articleTitle;
        [self updatePostTitle:title];
    }
}

#pragma mark - Alerts

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    __weak __typeof__(self) welf = self;
    [alertController addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        __typeof__(self) self = welf;
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Link management

- (IBAction)tappedLinkButton:(id)sender {
    NSURL *currentURL = self.modifiedPost.url;
    if (currentURL) {
        [[UIApplication sharedApplication] openURL:currentURL];
    }
    else {
        [self addLinkFromPasteboard];
    }
}

- (IBAction)removeLink:(id)sender {
    [self updatePostURL:nil];
}

- (BOOL)pasteboardHasLink {
    return [UIPasteboard generalPasteboard].URL != nil;
}

- (void)addLinkFromPasteboard {
    NSURL *pasteboardURL = [UIPasteboard generalPasteboard].URL;
    if (pasteboardURL) {
        [self updatePostURL:pasteboardURL];
    }
    else {
        [self showAlertWithTitle:@"Error" message:@"No link found on pasteboard"];
    }
}

#pragma mark - UITextViewDelegate methods

- (void)textViewDidChange:(UITextView *)textView {
    [self updatePostBody];
}

@end

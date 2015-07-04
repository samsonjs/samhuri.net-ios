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
#import "MBProgressHUD.h"
#import "CommonUI.h"
#import "NotificationToSelectorMap.h"

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
@property (nonatomic, strong) NotificationToSelectorMap *notificationMap;

@end

@implementation EditorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupFontAwesomeIcons];
    [self setupNotifications];
    self.linkView.hidden = YES;
}

- (void)setupNotifications {
    NSDictionary *map = @{UIApplicationWillResignActiveNotification: NSStringFromSelector(@selector(applicationWillResignActive:)),
                          UIApplicationDidBecomeActiveNotification: NSStringFromSelector(@selector(applicationDidBecomeActive:)),
                          UIPasteboardChangedNotification: NSStringFromSelector(@selector(configureLinkView)),
                          UIKeyboardWillShowNotification: NSStringFromSelector(@selector(keyboardWillShow:)),
                          UIKeyboardWillHideNotification: NSStringFromSelector(@selector(keyboardWillHide:)),
                          DraftRemovedNotification: NSStringFromSelector(@selector(postDeleted:)),
                          PublishedPostRemovedNotification: NSStringFromSelector(@selector(postDeleted:)),
                          };
    self.notificationMap = [[NotificationToSelectorMap alloc] initWithNotificationMap:map];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSAssert(self.blogController, @"blogController is required");
    [self configureView];
    [self restoreScrollOffset];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.notificationMap addObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.post) {
        [self savePostAndWaitForCompilation:NO];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.notificationMap removeObserver:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"showPreview"]) {
        PreviewViewController *previewViewController = segue.destinationViewController;
        previewViewController.promise = [self savePostAndWaitForCompilation:YES];
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
            self.linkView.hidden = NO;
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
        } completion:^(BOOL finished) {
            self.linkView.hidden = YES;
        }];
    }
}

- (void)configureBodyView {
    NSString *body = nil;
    Post *post = self.modifiedPost;
    if (post) {
        body = post.body;
    }
    self.textView.text = body;
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
        [self savePostAndWaitForCompilation:NO];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)note {
    if (self.post) {
        [self configureView];
    }
}

- (UIViewAnimationOptions)animationOptionsForCurve:(UIViewAnimationCurve)curve {
    UIViewAnimationOptions options = 0;
    if (curve == UIViewAnimationCurveEaseIn) {
        options |= UIViewAnimationOptionCurveEaseIn;
    }
    if (curve == UIViewAnimationCurveEaseOut) {
        options |= UIViewAnimationOptionCurveEaseOut;
    }
    if (curve == UIViewAnimationCurveEaseInOut) {
        options |= UIViewAnimationOptionCurveEaseInOut;
    }
    if (curve == UIViewAnimationCurveLinear) {
        options |= UIViewAnimationOptionCurveLinear;
    }
    return options;
}

- (void)keyboardWillShow:(NSNotification *)note {
    NSValue *keyboardFrame = note.userInfo[UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = keyboardFrame.CGRectValue.size.height;
    NSNumber *durationNumber = note.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curveNumber = note.userInfo[UIKeyboardAnimationCurveUserInfoKey];
    [UIView animateWithDuration:durationNumber.doubleValue delay:0 options:[self animationOptionsForCurve:curveNumber.integerValue] animations:^{
        self.toolbar.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight);
    } completion:nil];
    [self adjustTextViewBottomInset:keyboardHeight];

    if (self.textView.isFirstResponder) {
        // This notification is called inside an animation block, but we don't want animation here.
        // Dispatch to break out of the animation.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showHideKeyboardButton];
        });
    }
}

- (void)keyboardWillHide:(NSNotification *)note {
    NSNumber *durationNumber = note.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curveNumber = note.userInfo[UIKeyboardAnimationCurveUserInfoKey];
    [UIView animateWithDuration:durationNumber.doubleValue delay:0 options:[self animationOptionsForCurve:curveNumber.integerValue] animations:^{
        self.toolbar.transform = CGAffineTransformIdentity;
    } completion:nil];
    [self adjustTextViewBottomInset:0];
    [self hideHideKeyboardButton];
}

- (void)adjustTextViewBottomInset:(CGFloat)bottomInset {
    UIEdgeInsets inset = self.textView.contentInset;
    inset.bottom = bottomInset;
    self.textView.contentInset = inset;
    inset = self.textView.scrollIndicatorInsets;
    inset.bottom = bottomInset;
    self.textView.scrollIndicatorInsets = inset;
    // TODO: put the selection in the middle somehow ... can we get the point/rect for the selection?
    [self.textView scrollRangeToVisible:self.textView.selectedRange];
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
    [coder encodeObject:self.post forKey:StateRestorationPostKey];
    [coder encodeObject:self.modifiedPost forKey:StateRestorationModifiedPostKey];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
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

- (void)setModifiedPost:(Post *)modifiedPost {
    _modifiedPost = modifiedPost;
    [self configureSaveButton];
}

- (PMKPromise *)savePostAndWaitForCompilation:(BOOL)waitForCompilation {
    if (self.savePromise) {
        return self.savePromise;
    }

    [self saveScrollOffset];

    // TODO: persist on disk before going to the network
    NSAssert(self.post, @"post is required");
    [self updatePostBody];
    if (!self.post.new && [self.modifiedPost isEqualToPost:self.post]) {
        return [PMKPromise promiseWithValue:self.post];
    }

    self.textView.editable = NO;

    Post *modifiedPost = self.modifiedPost;
    NSString *path = modifiedPost.path;
    PMKPromise *savePromise;
    NSString *verb;
    if (modifiedPost.new) {
        verb = @"create";
        savePromise = [self.blogController requestCreateDraft:modifiedPost publishImmediatelyToEnvironment:nil waitForCompilation:waitForCompilation];
    }
    else {
        verb = @"update";
        savePromise = [self.blogController requestUpdatePost:modifiedPost waitForCompilation:waitForCompilation];
    }
    self.savePromise = savePromise;

    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [indicatorView startAnimating];
    UIBarButtonItem *indicatorItem = [[UIBarButtonItem alloc] initWithCustomView:indicatorView];
    NSMutableArray *items = [self.toolbar.items mutableCopy];
    UIBarButtonItem *saveItem = self.saveBarButtonItem; // get a strong reference since the property is weak and we're removing it
    [items replaceObjectAtIndex:[items indexOfObject:saveItem] withObject:indicatorItem];
    [self.toolbar setItems:items animated:NO];

    __weak typeof(self) welf = self;
    return savePromise.then(^(Post *savedPost) {
        typeof(self) self = welf;
        NSLog(@"%@ post at path %@", verb, path);

        // update our post because "new" may have changed, which is essential to correct operation
        [self configureWithPost:savedPost];
        return savedPost;
    }).catch(^(NSError *error) {
        NSLog(@"Failed to %@ post at path %@: %@ %@", verb, path, error.localizedDescription, error.userInfo);
        return error;
    }).finally(^{
        typeof(self) self = welf;
        self.textView.editable = YES;
        self.savePromise = nil;
        [items replaceObjectAtIndex:[items indexOfObject:indicatorItem] withObject:saveItem];
        [self.toolbar setItems:items animated:NO];
    });
}

- (NSString *)scrollOffsetKey {
    NSString *key = [NSString stringWithFormat:@"ScrollOffset-%@", self.modifiedPost.path];
    return key;
}

- (void)saveScrollOffset {
    CGPoint scrollOffset = self.textView.contentOffset;
    NSString *serializedOffset = NSStringFromCGPoint(scrollOffset);
    [[NSUserDefaults standardUserDefaults] setObject:serializedOffset forKey:[self scrollOffsetKey]];
}

- (void)restoreScrollOffset {
    NSString *serializedOffset = [[NSUserDefaults standardUserDefaults] objectForKey:[self scrollOffsetKey]];
    CGPoint scrollOffset = serializedOffset ? CGPointFromString(serializedOffset) : CGPointZero;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.textView setContentOffset:scrollOffset animated:YES];
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
    [self configureTitleView];
}

- (IBAction)publishOrUnpublish:(id)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view.window animated:YES];
    hud.dimBackground = YES;
    BOOL isPublish = self.modifiedPost.draft;
    hud.labelText = isPublish ? @"Publishing" : @"Unpublishing";
    __weak typeof(self) welf = self;
    [self savePostAndWaitForCompilation:NO].then(^{
        typeof(self) self = welf;
        PMKPromise *promise = nil;
        if (isPublish) {
            promise = [self.blogController requestPublishDraft:self.modifiedPost];
        }
        else {
            promise = [self.blogController requestUnpublishPost:self.modifiedPost];
        }
        promise.then(^(Post *post) {
            hud.mode = MBProgressHUDModeCustomView;
            hud.customView = NewFontAwesomeHUDView([NSString fontAwesomeIconStringForEnum:FACheck]);
            hud.labelText = isPublish ? @"Published" : @"Unpublished";
            self.post = post;
            self.modifiedPost = post;
            [self configureView];
            [hud hide:YES afterDelay:1];
        }).catch(^(NSError *error) {
            hud.mode = MBProgressHUDModeCustomView;
            hud.customView = NewFontAwesomeHUDView([NSString fontAwesomeIconStringForEnum:FATimes]);
            hud.labelText = @"Fail";
            hud.detailsLabelText = error.localizedDescription;
            [hud hide:YES afterDelay:3];
            NSLog(@"fail %@ %@", error, error.userInfo);
        });
    });
}

- (IBAction)save:(id)sender {
    [self savePostAndWaitForCompilation:NO];
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
    __weak typeof(changeTitleViewController) weakChangeTitleViewController = changeTitleViewController;
    changeTitleViewController.dismissBlock = ^{
        typeof(changeTitleViewController) changeTitleViewController = weakChangeTitleViewController;
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
    [alertController addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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

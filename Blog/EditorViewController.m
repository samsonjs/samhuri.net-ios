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

@interface EditorViewController () <UITextViewDelegate, UIPopoverPresentationControllerDelegate>

@property (nonatomic, weak) IBOutlet UILabel *titleView;
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *textViewTopConstraint;
@property (nonatomic, weak) IBOutlet UILabel *linkLabel;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *publishBarButtonItem;
@property (strong, nonatomic) Post *modifiedPost;
@property (strong, nonatomic) PMKPromise *savePromise;

@end

@implementation EditorViewController

#pragma mark - Managing the detail item

- (void)setPost:(id)newPost {
    if (_post != newPost) {
        _post = newPost;
        self.modifiedPost = newPost;
        [self configureView];
    }
}

- (void)configureView {
    [self configureTitleView];
    [self configureLinkView];
    [self configureBodyView];
    [self configureToolbar];
}

- (void)configureTitleView {
    self.titleView.text = self.modifiedPost.title.length ? self.modifiedPost.title : @"Untitled";
    [self.titleView sizeToFit];
}

- (void)configureLinkView {
    NSURL *url = self.modifiedPost.url;
    if (url) {
        self.linkLabel.text = url.absoluteString;
        self.linkLabel.alpha = 0;
        [UIView animateWithDuration:0.3 animations:^{
            self.linkLabel.alpha = 1;
            self.textViewTopConstraint.constant = CGRectGetMaxY(self.linkLabel.frame) + 4;
        }];
    }
    else {
        [UIView animateWithDuration:0.3 animations:^{
            self.linkLabel.alpha = 0;
            self.textViewTopConstraint.constant = 0;
        } completion:^(BOOL finished) {
            self.linkLabel.text = nil;
        }];
    }
}

- (void)configureBodyView {
    NSString *body = nil;
    CGPoint scrollOffset = CGPointZero;
    Post *post = self.modifiedPost;
    if (post) {
        // FIXME: date, status (draft, published)
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
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(savePost) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [self savePost];
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

    Post *newPost = self.modifiedPost;
    NSString *path = newPost.path;
    PMKPromise *savePromise;
    NSString *verb;
    if (newPost.new) {
        verb = @"create";
        savePromise = [self.blogController requestCreateDraft:newPost];
    }
    else {
        verb = @"update";
        savePromise = [self.blogController requestUpdatePost:newPost];
    }
    self.savePromise = savePromise;
    return savePromise.then(^{
        NSLog(@"%@ post at path %@", verb, path);

        // TODO: something better than this
        // update our post because "new" may have changed, which is essential to correct operation
        if ([self.modifiedPost isEqualToPost:newPost]) {
            self.post = newPost;
        }
        else {
            Post *modified = self.modifiedPost;
            self.post = newPost;
            self.modifiedPost = modified;
            [self configureView];
        }
        if (self.postUpdatedBlock) {
            self.postUpdatedBlock(self.post);
        }
        return newPost;
    }).catch(^(NSError *error) {
        NSLog(@"Failed to %@ post at path %@: %@ %@", verb, path, error.localizedDescription, error.userInfo);
        return error;
    }).finally(^{
        self.savePromise = nil;
    });
}

- (void)updatePostBody {
    self.modifiedPost = [self.modifiedPost copyWithBody:self.textView.text];
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
    [self savePost].then(^{
        PMKPromise *promise = nil;
        Post *post = self.modifiedPost;
        if (post.draft) {
            promise = [self.blogController requestPublishDraftWithPath:post.path];
        }
        else {
            promise = [self.blogController requestUnpublishPostWithPath:post.path];
        }
        promise.then(^(Post *post) {
            self.post = post;
            self.modifiedPost = post;
            [self configureView];
            if (self.postUpdatedBlock) {
                self.postUpdatedBlock(post);
            }
        });
    });
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
    presentationController.sourceRect = CGRectMake(CGRectGetWidth(self.view.bounds) / 2, 0, 1, 1);
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

- (IBAction)presentLinkActionSheet:(id)sender {
    if (self.presentedViewController) {
        return;
    }

    NSURL *currentURL = self.modifiedPost.url;

    // If nothing to add or remove, then don't present the action sheet.
    if (!currentURL && ![self pasteboardHasLink]) {
        [self showAlertWithTitle:@"No Link Found" message:@"Copy a link to the pasteboard to add it."];
        return;
    }

    UIAlertController *menuController = [UIAlertController alertControllerWithTitle:nil message:currentURL.absoluteString preferredStyle:UIAlertControllerStyleActionSheet];

    // Cancel
    [menuController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];

    // Add/Replace from Pasteboard
    NSString *addVerb = self.modifiedPost.link ? @"Replace" : @"Add";
    if ([self pasteboardHasLink]) {
        NSString *title = [NSString stringWithFormat:@"%@ from Pasteboard", addVerb];
        __weak __typeof__(self) welf = self;
        [menuController addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            __typeof__(self) self = welf;
            [self dismissViewControllerAnimated:YES completion:^{
                [self addLinkFromPasteboard];
            }];
        }]];
    }

    // Remove Link
    if (currentURL) {
        __weak __typeof__(self) welf = self;
        [menuController addAction:[UIAlertAction actionWithTitle:@"Remove Link" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            __typeof__(self) self = welf;
            [self dismissViewControllerAnimated:YES completion:^{
                [self updatePostURL:nil];
            }];
        }]];
    }

    [self presentViewController:menuController animated:YES completion:nil];
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

@end

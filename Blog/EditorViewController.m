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
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
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
    NSString *title = nil;
    NSString *body = nil;
    CGPoint scrollOffset = CGPointZero;
    Post *post = self.modifiedPost;
    if (post) {
        // FIXME: date, status (draft, published)
        body = post.body;
        // TODO: restore scroll offset for this post ... user defaults?
    }
    [self configureTitleView];
    self.textView.text = body;
    self.textView.contentOffset = scrollOffset;
    // TODO: url

    BOOL toolbarEnabled = post != nil;
    [self.toolbar.items enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger idx, BOOL *stop) {
        item.enabled = toolbarEnabled;
    }];
}

- (void)configureTitleView {
    self.titleView.text = self.modifiedPost.title.length ? self.modifiedPost.title : @"Untitled";
    [self.titleView sizeToFit];
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
    [self savePost];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
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
    changeTitleViewController.dismissBlock = ^{
        NSString *title = changeTitleViewController.articleTitle;
        [self updatePostTitle:title];
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    [self presentViewController:changeTitleViewController animated:YES completion:nil];
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    ChangeTitleViewController *changeTitleViewController = (ChangeTitleViewController *)popoverPresentationController.presentedViewController;
    NSString *title = changeTitleViewController.articleTitle;
    [self updatePostTitle:title];
}

@end

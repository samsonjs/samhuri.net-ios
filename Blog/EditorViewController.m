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

@interface EditorViewController () <UITextViewDelegate>

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;

@end

@implementation EditorViewController

#pragma mark - Managing the detail item

- (void)setPost:(id)newPost {
    if (_post != newPost) {
        _post = newPost;
        [self configureView];
    }
}

- (void)configureView {
    NSString *title = nil;
    NSString *text = nil;
    CGPoint scrollOffset = CGPointZero;
    if (self.post) {
        // FIXME: date, status (draft, published)
        title = self.post.title.length ? self.post.title : @"Untitled";
        text = self.post.body;
        // TODO: restore scroll offset for this post ... user defaults?
    }
    self.navigationItem.title = title;
    self.textView.text = text;
    self.textView.contentOffset = scrollOffset;

    BOOL toolbarEnabled = self.post != nil;
    [self.toolbar.items enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger idx, BOOL *stop) {
        item.enabled = toolbarEnabled;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(savePostBody) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self savePostBody];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (PMKPromise *)savePostBody {
    NSString *body = self.textView.text;
    if (!self.post || !body.length) {
        return [PMKPromise promiseWithValue:nil];
    }

    Post *newPost = [self.post copyWithBody:body];
    if ([newPost isEqual:self.post]) {
        return [PMKPromise promiseWithValue:self.post];
    }

    self.post = newPost;
    NSString *path = self.post.path;
    PMKPromise *savePromise;
    NSString *verb;
    if (self.post.new) {
        verb = @"create";
        savePromise = [self.blogController requestCreateDraft:self.post];
    }
    else {
        verb = @"update";
        savePromise = [self.blogController requestUpdatePost:self.post];
    }
    return savePromise.then(^(Post *post) {
        NSLog(@"%@ post at path %@", verb, path);

        // TODO: something better than this
        // update our post because "new" may have changed, which is essential to correct operation
        self.post = post;
        [self configureView];
        if (self.postUpdatedBlock) {
            self.postUpdatedBlock(self.post);
        }

        return post;
    }).catch(^(NSError *error) {
        NSLog(@"Falied to %@ post at path %@: %@ %@", verb, path, error.localizedDescription, error.userInfo);
        return error;
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.identifier isEqualToString:@"showPreview"]) {
        PreviewViewController *previewViewController = segue.destinationViewController;
        previewViewController.promise = [self savePostBody];
        previewViewController.initialRequest = [self.blogController previewRequestWithPath:self.post.path];
    }
}

@end

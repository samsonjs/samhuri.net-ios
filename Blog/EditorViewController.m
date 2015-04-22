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
    if (self.post) {
        // FIXME: date, status (draft, published)
        self.navigationItem.title = self.post.title ?: @"Untitled";
        self.textView.text = self.post.body;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureView];
}

- (void)viewWillAppear:(BOOL)animated;
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(savePostBody) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self savePostBody];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (PMKPromise *)savePostBody {
    if (!self.post || !self.textView) { return [PMKPromise promiseWithValue:nil]; }

    Post *newPost = [self.post copyWithBody:self.textView.text];
    if (![self.post isEqual:newPost])
    {
        self.post = newPost;
        return [self.blogController requestUpdatePostWithPath:self.post.path title:self.post.title body:self.post.body link:self.post.url.absoluteString]
        .then(^(Post *post) {
            NSLog(@"saved post at path %@", self.post.path);
        }).catch(^(NSError *error) {
            NSLog(@"Error saving post at path %@: %@ %@", self.post.path, error.localizedDescription, error.userInfo);
        });
    }
    return [PMKPromise promiseWithValue:self.post];
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

//
// Created by Sami Samhuri on 2015-06-27.
// Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//
#import <ObjectiveSugar/NSArray+ObjectiveSugar.h>
#import "BlogSplitViewController.h"
#import "PostsViewController.h"
#import "EditorViewController.h"
#import "SamhuriNet.h"

@interface BlogSplitViewController ()

@property (nonatomic, readonly, strong) PostsViewController *postsViewController;

@end

@implementation BlogSplitViewController

- (void)setSite:(SamhuriNet *)site {
    _site = site;
    self.postsViewController.blogController = self.site.blogController;
    self.editorViewController.blogController = self.site.blogController;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.postsViewController.preferredContentSize = CGSizeMake(320, 600);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateForNewTraitCollection:self.traitCollection];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    [self updateForNewTraitCollection:newCollection];
}

- (void)updateForNewTraitCollection:(UITraitCollection *)newCollection {
    BOOL isCompact = newCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
    self.postsViewController.clearsSelectionOnViewWillAppear = isCompact;
}

- (UINavigationController *)masterNavigationController {
    return self.viewControllers.firstObject;
}

- (UINavigationController *)detailNavigationController {
    return self.viewControllers.count == 2 ? self.viewControllers.lastObject : nil;
}

- (PostsViewController *)postsViewController {
    return (PostsViewController *)self.masterNavigationController.viewControllers.firstObject;
}

- (EditorViewController *)editorViewController {
    return (EditorViewController *)self.detailNavigationController.viewControllers.firstObject;
}

@end
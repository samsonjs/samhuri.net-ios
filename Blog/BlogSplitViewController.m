//
// Created by Sami Samhuri on 2015-06-27.
// Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//
#import <ObjectiveSugar/NSArray+ObjectiveSugar.h>
#import "BlogSplitViewController.h"
#import "PostsViewController.h"
#import "EditorViewController.h"
#import "SamhuriNet.h"

@implementation BlogSplitViewController

- (void)setSite:(SamhuriNet *)site {
    _site = site;
    self.postsViewController.blogController = self.site.blogController;
    self.editorViewControllerForPhone.blogController = self.site.blogController;
    self.editorViewControllerForPad.blogController = self.site.blogController;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.postsViewController.preferredContentSize = CGSizeMake(320, 600);
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    BOOL isCompact = newCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
    self.postsViewController.clearsSelectionOnViewWillAppear = isCompact;
}

- (UINavigationController *)masterNavigationController {
    return self.viewControllers.firstObject;
}

- (UINavigationController *)detailNavigationController {
    return self.viewControllers.lastObject;
}

- (PostsViewController *)postsViewController {
    return (PostsViewController *)self.masterNavigationController.viewControllers.firstObject;
}

- (EditorViewController *)editorViewControllerForPhone {
    UINavigationController *navigationController = self.masterNavigationController;
    if (navigationController.viewControllers.count > 1) {
        navigationController = navigationController.viewControllers.lastObject;
    }
    EditorViewController *editorViewController = (EditorViewController *)navigationController.viewControllers.firstObject;
    return editorViewController;
}

- (EditorViewController *)editorViewControllerForPad {
    return (EditorViewController *)self.detailNavigationController.viewControllers.firstObject;
}

@end
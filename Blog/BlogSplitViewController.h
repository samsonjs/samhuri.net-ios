//
// Created by Sami Samhuri on 2015-06-27.
// Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//
@import UIKit;

@class PostsViewController;
@class EditorViewController;
@class SamhuriNet;

@interface BlogSplitViewController : UISplitViewController

@property (nonatomic, strong) SamhuriNet *site;

- (UINavigationController *)masterNavigationController;
- (UINavigationController *)detailNavigationController;
- (PostsViewController *)postsViewController;
- (EditorViewController *)editorViewControllerForPhone;
- (EditorViewController *)editorViewControllerForPad;

@end
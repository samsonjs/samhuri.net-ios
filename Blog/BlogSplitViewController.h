//
// Created by Sami Samhuri on 2015-06-27.
// Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//
@import UIKit;

@class SamhuriNet;
@class EditorViewController;

@interface BlogSplitViewController : UISplitViewController

@property (nonatomic, strong) SamhuriNet *site;
@property (nonatomic, readonly, strong) UINavigationController *masterNavigationController;
@property (nonatomic, readonly, strong) UINavigationController *detailNavigationController;
@property (nonatomic, readonly, strong) EditorViewController *editorViewController;

@end
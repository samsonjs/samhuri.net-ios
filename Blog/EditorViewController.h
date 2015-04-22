//
//  EditorViewController.h
//  Blog
//
//  Created by Sami Samhuri on 2014-10-18.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

@import UIKit;

@class BlogController;
@class Post;

@interface EditorViewController : UIViewController

@property (strong, nonatomic) BlogController *blogController;
@property (strong, nonatomic) Post *post;

@end


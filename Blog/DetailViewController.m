//
//  DetailViewController.m
//  Blog
//
//  Created by Sami Samhuri on 2014-10-18.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

#import "DetailViewController.h"
#import "Post.h"

@interface DetailViewController ()

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setPost:(id)newPost {
    if (_post != newPost) {
        _post = newPost;

        // Update the view.
        [self configureView];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.post) {
        // FIXME: date, link (edit, open), status (draft, published), delete, preview, publish
        self.navigationItem.title = self.post.title ?: @"Untitled";
        self.detailDescriptionLabel.text = self.post.body;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

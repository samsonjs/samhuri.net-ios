//
//  PreviewViewController.m
//  Blog
//
//  Created by Sami Samhuri on 2015-04-19.
//  Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//

#import "PreviewViewController.h"

@interface PreviewViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation PreviewViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.initialRequest) {
        if (self.promise) {
            self.promise.then(^{
                [self.webView loadRequest:self.initialRequest];
            }).finally(^{
                self.promise = nil;
            });
        }
        else {
            [self.webView loadRequest:self.initialRequest];
        }
    }
}

- (void)setInitialRequest:(NSURLRequest *)initialRequest {
    _initialRequest = initialRequest;
    [self.webView loadHTMLString:@"<!doctype html><html><head><title></title></head><body></body></html>" baseURL:nil];
}

#pragma mark - UIWebViewDelegate methods

@end

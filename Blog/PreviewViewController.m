//
//  PreviewViewController.m
//  Blog
//
//  Created by Sami Samhuri on 2015-04-19.
//  Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//

#import "PreviewViewController.h"

@interface PreviewViewController () <UIWebViewDelegate>

@property (nonatomic, weak) IBOutlet UIWebView *webView;

@end

@implementation PreviewViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // UIWebView restores its request so we just have to reload it
    if (!self.initialRequest && self.webView.request) {
        [self.webView reload];
        return;
    }

    if (self.initialRequest) {
        if (self.promise) {
            __weak __typeof__(self) welf = self;
            self.promise.then(^{
                __typeof__(self) self = welf;
                [self.webView loadRequest:self.initialRequest];
            }).finally(^{
                __typeof__(self) self = welf;
                self.promise = nil;
            });
            return;
        }
        [self.webView loadRequest:self.initialRequest];
        return;
    }
}

- (void)setInitialRequest:(NSURLRequest *)initialRequest {
    _initialRequest = initialRequest;
    [self.webView loadHTMLString:@"<!doctype html><html><head><title></title></head><body></body></html>" baseURL:nil];
}

#pragma mark - UIWebViewDelegate methods

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if ([webView.request.URL isEqual:self.initialRequest.URL]) {
        self.initialRequest = nil;
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    __weak __typeof__(self) welf = self;
    [alertController addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        __typeof__(self) self = welf;
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end

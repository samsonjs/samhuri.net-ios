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
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *indicatorView;

@end

@implementation PreviewViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // UIWebView restores its request so we just have to reload it
    if (!self.initialRequest && self.webView.request) {
        [self.webView reload];
        [self.indicatorView startAnimating];
        return;
    }

    if (self.initialRequest) {
        PMKPromise *p = self.promise ?: [PMKPromise promiseWithValue:nil];
        __weak typeof(self) welf = self;
        p.then(^{
            typeof(self) self = welf;
            [self.webView loadRequest:self.initialRequest];
            [self.indicatorView startAnimating];
        }).finally(^{
            typeof(self) self = welf;
            self.promise = nil;
        });
        return;
    }
}

- (void)setInitialRequest:(NSURLRequest *)initialRequest {
    _initialRequest = initialRequest;
    self.webView.hidden = YES;
}

#pragma mark - UIWebViewDelegate methods

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.webView.hidden = NO;
    [self.indicatorView stopAnimating];
    if ([webView.request.URL isEqual:self.initialRequest.URL]) {
        self.initialRequest = nil;
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.indicatorView stopAnimating];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) welf = self;
    [alertController addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        typeof(self) self = welf;
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end

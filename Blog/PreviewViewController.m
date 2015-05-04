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
            __weak __typeof__(self) welf = self;
            self.promise.then(^{
                __typeof__(self) self = welf;
                [self.webView loadRequest:self.initialRequest];
            }).finally(^{
                __typeof__(self) self = welf;
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

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.initialRequest forKey:@"initialRequest"];
    [coder encodeObject:self.webView.request.URL forKey:@"webView.request.URL"];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    NSURL *url = [coder decodeObjectForKey:@"webView.request.URL"];
    if (url) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    }
    else {
        self.initialRequest = [coder decodeObjectForKey:@"initialRequest"];
    }
    [super decodeRestorableStateWithCoder:coder];
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

//
//  PreviewViewController.m
//  Blog
//
//  Created by Sami Samhuri on 2015-04-19.
//  Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//

@import WebKit;
#import "PreviewViewController.h"

@interface PreviewViewController () <WKNavigationDelegate>

@property (nonatomic, weak) IBOutlet WKWebView *webView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *centerIndicatorView;
@property (nonatomic, weak) UIActivityIndicatorView *cornerIndicatorView;

@end

@implementation PreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupCornerIndicatorView];
    [self setupWebView];
}

- (void)setupCornerIndicatorView {
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    indicator.hidesWhenStopped = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:indicator];
    self.cornerIndicatorView = indicator;
}

- (void)setupWebView {
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    webView.navigationDelegate = self;
    [self.view insertSubview:webView belowSubview:self.centerIndicatorView];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:webView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:webView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:webView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:webView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
    self.webView = webView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.initialRequest) {
        PMKPromise *p = self.promise ?: [PMKPromise promiseWithValue:nil];
        __weak typeof(self) welf = self;
        p.then(^{
            typeof(self) self = welf;
            [self.centerIndicatorView startAnimating];
            [self.cornerIndicatorView stopAnimating];
            self.webView.hidden = YES;
            [self.webView loadRequest:self.initialRequest];
        }).finally(^{
            typeof(self) self = welf;
            self.promise = nil;
        });
        return;
    }
}

- (void)applicationFinishedRestoringState {
    [super applicationFinishedRestoringState];
    [self.centerIndicatorView startAnimating];
    [self.cornerIndicatorView stopAnimating];
    self.webView.hidden = YES;
    [self.webView reload];
}

#pragma mark - UIWebViewDelegate methods

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if (!self.webView.hidden) {
        [self.cornerIndicatorView startAnimating];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.webView.hidden = NO;
    [self.centerIndicatorView stopAnimating];
    [self.cornerIndicatorView stopAnimating];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self.centerIndicatorView stopAnimating];
    [self.cornerIndicatorView stopAnimating];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) welf = self;
    [alertController addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        typeof(self) self = welf;
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end

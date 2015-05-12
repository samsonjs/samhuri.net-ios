//
//  ShareViewController.m
//  samhuri.net
//
//  Created by Sami Samhuri on 2015-05-05.
//  Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//
#import <PromiseKit/PromiseKit.h>
#import "ShareViewController.h"
#import "SamhuriNet.h"
#import "BlogController.h"
#import "Post.h"

@interface ShareViewController ()

@property (nonatomic, readonly, strong) NSItemProvider *URLProvider;
@property (nonatomic, assign) BOOL checkedForURLProvider;

@end

@implementation ShareViewController

@synthesize URLProvider = _URLProvider;

- (BOOL)isContentValid {
    return self.URLProvider != nil;
}

- (UIView *)loadPreviewView {
    // TODO: markdown preview ... or punt to the server
    return [super loadPreviewView];
}

- (void)didSelectPost {
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    SamhuriNet *site = [SamhuriNet new];
    BlogController *blogController = site.blogController;
    NSRange titleEndRange = [self.contentText rangeOfString:@"\n\n"];
    NSString *title = titleEndRange.location == NSNotFound ? self.contentText : [self.contentText substringToIndex:titleEndRange.location];
    NSString *body = titleEndRange.location == NSNotFound ? @"" : [self.contentText substringFromIndex:titleEndRange.location + titleEndRange.length];
    NSLog(@"title = %@", title);
    NSLog(@"body = %@", body);
    NSItemProvider *urlProvider = [self firstURLProvider];
    BOOL reallyPost = YES;
    [urlProvider loadItemForTypeIdentifier:@"public.url" options:nil completionHandler:^(NSURL *url, NSError *error) {
        // TODO: image
        NSLog(@"url = %@", url);
        if (reallyPost) {
            Post *post = [Post newDraftWithTitle:title body:body url:url];
            [blogController requestCreateDraft:post publishImmediatelyToEnvironment:@"production" waitForCompilation:NO].catch(^(NSError *error) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self dismissViewControllerAnimated:YES completion:nil];
                }]];
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
        [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
    }];
}

- (NSItemProvider *)firstURLProvider {
    NSExtensionItem *item = self.extensionContext.inputItems.firstObject;
    NSLog(@"item = %@", item);
    for (NSItemProvider *provider in item.attachments) {
        NSLog(@"provider = %@", provider);
        if ([provider hasItemConformingToTypeIdentifier:@"public.url"]) {
            return provider;
        }
    }
    return nil;
}

- (NSItemProvider *)URLProvider {
    if (!self.checkedForURLProvider) {
        _URLProvider = [self firstURLProvider];
        if (!_URLProvider) {
            NSLog(@"ERROR: No URL provider found");
        }
        self.checkedForURLProvider = YES;
    }
    return _URLProvider;
}

- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    return @[];
}

@end

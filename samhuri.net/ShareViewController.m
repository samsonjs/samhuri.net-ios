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

@end

@implementation ShareViewController

- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    return YES;
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
    NSExtensionItem *item = self.extensionContext.inputItems.firstObject;
    NSItemProvider *provider = item.attachments.firstObject;
    [provider loadItemForTypeIdentifier:@"public.url" options:nil completionHandler:^(NSURL *url, NSError *error) {
        // TODO: image
        Post *post = [Post newDraftWithTitle:title body:body url:url];
        [blogController requestCreateDraft:post publishImmediatelyToEnvironment:@"production" waitForCompilation:NO].catch(^(NSError *error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }]];
            [self presentViewController:alert animated:YES completion:nil];
        });
        [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
    }];
}

- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    return @[];
}

@end

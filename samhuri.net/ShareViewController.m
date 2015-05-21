//
//  ShareViewController.m
//  samhuri.net
//
//  Created by Sami Samhuri on 2015-05-05.
//  Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//
#import <PromiseKit/PromiseKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "ShareViewController.h"
#import "SamhuriNet.h"
#import "BlogController.h"
#import "Post.h"
#import "SharedContent.h"
#import "ExtensionItemProcessor.h"

@interface ShareViewController ()
@property(nonatomic, strong) SharedContent *content;
@end

@implementation ShareViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self findSharedContent].then(^(SharedContent *content) {
        self.textView.text = content.text;
        self.content = content;
    }).catch(^(NSError *error) {
        [self displayError:error];
        [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
    });
}

- (PMKPromise *)findSharedContent {
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *provider in item.attachments) {
            if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypePropertyList]) {
                return [[ExtensionItemProcessor new] sharedContentForPListItem:item];
            }
            if ([provider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
                return [[ExtensionItemProcessor new] sharedContentForURLItem:item text:self.contentText];
            }
        }
    }
    NSDictionary *info = @{NSLocalizedDescriptionKey: @"Cannot find PList or URL extension item to share."};
    return [PMKPromise promiseWithValue:[NSError errorWithDomain:@"SharedViewControllerDomain" code:1 userInfo:info]];
}

- (BOOL)isContentValid {
    return self.textView.text.length > 0;
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
    BOOL reallyPost = YES;
    if (reallyPost) {
        Post *post = [Post newDraftWithTitle:title body:body url:self.content.url];
        [blogController requestCreateDraft:post publishImmediatelyToEnvironment:@"production" waitForCompilation:NO].catch(^(NSError *error) {
            [self displayError:error];
        });
    }
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

- (NSArray *)configurationItems {
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    return @[];
}

- (void)displayError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

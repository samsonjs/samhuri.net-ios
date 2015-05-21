//
// Created by Sami Samhuri on 15-05-20.
// Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//
#import <PromiseKit/Promise.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "ExtensionItemProcessor.h"
#import "SharedContent.h"
#import "NSString+marshmallows.h"

@implementation ExtensionItemProcessor

- (PMKPromise *)sharedContentForPListItem:(NSExtensionItem *)item {
    return [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        NSItemProvider *provider = [self providerForIdentifier:(NSString *)kUTTypePropertyList fromExtensionItem:item];
        if (!provider) {
            reject([NSError errorWithDomain:@"ShareViewControllerDomain" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Cannot find PList provider"}]);
            return;
        }
        [provider loadItemForTypeIdentifier:(NSString *)kUTTypePropertyList options:nil completionHandler:^(NSDictionary *stuff, NSError *error) {
            NSDictionary *results = stuff[NSExtensionJavaScriptPreprocessingResultsKey];
            NSURL *url = [NSURL URLWithString:results[@"url"]];
            NSString *quotedText = [results[@"selectedText"] mm_stringByTrimmingWhitespace];
            NSString *quote = quotedText.length ? @"> " : @"";
            NSString *text = [NSString stringWithFormat:@"%@\n\n%@%@", results[@"title"], quote, quotedText];
            fulfill([SharedContent contentWithURL:url text:text]);
        }];
    }];
}

- (PMKPromise *)sharedContentForURLItem:(NSExtensionItem *)item text:(NSString *)text {
    return [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        NSItemProvider *provider = [self providerForIdentifier:(NSString *)kUTTypeURL fromExtensionItem:item];
        if (!provider) {
            reject([NSError errorWithDomain:@"ShareViewControllerDomain" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Cannot find URL provider"}]);
            return;
        }
        [provider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *url, NSError *error) {
            // TODO: fetch title?
            fulfill([SharedContent contentWithURL:url text:text]);
        }];
    }];
}

- (NSItemProvider *)providerForIdentifier:(NSString *)identifier fromExtensionItem:(NSExtensionItem *)item {
    for (NSItemProvider *provider in item.attachments) {
        if ([provider hasItemConformingToTypeIdentifier:identifier]) {
            return provider;
        }
    }
    return nil;
}

@end

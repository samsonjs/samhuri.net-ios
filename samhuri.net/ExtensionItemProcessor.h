//
// Created by Sami Samhuri on 15-05-20.
// Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//
@import Foundation;

@class PMKPromise;

@interface ExtensionItemProcessor : NSObject

- (PMKPromise *)sharedContentForPListItem:(NSExtensionItem *)item;
- (PMKPromise *)sharedContentForURLItem:(NSExtensionItem *)item text:(NSString *)text;

@end

//
//  BlogService.h
//  Blog
//
//  Created by Sami Samhuri on 2014-11-23.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

@import Foundation;
#import <PromiseKit/PromiseKit.h>

extern NSString * const BlogServiceErrorDomain;

typedef NS_ENUM(NSUInteger, BlogServiceErrorCode) {
    BlogServiceErrorCodeWTF
};

@class JSONHTTPClient;

@interface BlogService : NSObject

- (instancetype)initWithRootURL:(NSString *)rootURL client:(JSONHTTPClient *)client;

- (NSURL *)previewURLForPostWithPath:(NSString *)path;

- (PMKPromise *)requestBlogStatus;
- (PMKPromise *)requestPublishEnvironment:(NSString *)environment;

- (PMKPromise *)requestDrafts;
- (PMKPromise *)requestPublishedPosts;
- (PMKPromise *)requestPostWithPath:(NSString *)path;

- (PMKPromise *)requestCreateDraftWithID:(NSString *)draftID title:(NSString *)title body:(NSString *)body link:(NSString *)link;
- (PMKPromise *)requestUpdatePostWithPath:(NSString *)path title:(NSString *)title body:(NSString *)body link:(NSString *)link;
- (PMKPromise *)requestPublishDraftWithPath:(NSString *)path;
- (PMKPromise *)requestUnpublishPostWithPath:(NSString *)path;
- (PMKPromise *)requestDeletePostWithPath:(NSString *)path;

@end

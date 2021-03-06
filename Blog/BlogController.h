//
//  BlogController.h
//  Blog
//
//  Created by Sami Samhuri on 2014-11-27.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

@import Foundation;

@class PMKPromise;
@class ModelStore;
@class BlogService;
@class Post;

@interface BlogController : NSObject

- (instancetype)initWithService:(BlogService *)service store:(ModelStore *)store;

- (NSMutableURLRequest *)previewRequestWithPath:(NSString *)path;

- (PMKPromise *)requestBlogStatusWithCaching:(BOOL)useCache;

- (PMKPromise *)requestDraftsWithCaching:(BOOL)useCache;

- (PMKPromise *)requestPublishedPostsWithCaching:(BOOL)useCache;
- (PMKPromise *)requestAllPostsWithCaching:(BOOL)useCache;
- (PMKPromise *)requestPostWithPath:(NSString *)path;

- (PMKPromise *)requestCreateDraft:(Post *)draft publishImmediatelyToEnvironment:(NSString *)env waitForCompilation:(BOOL)waitForCompilation;
- (PMKPromise *)requestUpdatePost:(Post *)post waitForCompilation:(BOOL)waitForCompilation;
- (PMKPromise *)requestPublishDraft:(Post *)draft;
- (PMKPromise *)requestUnpublishPost:(Post *)publishedPost;
- (PMKPromise *)requestDeletePost:(Post *)post;

- (PMKPromise *)requestSync;
- (PMKPromise *)requestPublishToStagingEnvironment;
- (PMKPromise *)requestPublishToProductionEnvironment;

@end

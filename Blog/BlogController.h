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

- (PMKPromise *)requestCreateDraft:(Post *)draft publishImmediately:(BOOL)publish;
- (PMKPromise *)requestUpdatePost:(Post *)post;
- (PMKPromise *)requestPublishDraft:(Post *)post;
- (PMKPromise *)requestUnpublishPost:(Post *)post;
- (PMKPromise *)requestDeletePost:(Post *)post;

- (PMKPromise *)requestPublishToStagingEnvironment;
- (PMKPromise *)requestPublishToProductionEnvironment;

@end

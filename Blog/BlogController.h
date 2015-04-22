//
//  BlogController.h
//  Blog
//
//  Created by Sami Samhuri on 2014-11-27.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

@import Foundation;

extern NSString *BlogStatusChangedNotification;
extern NSString *BlogDraftsChangedNotification;
extern NSString *BlogDraftAddedNotification;
extern NSString *BlogDraftRemovedNotification;
extern NSString *BlogPublishedPostsChangedNotification;
extern NSString *BlogPublishedPostAddedNotification;
extern NSString *BlogPublishedPostRemovedNotification;
extern NSString *BlogPostChangedNotification;
extern NSString *BlogPostDeletedNotification;

@class PMKPromise;
@class ModelStore;
@class BlogService;

@interface BlogController : NSObject

- (instancetype)initWithService:(BlogService *)service store:(ModelStore *)store;

- (NSMutableURLRequest *)previewRequestWithPath:(NSString *)path;

- (PMKPromise *)requestBlogStatusWithCaching:(BOOL)useCache;

- (PMKPromise *)requestDraftsWithCaching:(BOOL)useCache;

- (PMKPromise *)requestPublishedPostsWithCaching:(BOOL)useCache;
- (PMKPromise *)requestAllPostsWithCaching:(BOOL)useCache;
- (PMKPromise *)requestPostWithPath:(NSString *)path;

- (PMKPromise *)requestCreateDraftWithID:(NSString *)draftID title:(NSString *)title body:(NSString *)body link:(NSString *)link;
- (PMKPromise *)requestUpdatePostWithPath:(NSString *)path title:(NSString *)title body:(NSString *)body link:(NSString *)link;
- (PMKPromise *)requestPublishDraftWithPath:(NSString *)path;
- (PMKPromise *)requestUnpublishPostWithPath:(NSString *)path;
- (PMKPromise *)requestDeletePostWithPath:(NSString *)path;

@end

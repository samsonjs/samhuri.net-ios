//
//  BlogController.h
//  Blog
//
//  Created by Sami Samhuri on 2014-11-27.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

@import Foundation;

NSString *BlogStatusChangedNotification;
NSString *BlogDraftsChangedNotification;
NSString *BlogDraftAddedNotification;
NSString *BlogDraftRemovedNotification;
NSString *BlogPublishedPostsChangedNotification;
NSString *BlogPublishedPostAddedNotification;
NSString *BlogPublishedPostRemovedNotification;
NSString *BlogPostChangedNotification;
NSString *BlogPostDeletedNotification;

@class PMKPromise;
@class ModelStore;
@class BlogService;

@interface BlogController : NSObject

- (instancetype)initWithService:(BlogService *)service store:(ModelStore *)store;

- (NSURL *)previewURLForPostWithPath:(NSString *)path;

- (PMKPromise *)requestBlogStatus;

- (PMKPromise *)requestDrafts;
- (PMKPromise *)requestPublishedPosts;
- (PMKPromise *)requestPostWithPath:(NSString *)path;

- (PMKPromise *)requestCreateDraftWithID:(NSString *)draftID title:(NSString *)title body:(NSString *)body link:(NSString *)link;
- (PMKPromise *)requestUpdatePostWithPath:(NSString *)path title:(NSString *)title body:(NSString *)body link:(NSString *)link;
- (PMKPromise *)requestPublishDraftWithPath:(NSString *)path;
- (PMKPromise *)requestUnpublishPostWithPath:(NSString *)path;
- (PMKPromise *)requestDeletePostWithPath:(NSString *)path;

@end

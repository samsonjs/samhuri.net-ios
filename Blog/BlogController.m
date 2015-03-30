//
//  BlogController.m
//  Blog
//
//  Created by Sami Samhuri on 2014-11-27.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

#import "BlogController.h"
#import <PromiseKit/PromiseKit.h>
#import "BlogService.h"
#import "ModelStore.h"
#import "BlogStatus.h"
#import "Post.h"

NSString *BlogStatusChangedNotification = @"BlogStatusChangedNotification";
NSString *BlogDraftsChangedNotification = @"BlogDraftsChangedNotification";
NSString *BlogDraftAddedNotification = @"BlogDraftAddedNotification";
NSString *BlogDraftRemovedNotification = @"BlogDraftRemovedNotification";
NSString *BlogPublishedPostsChangedNotification = @"BlogPublishedPostsChangedNotification";
NSString *BlogPublishedPostAddedNotification = @"BlogPostAddedNotification";
NSString *BlogPublishedPostRemovedNotification = @"BlogPostRemovedNotification";
NSString *BlogPostChangedNotification = @"BlogPostChangedNotification";
NSString *BlogPostDeletedNotification = @"BlogPostDeletedNotification";

@implementation BlogController {
    BlogService *_service;
    ModelStore *_store;
}

- (instancetype)initWithService:(BlogService *)service store:(ModelStore *)store {
    self = [super init];
    _service = service;
    _store = store;
    return self;
}

- (NSURL *)previewURLForPostWithPath:(NSString *)path {
    return [_service previewURLForPostWithPath:path];
}

- (PMKPromise *)requestBlogStatus {
    BlogStatus *status = [_store blogStatus];
    if (status) {
        return [PMKPromise promiseWithValue:status];
    }
    else {
        return [_service requestBlogStatus].then(^(BlogStatus *status) {
            [_store saveBlogStatus:status];
            return status;
        });
    }
}

- (PMKPromise *)requestDrafts {
    NSArray *posts = [_store drafts];
    if (posts) {
        return [PMKPromise promiseWithValue:posts];
    }
    else {
        return [_service requestDrafts].then(^(NSArray *posts) {
            [_store saveDrafts:posts];
            return posts;
        });
    }
}

- (PMKPromise *)requestPublishedPosts {
    NSArray *posts = [_store publishedPosts];
    if (posts) {
        return [PMKPromise promiseWithValue:posts];
    }
    else {
        return [_service requestPublishedPosts].then(^(NSArray *posts) {
            [_store savePublishedPosts:posts];
            return posts;
        });
    }
}

- (PMKPromise *)requestPostWithPath:(NSString *)path {
    Post *post = [_store postWithPath:path];
    if (post) {
        return [PMKPromise promiseWithValue:post];
    }
    else {
        return [_service requestPostWithPath:path].then(^(Post *post) {
            [_store savePost:post];
            return post;
        });
    }
}

- (PMKPromise *)requestCreateDraftWithID:(NSString *)draftID title:(NSString *)title body:(NSString *)body link:(NSString *)link {
    Post *post = [[Post alloc] initWithDictionary:@{@"objectID": draftID ?: [NSNull null],
                                                    @"title": title ?: [NSNull null],
                                                    @"body": body ?: [NSNull null],
                                                    @"link": link ?: [NSNull null],
                                                    @"draft": @YES,
                                                    } error:nil];
    return [_service requestCreateDraftWithID:draftID title:title body:body link:link].then(^(Post *post) {
        [_store addDraft:post];
        return post;
    });
}

- (PMKPromise *)requestUpdatePostWithPath:(NSString *)path title:(NSString *)title body:(NSString *)body link:(NSString *)link {
    return [_service requestUpdatePostWithPath:path title:title body:body link:link].then(^(Post *post) {
        [_store savePost:post];
        return post;
    });
}

- (PMKPromise *)requestPublishDraftWithPath:(NSString *)path {
    return [_service requestPublishDraftWithPath:path].then(^(Post *post) {
        [_store removeDraftWithPath:path];
        [_store addPublishedPost:post];
        return post;
    });
}

- (PMKPromise *)requestUnpublishPostWithPath:(NSString *)path {
    return [_service requestUnpublishPostWithPath:path].then(^(Post *post) {
        [_store removePostWithPath:path];
        [_store addDraft:post];
        return post;
    });
}

- (PMKPromise *)requestDeletePostWithPath:(NSString *)path {
    return [_service requestDeletePostWithPath:path].then(^(id _) {
        [_store removePostWithPath:path];
        [_store removeDraftWithPath:path];
        return _;
    });
}

@end

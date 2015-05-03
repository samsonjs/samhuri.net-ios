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

- (NSMutableURLRequest *)previewRequestWithPath:(NSString *)path {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[_service urlFor:path]];
    [request addValue:@"text/html" forHTTPHeaderField:@"Accept"];
    return request;
}

- (PMKPromise *)requestBlogStatusWithCaching:(BOOL)useCache {
    BlogStatus *status = useCache ? [_store blogStatus] : nil;
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

- (PMKPromise *)requestDraftsWithCaching:(BOOL)useCache {
    NSArray *posts = useCache ? [_store drafts] : nil;
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

- (PMKPromise *)requestPublishedPostsWithCaching:(BOOL)useCache {
    NSArray *posts = useCache ? [_store publishedPosts] : nil;
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

- (PMKPromise *)requestAllPostsWithCaching:(BOOL)useCache {
    return [PMKPromise when:@[[self requestDraftsWithCaching:useCache], [self requestPublishedPostsWithCaching:useCache]]];
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

- (PMKPromise *)requestCreateDraft:(Post *)draft {
    return [_service requestCreateDraftWithID:draft.objectID title:draft.title body:draft.body
                                         link:draft.url.absoluteString].then(^(Post *post) {
        [_store addDraft:post];
        return post;
    });
}

- (PMKPromise *)requestUpdatePost:(Post *)post {
    return [_service requestUpdatePostWithPath:post.path title:post.title body:post.body link:post.url.absoluteString]
            .then(^{
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

- (PMKPromise *)requestPublishToStagingEnvironment {
    return [_service requestPublishEnvironment:@"staging"];
}

- (PMKPromise *)requestPublishToProductionEnvironment {
    return [_service requestPublishEnvironment:@"production"];
}

@end

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

- (PMKPromise *)requestCreateDraft:(Post *)draft publishImmediately:(BOOL)publish waitForCompilation:(BOOL)waitForCompilation {
    return [_service requestCreateDraftWithID:draft.objectID title:draft.title body:draft.body link:draft.url.absoluteString publish:publish waitForCompilation:waitForCompilation].then(^(Post *post) {
        [_store addDraft:post];
        return post;
    });
}

- (PMKPromise *)requestUpdatePost:(Post *)post waitForCompilation:(BOOL)waitForCompilation {
    return [_service requestUpdatePostWithPath:post.path title:post.title body:post.body link:post.url.absoluteString waitForCompilation:NO]
            .then(^{
                [_store savePost:post];
                return post;
            });
}

- (PMKPromise *)requestPublishDraft:(Post *)post {
    return [_service requestPublishDraftWithPath:post.path].then(^(Post *post) {
        [_store removeDraft:post];
        [_store addPublishedPost:post];
        return post;
    });
}

- (PMKPromise *)requestUnpublishPost:(Post *)post {
    return [_service requestUnpublishPostWithPath:post.path].then(^(Post *post) {
        [_store removePost:post];
        [_store addDraft:post];
        return post;
    });
}

- (PMKPromise *)requestDeletePost:(Post *)post {
    return [_service requestDeletePostWithPath:post.path].then(^(id _) {
        [_store removePost:post];
        [_store removeDraft:post];
        return _;
    });
}

- (PMKPromise *)requestSync {
    return [_service requestSync];
}

- (PMKPromise *)requestPublishToStagingEnvironment {
    return [_service requestPublishEnvironment:@"staging"];
}

- (PMKPromise *)requestPublishToProductionEnvironment {
    return [_service requestPublishEnvironment:@"production"];
}

@end

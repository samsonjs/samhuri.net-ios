//
//  ModelStore.m
//  Blog
//
//  Created by Sami Samhuri on 2014-11-26.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

#import "ModelStore.h"
#import <PromiseKit/PromiseKit.h>
#import <YapDatabase/YapDatabase.h>
#import "BlogStatus.h"
#import "Post.h"
#import "NSArray+ObjectiveSugar.h"

NSString *const PostUpdatedNotification = @"PostUpdatedNotification";
NSString *const DraftRemovedNotification = @"DraftRemovedNotification";
NSString *const DraftAddedNotification = @"DraftAddedNotification";
NSString *const PublishedPostAddedNotification = @"PublishedPostAddedNotification";
NSString *const PublishedPostRemovedNotification = @"PublishedPostRemovedNotification";
NSString *const PostUserInfoKey = @"PostUserInfoKey";
NSString *const PostPathUserInfoKey = @"PostPathUserInfoKey";

@implementation ModelStore {
    YapDatabaseConnection *_connection;
}

- (instancetype)initWithConnection:(YapDatabaseConnection *)connection {
    self = [super init];
    _connection = connection;
    return self;
}

- (BlogStatus *)blogStatus {
    __block BlogStatus *status = nil;
    __block NSDictionary *metadata = nil;
    [_connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction getObject:&status metadata:&metadata forKey:@"status" inCollection:@"BlogStatus"];
        if (status && metadata) {
            NSNumber *timestamp = metadata[@"timestamp"];
            NSTimeInterval age = [NSDate date].timeIntervalSince1970 - [timestamp unsignedIntegerValue];
            if (age > 300) {
                NSLog(@"Blog status is stale (%@s old)", @(age));
                status = nil;
            }
        }
    }];
    return status;
}

- (PMKPromise *)saveBlogStatus:(BlogStatus *)blogStatus {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [_connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [transaction setObject:blogStatus forKey:@"status" inCollection:@"BlogStatus" withMetadata:@{@"timestamp" : @([NSDate date].timeIntervalSince1970)}];
        } completionBlock:^{
            fulfill(blogStatus);
        }];
    }];
}

- (void)postPostUpdatedNotificationForPost:(Post *)post {
    NSDictionary *info = @{PostPathUserInfoKey : post.path, PostUserInfoKey : post};
    [[NSNotificationCenter defaultCenter] postNotificationName:PostUpdatedNotification object:self userInfo:info];
}

- (Post *)postWithPath:(NSString *)path {
    __block Post *post = nil;
    [_connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        post = [transaction objectForKey:path inCollection:@"Post"];
    }];
    return post;
}

- (PMKPromise *)savePost:(Post *)post {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [_connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [transaction setObject:post forKey:post.path inCollection:@"Post"];
        } completionBlock:^{
            [self postPostUpdatedNotificationForPost:post];
            fulfill(post);
        }];
    }];
}

- (NSArray *)drafts {
    __block NSMutableArray *posts = nil;
    [_connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        NSArray *postPaths = [transaction objectForKey:@"drafts" inCollection:@"PostCollection"];
        if (postPaths) {
            [transaction enumerateObjectsForKeys:postPaths inCollection:@"Post" unorderedUsingBlock:^(NSUInteger keyIndex, id object, BOOL *stop) {
                if (object) {
                    if (!posts) {
                        posts = [NSMutableArray new];
                    }
                    [posts addObject:object];
                }
            }];
        }
    }];
    return posts;
}

- (PMKPromise *)saveDrafts:(NSArray *)posts {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [_connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            NSMutableArray *postPaths = [NSMutableArray array];
            for (Post *post in posts) {
                [transaction setObject:post forKey:post.path inCollection:@"Post"];
                [postPaths addObject:post.path];
            }
            [transaction setObject:postPaths forKey:@"drafts" inCollection:@"PostCollection"];
        } completionBlock:^{
            fulfill(posts);
        }];
    }];
}

- (PMKPromise *)addDraft:(Post *)post {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [_connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [transaction setObject:post forKey:post.path inCollection:@"Post"];
            NSMutableArray *postPaths = [[transaction objectForKey:@"drafts" inCollection:@"PostCollection"] mutableCopy];
            if (![postPaths containsObject:post.path]) {
                [postPaths addObject:post.path];
                [transaction setObject:postPaths forKey:@"drafts" inCollection:@"PostCollection"];
            }
        } completionBlock:^{
            NSDictionary *info = @{PostPathUserInfoKey : post.path, PostUserInfoKey : post};
            [[NSNotificationCenter defaultCenter] postNotificationName:DraftAddedNotification object:self userInfo:info];
            fulfill(post);
        }];
    }];
}

- (PMKPromise *)removeDraft:(Post *)post {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [_connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            NSMutableArray *postPaths = [[transaction objectForKey:@"drafts" inCollection:@"PostCollection"] mutableCopy];
            if ([postPaths containsObject:post.path]) {
                [postPaths removeObject:post.path];
                [transaction setObject:postPaths forKey:@"drafts" inCollection:@"PostCollection"];
            }
        } completionBlock:^{
            NSDictionary *info = @{PostPathUserInfoKey : post.path, PostUserInfoKey : post};
            [[NSNotificationCenter defaultCenter] postNotificationName:DraftRemovedNotification object:self userInfo:info];
            fulfill(post);
        }];
    }];
}

- (NSArray *)publishedPosts {
    __block NSArray *posts = nil;
    [_connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        NSArray *postPaths = [transaction objectForKey:@"published" inCollection:@"PostCollection"];
        NSMutableDictionary *postsByPath = [NSMutableDictionary dictionaryWithCapacity:postPaths.count];
        if (postPaths) {
            [transaction enumerateObjectsForKeys:postPaths inCollection:@"Post" unorderedUsingBlock:^(NSUInteger keyIndex, Post *post, BOOL *stop) {
                if (post) {
                    postsByPath[post.path] = post;
                }
            }];
            posts = [postPaths map:^id(NSString *path) {
                return postsByPath[path];
            }];
        }
    }];
    return posts.count ? posts : nil;
}

- (PMKPromise *)savePublishedPosts:(NSArray *)posts {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [_connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            NSMutableArray *postPaths = [NSMutableArray array];
            for (Post *post in posts) {
                [transaction setObject:post forKey:post.path inCollection:@"Post"];
                [postPaths addObject:post.path];
            }
            [transaction setObject:postPaths forKey:@"published" inCollection:@"PostCollection"];
        } completionBlock:^{
            fulfill(posts);
        }];
    }];
}

- (PMKPromise *)addPublishedPost:(Post *)post {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [_connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [transaction setObject:post forKey:post.path inCollection:@"Post"];
            NSMutableArray *postPaths = [[transaction objectForKey:@"published" inCollection:@"PostCollection"] mutableCopy];
            if (![postPaths containsObject:post.path]) {
                [postPaths addObject:post.path];
                [transaction setObject:postPaths forKey:@"published" inCollection:@"PostCollection"];
            }
        } completionBlock:^{
            NSDictionary *info = @{PostPathUserInfoKey : post.path, PostUserInfoKey : post};
            [[NSNotificationCenter defaultCenter] postNotificationName:PublishedPostAddedNotification object:self userInfo:info];
            fulfill(post);
        }];
    }];
}

- (PMKPromise *)removePost:(Post *)post {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [_connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            NSMutableArray *postPaths = [[transaction objectForKey:@"published" inCollection:@"PostCollection"] mutableCopy];
            if ([postPaths containsObject:post.path]) {
                [postPaths removeObject:post.path];
                [transaction setObject:postPaths forKey:@"published" inCollection:@"PostCollection"];
            }
        } completionBlock:^{
            NSDictionary *info = @{PostPathUserInfoKey : post.path, PostUserInfoKey : post};
            [[NSNotificationCenter defaultCenter] postNotificationName:PublishedPostRemovedNotification object:self userInfo:info];
            fulfill(post);
        }];
    }];
}

@end

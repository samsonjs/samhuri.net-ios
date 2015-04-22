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
            [transaction setObject:blogStatus forKey:@"status" inCollection:@"BlogStatus" withMetadata:@{@"timestamp": @([NSDate date].timeIntervalSince1970)}];
        } completionBlock:^{
            fulfill(blogStatus);
        }];
    }];
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
            NSMutableArray *postIDs = [NSMutableArray array];
            for (Post *post in posts) {
                [transaction setObject:post forKey:post.path inCollection:@"Post"];
                [postIDs addObject:post.path];
            }
            [transaction setObject:postIDs forKey:@"drafts" inCollection:@"PostCollection"];
        } completionBlock:^{
            fulfill(posts);
        }];
    }];
}

- (PMKPromise *)addDraft:(Post *)post {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [_connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [transaction setObject:post forKey:post.path inCollection:@"Post"];
            NSMutableArray *postIDs = [[transaction objectForKey:@"drafts" inCollection:@"PostCollection"] mutableCopy];
            if (![postIDs containsObject:post.path]) {
                [postIDs addObject:post.path];
                [transaction setObject:postIDs forKey:@"drafts" inCollection:@"PostCollection"];
            }
        } completionBlock:^{
            fulfill(post);
        }];
    }];
}

- (PMKPromise *)removeDraftWithPath:(NSString *)path {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [_connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            NSMutableArray *postIDs = [[transaction objectForKey:@"drafts" inCollection:@"PostCollection"] mutableCopy];
            if ([postIDs containsObject:path]) {
                [postIDs removeObject:path];
                [transaction setObject:postIDs forKey:@"drafts" inCollection:@"PostCollection"];
            }
        } completionBlock:^{
            fulfill(path);
        }];
    }];
}

- (NSArray *)publishedPosts {
    __block NSMutableArray *posts = nil;
    [_connection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        NSArray *postPaths = [transaction objectForKey:@"published" inCollection:@"PostCollection"];
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

- (PMKPromise *)savePublishedPosts:(NSArray *)posts {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [_connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            NSMutableArray *postIDs = [NSMutableArray array];
            for (Post *post in posts) {
                [transaction setObject:post forKey:post.path inCollection:@"Post"];
                [postIDs addObject:post.path];
            }
            [transaction setObject:postIDs forKey:@"published" inCollection:@"PostCollection"];
        } completionBlock:^{
            fulfill(posts);
        }];
    }];
}

- (PMKPromise *)addPublishedPost:(Post *)post {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [_connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [transaction setObject:post forKey:post.path inCollection:@"Post"];
            NSMutableArray *postIDs = [[transaction objectForKey:@"published" inCollection:@"PostCollection"] mutableCopy];
            if (![postIDs containsObject:post.path]) {
                [postIDs addObject:post.path];
                [transaction setObject:postIDs forKey:@"published" inCollection:@"PostCollection"];
            }
        } completionBlock:^{
            fulfill(post);
        }];
    }];
}

- (PMKPromise *)removePostWithPath:(NSString *)path {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [_connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            NSMutableArray *postIDs = [[transaction objectForKey:@"published" inCollection:@"PostCollection"] mutableCopy];
            if ([postIDs containsObject:path]) {
                [postIDs removeObject:path];
                [transaction setObject:postIDs forKey:@"published" inCollection:@"PostCollection"];
            }
        } completionBlock:^{
            fulfill(path);
        }];
    }];
}

@end

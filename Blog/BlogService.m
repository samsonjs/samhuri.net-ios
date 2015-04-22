//
//  BlogService.m
//  Blog
//
//  Created by Sami Samhuri on 2014-11-23.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

#import "BlogService.h"
#import <Mantle/MTLJSONAdapter.h>
#import "NSString+marshmallows.h"
#import "JSONHTTPClient.h"
#import "BlogStatus.h"
#import "Post.h"

NSString *const BlogServiceErrorDomain = @"BlogServiceErrorDomain";

@interface BlogService ()

@property (nonatomic, readonly, strong) NSString *rootURL;
@property (nonatomic, readonly, strong) JSONHTTPClient *client;

@end

@implementation BlogService

- (instancetype)initWithRootURL:(NSString *)rootURL client:(JSONHTTPClient *)client {
    NSParameterAssert([rootURL length]);
    NSParameterAssert(client);
    self = [super init];
    _rootURL = [rootURL mm_stringByReplacing:@"/$" with:@""];
    _client = client;
    return self;
}

- (NSURL *)urlFor:(NSString *)path, ... {
    va_list args;
    va_start(args, path);
    path = [[NSString alloc] initWithFormat:path arguments:args];
    va_end(args);

    NSString *slash = [path hasPrefix:@"/"] ? @"" : @"/";
    NSString *urlString = [self.rootURL stringByAppendingFormat:@"%@%@", slash, path];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        @throw [NSException exceptionWithName:@"BlogServiceException" reason:@"Invalid URL" userInfo:@{@"URL": urlString ?: [NSNull null]}];
    }
    return url;
}

- (id (^)(NSDictionary *))decodePostBlock {
    return ^(NSDictionary *root) {
        NSError *error = nil;
        Post *post = [MTLJSONAdapter modelOfClass:[Post class] fromJSONDictionary:root[@"post"] error:&error];
        return post ?: error;
    };
}

- (id (^)(NSDictionary *))decodePostsBlock {
    return ^(NSDictionary *root) {
        NSError *error = nil;
        NSArray *posts = [MTLJSONAdapter modelsOfClass:[Post class] fromJSONArray:root[@"posts"] error:&error];
        return posts ?: error;
    };
}

- (PMKPromise *)requestBlogStatus {
    return [self.client get:[self urlFor:@"/status"] headers:nil].then(^(NSDictionary *root) {
        NSError *error = nil;
        BlogStatus *status = [MTLJSONAdapter modelOfClass:[BlogStatus class] fromJSONDictionary:root[@"status"] error:&error];
        return status ?: error;
    });
}

- (PMKPromise *)requestPublishEnvironment:(NSString *)environment {
    NSDictionary *fields = @{@"env": environment ?: @"staging"};
    return [self.client postJSON:[self urlFor:@"/publish"] headers:nil fields:fields];
}

- (PMKPromise *)requestDrafts {
    return [self.client get:[self urlFor:@"/posts/drafts"] headers:nil].then([self decodePostsBlock]);
}

- (PMKPromise *)requestPublishedPosts {
    return [self.client get:[self urlFor:@"/posts"] headers:nil].then([self decodePostsBlock]);
}

- (PMKPromise *)requestPostWithPath:(NSString *)path {
    return [self.client get:[self urlFor:path] headers:nil].then([self decodePostBlock]);
}

- (PMKPromise *)requestCreateDraftWithID:(NSString *)draftID title:(NSString *)title body:(NSString *)body link:(NSString *)link {
    NSDictionary *fields = @{
            @"id"    : draftID,
            @"title" : title,
            @"body"  : body,
            @"link"  : link ?: [NSNull null],
    };
    return [self.client postJSON:[self urlFor:@"/posts/drafts"] headers:nil fields:fields].then([self decodePostBlock]);
}

- (PMKPromise *)requestPublishDraftWithPath:(NSString *)path {
    return [self.client post:[self urlFor:@"%@/publish", path] headers:nil].then([self decodePostBlock]);
}

- (PMKPromise *)requestUnpublishPostWithPath:(NSString *)path {
    return [self.client post:[self urlFor:@"%@/unpublish", path] headers:nil];
}

- (PMKPromise *)requestUpdatePostWithPath:(NSString *)path title:(NSString *)title body:(NSString *)body link:(NSString *)link {
    NSDictionary *fields = @{
            @"title" : title,
            @"body"  : body,
            @"link"  : link ?: [NSNull null],
    };
    return [self.client putJSON:[self urlFor:path] headers:nil fields:fields];
}

- (PMKPromise *)requestDeletePostWithPath:(NSString *)path {
    return [self.client delete:[self urlFor:path] headers:nil];
}

@end

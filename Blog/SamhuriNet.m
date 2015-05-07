//
//  SamhuriNet.m
//  Blog
//
//  Created by Sami Samhuri on 2015-05-05.
//  Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//

#import "SamhuriNet.h"
#import <YapDatabase/YapDatabase.h>
#import "ModelStore.h"
#import "JSONHTTPClient.h"
#import "BlogService.h"
#import "BlogController.h"

@implementation SamhuriNet

@synthesize blogController = _blogController;

- (NSString *)authPath {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *authPath = [bundle pathForResource:@"auth.json" ofType:nil];
    return authPath;
}

- (NSDictionary *)auth {
    NSString *authPath = [self authPath];
    if (authPath.length) {
        NSData *data = [NSData dataWithContentsOfFile:authPath];
        NSError *error = nil;
        NSDictionary *auth = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (auth) {
            return auth;
        }
        NSLog(@"auth.json: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        NSLog(@"[ERROR] Failed to parse auth.json: %@ %@", error.localizedDescription, error.userInfo);
        return nil;
    }
    return nil;
}

- (NSDictionary *)defaultBlogHeaders {
    NSDictionary *auth = [self auth];
    if (auth) {
        return @{@"Auth" : [NSString stringWithFormat:@"%@|%@", auth[@"username"], auth[@"password"]]};
    }
    NSLog(@"[WARNING] Failed configure authentication. Blog will be read-only.");
    return nil;
}

- (JSONHTTPClient *)newJSONHTTPClientWithSession:(NSURLSession *)session {
    JSONHTTPClient *client = [[JSONHTTPClient alloc] initWithSession:session];
    client.defaultHeaders = [self defaultBlogHeaders];
    return client;
}

- (ModelStore *)newModelStoreWithDatabasePath:(NSString *)dbPath {
    YapDatabase *database = [[YapDatabase alloc] initWithPath:dbPath];
    YapDatabaseConnection *connection = [database newConnection];
    ModelStore *store = [[ModelStore alloc] initWithConnection:connection];
    return store;
}

- (BlogController *)newBlogControllerWithDatabasePath:(NSString *)dbPath session:(NSURLSession *)session rootURL:(NSString *)rootURL {
    ModelStore *store = [self newModelStoreWithDatabasePath:dbPath];
    BlogService *service = [[BlogService alloc] initWithRootURL:rootURL client:[self newJSONHTTPClientWithSession:session]];
    BlogController *blogController = [[BlogController alloc] initWithService:service store:store];
    return blogController;
}

- (NSURLSession *)newURLSession {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    return session;
}

- (NSString *)dbPath {
    NSString *cachesPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
    NSString *dbPath = [cachesPath stringByAppendingPathComponent:@"samhuri.net.sqlite"];
    return dbPath;
}

- (NSString *)rootURL {
    return @"http://ocean.samhuri.net:6706/";
}

- (BlogController *)blogController {
    if (!_blogController) {
        BlogController *blogController = [self newBlogControllerWithDatabasePath:[self dbPath] session:[self newURLSession] rootURL:[self rootURL]];
        _blogController = blogController;
    }
    return _blogController;
}

@end

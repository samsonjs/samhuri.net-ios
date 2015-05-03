//
//  JSONHTTPClient.m
//  Blog
//
//  Created by Sami Samhuri on 2014-11-23.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

#import "JSONHTTPClient.h"

NSString *const JSONHTTPClientErrorDomain = @"JSONHTTPClientErrorDomain";

@interface JSONHTTPClient ()

@property (nonatomic, readonly, strong) NSURLSession *session;

@end

@implementation JSONHTTPClient

- (instancetype)initWithSession:(NSURLSession *)session {
    self = [super init];
    _session = session;
    return self;
}

- (PMKPromise *)get:(NSURL *)url headers:(NSDictionary *)headers {
    return [self request:[self requestWithMethod:@"GET" URL:url headers:headers data:nil]];
}

- (PMKPromise *)putJSON:(NSURL *)url headers:(NSDictionary *)headers fields:(NSDictionary *)fields {
    return [self JSONRequestWithMethod:@"PUT" url:url headers:headers fields:fields];
}

- (PMKPromise *)postJSON:(NSURL *)url headers:(NSDictionary *)headers fields:(NSDictionary *)fields {
    return [self JSONRequestWithMethod:@"POST" url:url headers:headers fields:fields];
}

- (PMKPromise *)post:(NSURL *)url headers:(NSDictionary *)headers {
    return [self request:[self requestWithMethod:@"POST" URL:url headers:headers data:nil]];
}

- (PMKPromise *)delete:(NSURL *)url headers:(NSDictionary *)headers {
    return [self request:[self requestWithMethod:@"DELETE" URL:url headers:headers data:nil]];
}

- (PMKPromise *)request:(NSURLRequest *)request {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [[self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse *httpResponse = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;
            if (error) {
                reject(error);
            }
            else if (httpResponse) {
                NSDictionary *headers = [httpResponse allHeaderFields];
                NSString *type = headers[@"Content-Type"];
                if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
                    if ([type hasPrefix:@"application/json"]) {
                        NSError *jsonError = nil;
                        id root = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                        if (root)
                        {
                            fulfill(PMKManifold(root, headers, @(httpResponse.statusCode)));
                        }
                        else {
                            reject(jsonError);
                        }
                    }
                    else if ([data length] > 0) {
                        NSDictionary *info = @{NSLocalizedDescriptionKey: @"response type is not JSON",
                                               @"type": type ?: [NSNull null],
                                               @"length": headers[@"Content-Length"] ?: [NSNull null],
                                               @"request": request,
                                               @"response": httpResponse,
                                               };
                        NSError *error = [NSError errorWithDomain:JSONHTTPClientErrorDomain code:JSONHTTPClientErrorCodeInvalidResponse userInfo:info];
                        reject(error);
                    }
                    else {
                        fulfill(PMKManifold(nil, headers, @(httpResponse.statusCode)));
                    }
                }
                else {
                    NSDictionary *info = @{NSLocalizedDescriptionKey: @"HTTP request failed",
                                           @"status": @(httpResponse.statusCode),
                                           @"request": request,
                                           @"response": httpResponse,
                                           };
                    NSError *error = [NSError errorWithDomain:JSONHTTPClientErrorDomain code:JSONHTTPClientErrorCodeRequestFailed userInfo:info];
                    reject(error);
                }
            }
            else {
                NSDictionary *info = @{NSLocalizedDescriptionKey: @"response is not an HTTP response"};
                NSError *error = [NSError errorWithDomain:JSONHTTPClientErrorDomain code:JSONHTTPClientErrorCodeWTF userInfo:info];
                reject(error);
            }
        }] resume];
    }];
}

- (NSURLRequest *)requestWithMethod:(NSString *)method URL:(NSURL *)url headers:(NSDictionary *)headers data:(NSData *)data {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:method];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    for (NSString *key in [self.defaultHeaders allKeys]) {
        [request setValue:self.defaultHeaders[key] forHTTPHeaderField:key];
    }
    for (NSString *key in [headers allKeys]) {
        [request setValue:headers[key] forHTTPHeaderField:key];
    }
    if (data) {
        [request setValue:[NSString stringWithFormat:@"%@", @([data length])] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:data];
    }
    return request;
}

- (PMKPromise *)JSONRequestWithMethod:(NSString *)method url:(NSURL *)url headers:(NSDictionary *)headers fields:(NSDictionary *)fields {
    NSMutableDictionary *newHeaders = [headers ?: @{} mutableCopy];
    newHeaders[@"Content-Type"] = @"application/json";
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:fields options:0 error:&error];
    if (data) {
        return [self request:[self requestWithMethod:method URL:url headers:newHeaders data:data]];
    }
    else {
        NSLog(@"error: %@ %@", error, [error userInfo]);
        return [PMKPromise promiseWithValue:error];
    }
}

@end

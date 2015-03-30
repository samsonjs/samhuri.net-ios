//
//  JSONHTTPClient.h
//  Blog
//
//  Created by Sami Samhuri on 2014-11-23.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PromiseKit/PromiseKit.h>

extern NSString * const JSONHTTPClientErrorDomain;

typedef enum : NSUInteger {
    JSONHTTPClientErrorCodeWTF,
    JSONHTTPClientErrorCodeInvalidResponse,
    JSONHTTPClientErrorCodeRequestFailed
} JSONHTTPClientErrorCode;

@interface JSONHTTPClient : NSObject

@property (nonatomic, strong) NSDictionary *defaultHeaders;

- (instancetype)initWithSession:(NSURLSession *)session;

- (PMKPromise *)request:(NSURLRequest *)request;
- (PMKPromise *)get:(NSURL *)url headers:(NSDictionary *)headers;
- (PMKPromise *)putJSON:(NSURL *)url headers:(NSDictionary *)headers fields:(NSDictionary *)fields;
- (PMKPromise *)postJSON:(NSURL *)url headers:(NSDictionary *)headers fields:(NSDictionary *)fields;
- (PMKPromise *)post:(NSURL *)url headers:(NSDictionary *)headers;
- (PMKPromise *)delete:(NSURL *)url headers:(NSDictionary *)headers;

@end

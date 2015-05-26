//
//  Post.m
//  Blog
//
//  Created by Sami Samhuri on 2014-11-23.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

#import "Post.h"
#import "NSDate+marshmallows.h"
#import "NSString+marshmallows.h"
#import <Mantle/MTLValueTransformer.h>

@implementation Post

@synthesize objectID = _objectID;
@synthesize slug = _slug;
@synthesize author = _author;
@synthesize time = _time;
@synthesize path = _path;

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
            @"objectID"  : @"id",
            @"slug"      : @"slug",
            @"author"    : @"author",
            @"title"     : @"title",
            @"date"      : @"date",
            @"draft"     : @"draft",
            @"body"      : @"body",
            @"path"      : @"url",
            @"url"       : @"link",
            @"time"      : @"", // ignore
            @"timestamp" : @"timestamp",
    };
}

+ (NSValueTransformer *)urlJSONTransformer {
    return [MTLValueTransformer transformerUsingForwardBlock:^NSURL *(NSString *str, BOOL *success, NSError **error) {
        return [NSURL URLWithString:str];
    } reverseBlock:^NSString *(NSURL *url, BOOL *success, NSError **error) {
        return [url absoluteString];
    }];
}

+ (instancetype)newDraftWithTitle:(NSString *)title body:(NSString *)body url:(NSURL *)url {
    NSDictionary *fields = @{
            @"new"   : @(YES),
            @"draft" : @(YES),
            @"title" : title ?: @"",
            @"body"  : body ?: @"",
            @"url"   : url ?: [NSNull null],
    };
    return [[self alloc] initWithDictionary:fields error:nil];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)copyWithBody:(NSString *)body {
    return [self copyWithTitle:self.title body:body url:self.url new:self.new];
}

- (instancetype)copyWithTitle:(NSString *)title {
    return [self copyWithTitle:title body:self.body url:self.url new:self.new];
}

- (instancetype)copyWithURL:(NSURL *)url {
    return [self copyWithTitle:self.title body:self.body url:url new:self.new];
}

- (instancetype)copyWithNew:(BOOL)isNew {
    return [self copyWithTitle:self.title body:self.body url:self.url new:isNew];
}

- (instancetype)copyWithTitle:(NSString *)title body:(NSString *)body url:(NSURL *)url new:(BOOL)isNew {
    return [[Post alloc] initWithDictionary:@{
            @"objectID" : self.objectID ?: [NSNull null],
            @"slug"     : self.slug ?: [NSNull null],
            @"author"   : self.author ?: [NSNull null],
            @"title"    : title ?: [NSNull null],
            @"date"     : self.date ?: [NSNull null],
            @"body"     : body ?: [NSNull null],
            @"path"     : self.path ?: [NSNull null],
            @"url"      : url ?: [NSNull null],
            @"draft"    : @(self.draft),
            @"new"      : @(isNew),
    } error:nil];
}

- (BOOL)isEqualToPost:(Post *)other {
    return [self.objectID isEqualToString:other.objectID]
            && [self.path isEqualToString:other.path]
            && ((!self.title && !other.title) || [self.title isEqual:other.title])
            && ((!self.body && !other.body) || [self.body isEqual:other.body])
            && self.draft == other.draft
            && ((!self.url && !other.url) || [self.url isEqual:other.url]);
    // include "new" here too?
}

- (BOOL)isEqual:(id)object {
    return self == object || ([object isMemberOfClass:[Post class]] && [self isEqualToPost:object]);
}

- (NSUInteger)hash {
    return [(self.objectID ?: self.slug) hash];
}

- (NSString *)objectID {
    if (!_objectID && _draft) {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        CFStringRef uuidString = CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
        _objectID = (__bridge NSString *)uuidString;
    }
    return _objectID;
}

- (NSString *)author {
    if (!_author) {
        _author = @"Sami Samhuri";
    }
    return _author;
}

- (NSString *)slug {
    if (!_slug && !self.draft && self.title) {
        _slug = [[[[[self.title lowercaseString]
                mm_stringByReplacing:@"'" with:@""]
                mm_stringByReplacing:@"[^[:alpha:]\\d_]" with:@"-"]
                mm_stringByReplacing:@"^-+|-+$" with:@""]
                mm_stringByReplacing:@"-+" with:@"-"];
    }
    return _slug;
}

- (BOOL)isLink {
    return self.url != nil;
}

- (NSDate *)time {
    if (!_time && self.timestamp) {
        _time = [NSDate dateWithTimeIntervalSince1970:self.timestamp];
    }
    return _time;
}

- (NSString *)path {
    if (!_path) {
        if (self.draft) {
            _path = [NSString stringWithFormat:@"/posts/drafts/%@", self.objectID];
        }
        else {
            NSAssert(self.slug && self.date, @"slug and date are required");
            NSString *paddedMonth = [self paddedMonthForDate:self.time];
            _path = [NSString stringWithFormat:@"/posts/%ld/%@/%@", (long)self.time.mm_year, paddedMonth, self.slug];
        }
    }
    return _path;
}

- (NSString *)paddedMonthForDate:(NSDate *)date {
    return [NSString stringWithFormat:@"%02ld", (long)date.mm_month];
}

@end

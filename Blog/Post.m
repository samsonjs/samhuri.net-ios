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
@synthesize title = _title;
@synthesize date = _date;
@synthesize time = _time;
@synthesize body = _body;
@synthesize path = _path;
@synthesize url = _url;
@synthesize formattedDate = _formattedDate;

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{@"objectID": @"id",
             @"path": @"url",
             @"url": @"link",
             @"time": @"", // ignore
             };
}

+ (NSValueTransformer *)urlJSONTransformer {
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^NSURL *(NSString *str) {
        return [NSURL URLWithString:str];
    } reverseBlock:^NSString *(NSURL *url) {
        return [url absoluteString];
    }];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)copyWithBody:(NSString *)body {
    return [[Post alloc] initWithDictionary:@{@"objectID": self.objectID ?: [NSNull null],
                                              @"slug": self.slug ?: [NSNull null],
                                              @"author": self.author ?: [NSNull null],
                                              @"title": self.title ?: [NSNull null],
                                              @"date": self.date ?: [NSNull null],
                                              @"body": body ?: [NSNull null],
                                              @"path": self.path ?: [NSNull null],
                                              @"url": self.url ?: [NSNull null],
                                              } error:nil];
}

- (instancetype)copyWithTitle:(NSString *)title {
    return [[Post alloc] initWithDictionary:@{@"objectID": self.objectID ?: [NSNull null],
                                              @"slug": self.slug ?: [NSNull null],
                                              @"author": self.author ?: [NSNull null],
                                              @"title": title ?: [NSNull null],
                                              @"date": self.date ?: [NSNull null],
                                              @"body": self.body ?: [NSNull null],
                                              @"path": self.path ?: [NSNull null],
                                              @"url": self.url ?: [NSNull null],
                                              } error:nil];
}

- (instancetype)copyWithURL:(NSURL *)url {
    return [[Post alloc] initWithDictionary:@{@"objectID": self.objectID ?: [NSNull null],
                                              @"slug": self.slug ?: [NSNull null],
                                              @"author": self.author ?: [NSNull null],
                                              @"title": self.title ?: [NSNull null],
                                              @"date": self.date ?: [NSNull null],
                                              @"body": self.body ?: [NSNull null],
                                              @"path": self.path ?: [NSNull null],
                                              @"url": url ?: [NSNull null],
                                              } error:nil];
}

- (BOOL)isEqualToPost:(Post *)other {
    return [self.objectID isEqualToString:other.objectID]
            && [self.path isEqualToString:other.path]
            && [self.title isEqualToString:other.title]
            && [self.body isEqualToString:other.body]
            && self.draft == other.draft
            && ((!self.url && !other.url) || [self.url isEqual:other.url]);
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

- (NSString *)formattedDate {
    if (!_formattedDate && self.time) {
        _formattedDate = [NSString stringWithFormat:@"%ld-%02ld-%02ld", (long)self.time.mm_year, (long)self.time.mm_month, (long)self.time.mm_day];
    }
    return _formattedDate;
}

- (NSString *)path {
    if (!_path) {
        if (self.draft) {
            _path = [NSString stringWithFormat:@"/posts/drafts/%@", self.objectID];
        }
        else {
            NSAssert(self.slug && self.date, @"slug and date are required");
            NSString *paddedMonth = [self paddedMonthForDate:self.date];
            _path = [NSString stringWithFormat:@"/posts/%ld/%@/%@", (long)self.time.mm_year, paddedMonth, self.slug];
        }
    }
    return _path;
}

- (NSString *)paddedMonthForDate:(NSDate *)date {
    return [NSString stringWithFormat:@"%02ld", (long)date.mm_month];
}

@end

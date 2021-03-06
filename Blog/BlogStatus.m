//
//  BlogStatus.m
//  Blog
//
//  Created by Sami Samhuri on 2014-11-23.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

#import "BlogStatus.h"

@implementation BlogStatus

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
            @"localVersion"  : @"local-version",
            @"remoteVersion" : @"remote-version",
            @"dirty"         : @"dirty",
    };
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error {
    self = [super initWithDictionary:dictionaryValue error:error];
    if (self) {
        _date = [NSDate date];
    }
    return self;
}

@end

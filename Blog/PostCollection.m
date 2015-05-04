//
// Created by Sami Samhuri on 15-04-24.
// Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//
#import "PostCollection.h"

@implementation PostCollection

+ (instancetype)postCollectionWithTitle:(NSString *)title posts:(NSMutableArray *)posts {
    return [[self alloc] initWithTitle:title posts:posts];
}

- (instancetype)initWithTitle:(NSString *)title posts:(NSMutableArray *)posts {
    self = [super init];
    if (self) {
        _title = [title copy];
        _posts = [posts mutableCopy];
    }
    return self;
}

static NSString *const PostsKey = @"posts";
static NSString *const TitleKey = @"title";

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _title = [coder decodeObjectForKey:TitleKey];
        _posts = [coder decodeObjectForKey:PostsKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.title forKey:TitleKey];
    [coder encodeObject:self.posts forKey:PostsKey];
}

@end

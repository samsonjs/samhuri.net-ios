//
// Created by Sami Samhuri on 15-05-20.
// Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//
#import "SharedContent.h"

@implementation SharedContent

+ (instancetype)contentWithURL:(NSURL *)url text:(NSString *)text {
    return [[self alloc] initWithURL:url contentText:text];
}

- (instancetype)initWithURL:(NSURL *)url contentText:(NSString *)text {
    self = [super init];
    if (self) {
        _url = [url copy];
        _text = [text copy];
    }
    return self;
}

@end

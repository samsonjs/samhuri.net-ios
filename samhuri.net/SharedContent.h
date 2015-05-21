//
// Created by Sami Samhuri on 15-05-20.
// Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//
@import Foundation;

@interface SharedContent : NSObject

@property(nonatomic, readonly, copy) NSURL *url;
@property(nonatomic, readonly, copy) NSString *text;

+ (instancetype)contentWithURL:(NSURL *)url text:(NSString *)text;
- (instancetype)initWithURL:(NSURL *)url contentText:(NSString *)text;


@end

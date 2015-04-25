//
// Created by Sami Samhuri on 15-04-24.
// Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//
@import Foundation;

@interface PostCollection : NSObject

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSMutableArray *posts;

+ (instancetype)postCollectionWithTitle:(NSString *)title posts:(NSArray *)posts;
- (instancetype)initWithTitle:(NSString *)title posts:(NSArray *)posts;

@end
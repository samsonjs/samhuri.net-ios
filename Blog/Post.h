//
//  Post.h
//  Blog
//
//  Created by Sami Samhuri on 2014-11-23.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

#import <Mantle/Mantle.h>

@interface Post : MTLModel <MTLJSONSerializing>

@property (nonatomic, readonly, strong) NSString *objectID;
@property (nonatomic, readonly, strong) NSString *slug;
@property (nonatomic, readonly, strong) NSString *author;
@property (nonatomic, readonly, strong) NSString *title;
@property (nonatomic, readonly, strong) NSString *date;
@property (nonatomic, readonly, strong) NSDate *time;
@property (nonatomic, readonly) NSTimeInterval timestamp;
@property (nonatomic, readonly, strong) NSString *body;
@property (nonatomic, readonly, strong) NSString *path;
@property (nonatomic, readonly, strong) NSURL *url;
@property (nonatomic, readonly, getter=isDraft) BOOL draft;
@property (nonatomic, readonly, getter=isLink) BOOL link;
@property (nonatomic, readonly) NSString *formattedDate;

- (instancetype)copyWithBody:(NSString *)body;
- (instancetype)copyWithTitle:(NSString *)title;
- (instancetype)copyWithURL:(NSURL *)url;
- (BOOL)isEqualToPost:(Post *)other;

@end

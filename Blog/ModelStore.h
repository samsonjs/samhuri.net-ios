//
//  ModelStore.h
//  Blog
//
//  Created by Sami Samhuri on 2014-11-26.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PMKPromise;
@class YapDatabaseConnection;
@class BlogStatus;
@class Post;

@interface ModelStore : NSObject

- (instancetype)initWithConnection:(YapDatabaseConnection *)connection;

- (BlogStatus *)blogStatus;

- (NSArray *)drafts;
- (NSArray *)publishedPosts;
- (Post *)postWithPath:(NSString *)path;

- (PMKPromise *)saveBlogStatus:(BlogStatus *)blogStatus;
- (PMKPromise *)savePost:(Post *)post;
- (PMKPromise *)saveDrafts:(NSArray *)posts;
- (PMKPromise *)savePublishedPosts:(NSArray *)posts;

- (PMKPromise *)addDraft:(Post *)post;
- (PMKPromise *)addPublishedPost:(Post *)post;

- (PMKPromise *)removeDraftWithPath:(NSString *)path;
- (PMKPromise *)removePostWithPath:(NSString *)path;

@end

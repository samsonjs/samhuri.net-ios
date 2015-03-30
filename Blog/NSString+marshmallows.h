//
//  NSString+marshmallows.h
//  Marshmallows
//
//  Created by Sami Samhuri on 11-09-03.
//  Copyright 2011 Sami Samhuri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Marshmallows)

- (NSString *)mm_firstMatch:(NSString *)pattern;
- (NSString *)mm_stringByReplacing:(NSString *)pattern with:(NSString *)replacement;
- (NSString *)mm_stringByReplacingFirst:(NSString *)pattern with:(NSString *)replacement;
- (NSString *)mm_stringByTrimmingWhitespace;
- (NSString *)mm_stringByURLEncoding;
- (NSString *)mm_stringByURLDecoding;

@end

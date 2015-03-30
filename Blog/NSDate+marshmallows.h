//
//  NSDate+marshmallows.h
//  Marshmallows
//
//  Created by Sami Samhuri on 11-06-18.
//  Copyright 2011 Sam1 Samhuri. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDate (Marshmallows)

@property (nonatomic, readonly) NSInteger mm_year;
@property (nonatomic, readonly) NSInteger mm_month;
@property (nonatomic, readonly) NSInteger mm_day;

+ (NSDate *)mm_dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day;
- (NSString *)mm_relativeToNow;

@end

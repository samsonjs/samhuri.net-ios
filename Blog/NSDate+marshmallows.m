//
//  NSDate+marshmallows.m
//  Marshmallows
//
//  Created by Sami Samhuri on 11-06-18.
//  Copyright 2011 Sami Samhuri. All rights reserved.
//

#import "NSDate+marshmallows.h"

#define MINUTE 60.0
#define HOUR   (60.0 * MINUTE)
#define DAY    (24.0 * HOUR)
#define WEEK   (7.0 * DAY)
#define MONTH  (30.0 * DAY)
#define YEAR   (365.25 * DAY)

@implementation NSDate (Marshmallows)

+ (NSDate *)mm_dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [NSDateComponents new];
    [components setYear:year];
    [components setMonth:month];
    [components setDay:day];
    return [calendar dateFromComponents:components];
}   

- (NSString *)mm_relativeToNow {
    double diff = [[NSDate date] timeIntervalSinceDate:self];
    NSString *result = nil;

    // future
    if (diff < -2 * YEAR) {
        result = [NSString stringWithFormat:@"in %d years", abs(diff / YEAR)];
    }
    else if (diff < -YEAR) {
        result = @"next year";
    }
    else if (diff < -8 * WEEK) {
        result = [NSString stringWithFormat:@"in %d months", abs(diff / MONTH)];
    }
    else if (diff < -4 * WEEK) {
        result = @"next month";
    }
    else if (diff < -2 * WEEK) {
        result = [NSString stringWithFormat:@"in %d weeks", abs(diff / WEEK)];
    }
    else if (diff < -WEEK) {
        result = @"next week";
    }
    else if (diff < -2 * DAY) {
        result = [NSString stringWithFormat:@"in %d days", abs(diff / DAY)];
    }
    else if (diff < -DAY) {
        result = @"tomorrow";
    }
    else if (diff < -2 * HOUR) {
        result = [NSString stringWithFormat:@"in %d hours", abs(diff / HOUR)];
    }
    else if (diff < -HOUR) {
        result = @"in an hour";
    }
    else if (diff < -2 * MINUTE) {
        result = [NSString stringWithFormat:@"in %d minutes", abs(diff / MINUTE)];
    }
    else if (diff < -MINUTE) {
        result = @"in a minute";
    }

    // present
    else if (diff < MINUTE) {
        result = @"right now";
    }

    // past
    else if (diff < 2 * MINUTE) {
        result = @"a minute ago";
    }
    else if (diff < HOUR) {
        result = [NSString stringWithFormat:@"%d minutes ago", (int)(diff / MINUTE)];
    }
    else if (diff < 2 * HOUR) {
        result = @"an hour ago";
    }
    else if (diff < DAY) {
        result = [NSString stringWithFormat:@"%d hours ago", (int)(diff / HOUR)];
    }
    else if (diff < 2 * DAY) {
        result = @"yesterday";
    }
    else if (diff < WEEK) {
        result = [NSString stringWithFormat:@"%d days ago", (int)(diff / DAY)];
    }
    else if (diff < 2 * WEEK) {
        result = @"last week";
    }
    else if (diff < 4 * WEEK) {
        result = [NSString stringWithFormat:@"%d weeks ago", (int)(diff / WEEK)];
    }
    else if (diff < 8 * WEEK) {
        result = @"last month";
    }
    else if (diff < YEAR) {
        result = [NSString stringWithFormat:@"%d months ago", (int)(diff / MONTH)];
    }
    else if (diff < 2 * YEAR) {
        result = @"last year";
    }
    else {
        result = [NSString stringWithFormat:@"%d years ago", (int)(diff / YEAR)];
    }

    return result;
}

- (NSInteger)mm_year {
    return [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:self].year;
}

- (NSInteger)mm_month {
    return [[NSCalendar currentCalendar] components:NSCalendarUnitMonth fromDate:self].month;
}

- (NSInteger)mm_day {
    return [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:self].day;
}

@end

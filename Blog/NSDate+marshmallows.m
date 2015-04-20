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
    return [self mm_dateWithYear:year month:month day:day hour:0 minute:0 second:0];
}

+ (NSDate *)mm_dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day hour:(NSInteger)hour minute:(NSInteger)minute second:(NSInteger)second {
    return [[NSCalendar currentCalendar] dateWithEra:1 year:year month:month day:day hour:hour minute:minute second:second nanosecond:0];
}

- (NSString *)mm_relativeToNow {
    double diff = [[NSDate date] timeIntervalSinceDate:self];

    // future
    if (diff < -2 * YEAR) {
        return [NSString stringWithFormat:@"in %d years", abs((int)(diff / YEAR))];
    }
    else if (diff < -YEAR) {
        return @"next year";
    }
    else if (diff < -8 * WEEK) {
        return [NSString stringWithFormat:@"in %d months", abs((int)(diff / MONTH))];
    }
    else if (diff < -4 * WEEK) {
        return @"next month";
    }
    else if (diff < -2 * WEEK) {
        return [NSString stringWithFormat:@"in %d weeks", abs((int)(diff / WEEK))];
    }
    else if (diff < -WEEK) {
        return @"next week";
    }
    else if (diff < -2 * DAY) {
        return [NSString stringWithFormat:@"in %d days", abs((int)(diff / DAY))];
    }
    else if (diff < -DAY) {
        return @"tomorrow";
    }
    else if (diff < -2 * HOUR) {
        return [NSString stringWithFormat:@"in %d hours", abs((int)(diff / HOUR))];
    }
    else if (diff < -HOUR) {
        return @"in an hour";
    }
    else if (diff < -2 * MINUTE) {
        return [NSString stringWithFormat:@"in %d minutes", abs((int)(diff / MINUTE))];
    }
    else if (diff < -MINUTE) {
        return @"in a minute";
    }

    // present
    else if (diff < MINUTE) {
        return @"right now";
    }

    // past
    else if (diff < 2 * MINUTE) {
        return @"a minute ago";
    }
    else if (diff < HOUR) {
        return [NSString stringWithFormat:@"%d minutes ago", (int)(diff / MINUTE)];
    }
    else if (diff < 2 * HOUR) {
        return @"an hour ago";
    }
    else if (diff < DAY) {
        return [NSString stringWithFormat:@"%d hours ago", (int)(diff / HOUR)];
    }
    else if (diff < 2 * DAY) {
        return @"yesterday";
    }
    else if (diff < WEEK) {
        return [NSString stringWithFormat:@"%d days ago", (int)(diff / DAY)];
    }
    else if (diff < 2 * WEEK) {
        return @"last week";
    }
    else if (diff < 4 * WEEK) {
        return [NSString stringWithFormat:@"%d weeks ago", (int)(diff / WEEK)];
    }
    else if (diff < 8 * WEEK) {
        return @"last month";
    }
    else if (diff < YEAR) {
        return [NSString stringWithFormat:@"%d months ago", (int)(diff / MONTH)];
    }
    else if (diff < 2 * YEAR) {
        return @"last year";
    }
    else {
        return [NSString stringWithFormat:@"%d years ago", (int)(diff / YEAR)];
    }
}

- (NSInteger)mm_year {
    return [[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:self];
}

- (NSInteger)mm_month {
    return [[NSCalendar currentCalendar] component:NSCalendarUnitMonth fromDate:self];
}

- (NSInteger)mm_day {
    return [[NSCalendar currentCalendar] component:NSCalendarUnitDay fromDate:self];
}

@end

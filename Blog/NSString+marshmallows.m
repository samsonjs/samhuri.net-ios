//
//  NSString+marshmallows.m
//  Marshmallows
//
//  Created by Sami Samhuri on 11-09-03.
//  Copyright 2011 Sami Samhuri. All rights reserved.
//

#import "NSString+marshmallows.h"

@implementation NSString (Marshmallows)

- (NSString *)mm_stringByTrimmingWhitespace {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)mm_firstMatch:(NSString *)pattern {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:0
                                                                             error:NULL];
    NSRange match = [regex rangeOfFirstMatchInString:self
                                             options:NSMatchingReportCompletion
                                               range:NSMakeRange(0, self.length)];
    return match.location == NSNotFound ? nil : [self substringWithRange:match];
}

- (NSString *)mm_stringByReplacing:(NSString *)pattern with:(NSString *)replacement {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:0
                                                                             error:NULL];
    return [regex stringByReplacingMatchesInString:self
                                           options:NSMatchingReportCompletion
                                             range:NSMakeRange(0, [self length])
                                      withTemplate:@""];
}

- (NSString *)mm_stringByReplacingFirst:(NSString *)pattern with:(NSString *)replacement {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:0
                                                                             error:NULL];
    NSRange match = [regex rangeOfFirstMatchInString:self
                                             options:NSMatchingReportCompletion
                                               range:NSMakeRange(0, self.length)];
    if (match.location != NSNotFound) {
        NSString *rest = [self substringFromIndex:match.location + match.length];
        return [[[self substringToIndex:match.location]
                 stringByAppendingString:replacement]
                stringByAppendingString:rest];
    }
    return [self copy];
}

- (NSString *) mm_stringByURLEncoding {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (CFStringRef)self,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                 kCFStringEncodingUTF8));
}

- (NSString *)mm_stringByURLDecoding {
    return [[self stringByReplacingOccurrencesOfString:@"+" withString:@" "]
            stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end

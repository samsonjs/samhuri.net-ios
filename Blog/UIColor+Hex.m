//
// Created by Sami Samhuri on 15-04-21.
// Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//
#import "UIColor+Hex.h"

@implementation UIColor (Hex)

+ (UIColor *)mm_colorFromInteger:(NSUInteger)color {
    unsigned char red = color >> 16;
    unsigned char green = (color >> 8) & 0xff;
    unsigned char blue = color & 0xff;
    return [UIColor colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:1.0];
}

@end
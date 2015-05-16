//
// Created by Sami Samhuri on 15-05-15.
// Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//
#import "CommonUI.h"
#import <FontAwesome+iOS/UIFont+FontAwesome.h>

UIView *NewFontAwesomeHUDView(NSString *text) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont fontAwesomeFontOfSize:36];
    label.text = text;
    [label sizeToFit];
    return label;
}

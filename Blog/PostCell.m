//
// Created by Sami Samhuri on 15-04-19.
// Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//
#import "PostCell.h"
#import "UIColor+Hex.h"

@interface PostCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;

@end

@implementation PostCell

- (void)configureWithTitle:(NSString *)title date:(NSString *)date {
    self.titleLabel.text = title;
    self.dateLabel.text = date;
    // workaround for iPad bug
    self.backgroundColor = [UIColor colorWithWhite:0.1333 alpha:1.0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated;
{
    UIColor *backgroundColor = [UIColor colorWithWhite:0.1333 alpha:1.0];
    UIColor *textColor = [UIColor whiteColor];
    if (selected) {
        backgroundColor = [UIColor mm_colorFromInteger:0x333333];
        textColor = [UIColor mm_colorFromInteger:0xAA0000];
    }

    void (^setProperties)() = ^{
        self.backgroundColor = backgroundColor;
        self.titleLabel.textColor = textColor;
    };
    if (animated) {
        [UIView animateWithDuration:0.3 animations:setProperties];
    }
    else {
        setProperties();
    }
}

@end
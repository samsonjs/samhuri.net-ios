//
// Created by Sami Samhuri on 15-04-19.
// Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//
#import "PostCell.h"

@interface PostCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;

@end

@implementation PostCell

- (void)configureWithTitle:(NSString *)title date:(NSString *)date {
    self.titleLabel.text = title;
    self.dateLabel.text = date;
}

@end
//
// Created by Sami Samhuri on 15-04-24.
// Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//
@import UIKit;

@interface ChangeTitleViewController : UIViewController

@property (nonatomic, copy) NSString *articleTitle;
@property (nonatomic, copy) dispatch_block_t dismissBlock;

@end
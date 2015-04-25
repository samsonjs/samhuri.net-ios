//
// Created by Sami Samhuri on 15-04-24.
// Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//
#import "ChangeTitleViewController.h"

@interface ChangeTitleViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *titleField;

@end

@implementation ChangeTitleViewController

@synthesize articleTitle = _articleTitle;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.titleField.text = _articleTitle;
    [self.titleField becomeFirstResponder];
}

- (NSString *)articleTitle {
    if (self.titleField) {
        return self.titleField.text;
    }
    return _articleTitle;
}

- (void)setArticleTitle:(NSString *)articleTitle {
    _articleTitle = [articleTitle copy];
    if (self.titleField) {
        self.titleField.text = articleTitle;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.dismissBlock) {
        self.dismissBlock();
    }
    return NO;
}

@end
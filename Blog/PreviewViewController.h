//
//  PreviewViewController.h
//  Blog
//
//  Created by Sami Samhuri on 2015-04-19.
//  Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PromiseKit/Promise.h>

@interface PreviewViewController : UIViewController

@property (nonatomic, strong) NSURLRequest *initialRequest;
@property (nonatomic, strong) PMKPromise *promise;

@end

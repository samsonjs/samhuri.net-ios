//
//  BlogStatus.h
//  Blog
//
//  Created by Sami Samhuri on 2014-11-23.
//  Copyright (c) 2014 Guru Logic Inc. All rights reserved.
//

@import Foundation;
#import <Mantle/Mantle.h>

@interface BlogStatus : MTLModel <MTLJSONSerializing>

@property (nonatomic, readonly, strong) NSDate *date;
@property (nonatomic, readonly, strong) NSString *localVersion;
@property (nonatomic, readonly, strong) NSString *remoteVersion;
@property (nonatomic, readonly, getter=isDirty) BOOL dirty;

@end

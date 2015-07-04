//
//  NotificationToSelectorMap.h
//  Blog
//
//  Created by Sami Samhuri on 2015-06-29.
//  Copyright © 2015 Guru Logic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NotificationToSelectorMap : NSObject

@property (nonatomic, copy, nonnull) NSDictionary *notificationNameToSelectorNameMap;

- (nonnull instancetype)initWithNotificationMap:(nonnull NSDictionary *)notificationMap;
- (void)addObserver:(nonnull NSObject *)observer;
- (void)removeObserver:(nonnull NSObject *)observer;

@end

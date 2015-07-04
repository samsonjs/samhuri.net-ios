//
//  NotificationToSelectorMap.h
//  Blog
//
//  Created by Sami Samhuri on 2015-06-29.
//  Copyright © 2015 Guru Logic Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NotificationToSelectorMap : NSObject

@property (nonatomic, copy) NSDictionary *notificationNameToSelectorNameMap;

- (instancetype)initWithNotificationMap:(nonnull NSDictionary *)notificationMap;
- (void)addObserver:(NSObject *)observer;
- (void)removeObserver:(NSObject *)observer;

@end

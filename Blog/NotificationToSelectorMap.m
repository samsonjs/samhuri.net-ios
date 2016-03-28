//
//  NotificationToSelectorMap.m
//  Blog
//
//  Created by Sami Samhuri on 2015-06-29.
//  Copyright © 2015 Guru Logic Inc. All rights reserved.
//

#import "NotificationToSelectorMap.h"

@implementation NotificationToSelectorMap

- (nonnull instancetype)initWithNotificationMap:(nonnull NSDictionary *)notificationMap {
    self = [super init];
    if (self) {
        _notificationNameToSelectorNameMap = notificationMap;
    }
    return self;
}

- (void)addObserver:(nonnull NSObject *)observer {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    for (NSString *notificationName in self.notificationNameToSelectorNameMap.allKeys) {
        NSString *selectorName = self.notificationNameToSelectorNameMap[notificationName];
        [notificationCenter addObserver:observer selector:NSSelectorFromString(selectorName) name:notificationName object:nil];
    }
}

- (void)removeObserver:(nonnull NSObject *)observer {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    for (NSString *notificationName in self.notificationNameToSelectorNameMap.allKeys) {
        [notificationCenter removeObserver:observer name:notificationName object:nil];
    }
}

@end

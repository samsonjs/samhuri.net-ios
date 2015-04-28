//
//  Functions.m
//  Blog
//
//  Created by Sami Samhuri on 2015-04-26.
//  Copyright (c) 2015 Guru Logic Inc. All rights reserved.
//

#import "Functions.h"

id safeCast(id obj, __unsafe_unretained Class class) {
    return [obj isKindOfClass:class] ? obj : nil;
}

//
//  User.m
//  JKBaseModel
//
//  Created by zx_04 on 15/6/24.
//  Copyright (c) 2015年 joker. All rights reserved.
//

#import "User.h"

@interface User ()

@property (nonatomic, copy) NSString *duty;

@end

@implementation User

#pragma mark - override method

+(NSArray *)transients
{
    return [NSArray arrayWithObjects:@"field1",@"field2",nil];
}

@end

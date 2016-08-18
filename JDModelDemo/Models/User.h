//
//  User.h
//  JKBaseModel
//
//  Created by zx_04 on 15/6/24.
//  Copyright (c) 2015年 joker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JDModel.h"
#import "Depart.h"

@interface User : JDModel

/** 账号 */
@property (nonatomic, copy)     NSString                    *account;
/** 名字 */
@property (nonatomic, copy)     NSString                    *name;
/** 性别 */
@property (nonatomic, copy)     NSString                    *sex;
/** 头像地址 */
@property (nonatomic, copy)     NSString                    *portraitPath;
/** 手机号码 */
@property (nonatomic, copy)     NSString                    *moblie;
/** 简介 */
@property (nonatomic, copy)     NSString                    *descn;
/** 年龄 */
@property (nonatomic, assign)  int                          age;

@property (nonatomic, assign)   long long                   createTime;

@property (nonatomic, assign)   int                        height;

@property (nonatomic, assign)   int                        field1;

@property (nonatomic, assign)   int                        field2;
@property (nonatomic, copy)   NSArray<Depart>             *departsArray;
@property (nonatomic, copy)   NSArray                     *testArray;
@property (nonatomic, copy)   NSMutableArray              *testMutableArray;
@property (nonatomic, copy)   NSDictionary                *testDict;
@property (nonatomic, copy)   NSMutableDictionary         *testMutableDict;
@property (nonatomic, copy)   NSData                      *testData;
@property (nonatomic, copy)   NSDate                      *testDate;
@property (nonatomic, copy)   NSNumber                    *testNumber;

@end

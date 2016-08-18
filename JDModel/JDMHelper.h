//
//  JDMHelper.h
//  JDModelDemo
//
//  Created by SC on 16/8/18.
//  Copyright © 2016年 SDJY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"

@interface JDMHelper : NSObject

@property (nonatomic, retain, readonly) FMDatabaseQueue *dbQueue;

+ (JDMHelper *)shareInstance;

+ (NSString *)dbPath;

- (BOOL)changeDBWithDirectoryName:(NSString *)directoryName;


@end

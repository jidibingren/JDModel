//
//  JDModel.m
//  JDModelDemo
//
//  Created by SC on 16/8/18.
//  Copyright © 2016年 SDJY. All rights reserved.
//

#import "JDModel.h"
#import "JDMHelper.h"

#import <objc/runtime.h>

@implementation JDModel

#pragma mark - override method
+ (void)initialize
{
    if (self != [JDModel self]) {
        [self createTable];
        [self JD_Queue];
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSDictionary *dic = [self.class getAllProperties];
        _jdm_columeNames = [dic objectForKey:@"name"];
        //        _columeTypes = [dic objectForKey:@"type"];
        //        _columeTypeNames = [dic objectForKey:@"typeName"];
        _jdm_subModelClasses = [dic objectForKey:@"subModelClasses"];
        _jdm_propertyTypes   = [dic objectForKey:@"propertyTypes"];
    }
    
    return self;
}

#pragma mark - base method
/**
 *  获取该类的所有属性
 */
+ (NSDictionary *)getPropertys
{
    NSMutableArray *proNames = [NSMutableArray new];
    NSMutableArray *proTypes = [NSMutableArray new];
    NSMutableArray *proTypeNames = [NSMutableArray new];
    NSMutableDictionary *subModelClassDict = [NSMutableDictionary new];
    NSMutableData       *propertyTypes = [NSMutableData new];
    JDMPropertyType pType = JDMPropertyInteger;
    [propertyTypes appendBytes:(const void *)&pType length:1];
    
    NSArray *theTransients = [[self class] transients];
    
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        //获取属性名
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        if ([theTransients containsObject:propertyName] || [propertyName hasPrefix:@"jdm_"]) {
            continue;
        }
        [proNames addObject:propertyName];
        //获取属性类型等参数
        NSString *propertyType = [NSString stringWithCString: property_getAttributes(property) encoding:NSUTF8StringEncoding];
        /*
         各种符号对应类型，部分类型在新版SDK中有所变化，如long 和long long
         c char         C unsigned char
         i int          I unsigned int
         l long         L unsigned long
         s short        S unsigned short
         d double       D unsigned double
         f float        F unsigned float
         q long long    Q unsigned long long
         B BOOL
         @ 对象类型 //指针 对象类型 如NSString 是@“NSString”
         
         
         64位下long 和long long 都是Tq
         SQLite 默认支持五种数据类型TEXT、INTEGER、REAL、BLOB、NULL
         因为在项目中用的类型不多，故只考虑了少数类型
         */
        if ([propertyType hasPrefix:@"T@"]) {
            
            NSString *classProperties = [propertyType componentsSeparatedByString:@"\""][1];
            NSArray<NSString*> *propertys = [classProperties componentsSeparatedByString:@"<"];
            Class modelClass = NSClassFromString(propertys[0]);
            
            if (propertys.count > 1) {
                NSArray<NSString*> *protocolNames = [[propertys[1] stringByReplacingOccurrencesOfString:@">" withString:@""] componentsSeparatedByString:@","];
                
                for (NSString *protocolName in protocolNames) {
                    Class modelClass = NSClassFromString(protocolName);
                    if ([modelClass isSubclassOfClass:[JDModel class]]) {
                        subModelClassDict[propertyName] = modelClass;
                        break;
                    }
                }
            }
            
            [proTypeNames addObject:classProperties];
            
            if ([modelClass isSubclassOfClass:[JDModel class]]){
                
                [proTypes addObject:JDM_SQLINTEGER];
                
                pType = JDMPropertyModel;
                
            }else if ([modelClass isSubclassOfClass:[NSString class]] ||
                      [modelClass isSubclassOfClass:[NSAttributedString class]]) {
                
                [proTypes addObject:JDM_SQLTEXT];
                
                pType = JDMPropertyText;
                
            }else {
                
                [proTypes addObject:JDM_SQLBLOB];
                
                if ([modelClass isSubclassOfClass:[NSArray class]]) {
                    
                    pType = subModelClassDict[propertyName] ? JDMPropertyModelArray : JDMPropertyArray;
                    
                }else if ([modelClass isSubclassOfClass:[NSMutableArray class]]) {
                    
                    pType = subModelClassDict[propertyName] ? JDMPropertyMutableModelArray : JDMPropertyMutableArray;
                    
                }else {
                    
                    pType = JDMPropertyBlob;
                    
                }
                
            }
            
        } else if ([propertyType hasPrefix:@"Ti"]||[propertyType hasPrefix:@"TI"]||[propertyType hasPrefix:@"Ts"]||[propertyType hasPrefix:@"TS"]||[propertyType hasPrefix:@"TB"]||[propertyType hasPrefix:@"Tq"]||[propertyType hasPrefix:@"TQ"]) {
            
            [proTypes addObject:JDM_SQLINTEGER];
            [proTypeNames addObject:JDM_SQLINTEGER];
            
            pType = JDMPropertyInteger;
            
        } else {
            
            [proTypes addObject:JDM_SQLREAL];
            [proTypeNames addObject:JDM_SQLREAL];
            
            pType = JDMPropertyReal;
            
        }
        
        [propertyTypes appendBytes:(const void *)&pType length:1];
        
    }
    free(properties);
    
    return [NSDictionary dictionaryWithObjectsAndKeys:proNames,@"name",proTypes,@"type",proTypeNames,@"typeName",subModelClassDict,@"subModelClasses",propertyTypes,@"propertyTypes",nil];
}

/** 获取所有属性，包含主键pk */
+ (NSDictionary *)getAllProperties
{
    static NSMutableDictionary *initializeClasses = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        initializeClasses = [NSMutableDictionary new];
    });
    
    NSString *className = NSStringFromClass(self);
    
    if (initializeClasses[className] == nil) {
        
        NSDictionary *dict = [self.class getPropertys];
        
        NSMutableArray *proNames = [NSMutableArray array];
        NSMutableArray *proTypes = [NSMutableArray array];
        NSMutableArray *proTypeNames = [NSMutableArray array];
        NSDictionary *subModelClassDict = [dict objectForKey:@"subModelClasses"];
        NSData *propertyTypes = [dict objectForKey:@"propertyTypes"];
        [proNames addObject:JDM_primaryId];
        [proTypes addObject:[NSString stringWithFormat:@"%@ %@",JDM_SQLINTEGER,JDM_PrimaryKey]];
        [proNames addObjectsFromArray:[dict objectForKey:@"name"]];
        [proTypes addObjectsFromArray:[dict objectForKey:@"type"]];
        [proTypeNames addObject:JDM_SQLINTEGER];
        [proTypeNames addObjectsFromArray:[dict objectForKey:@"typeName"]];
        
        NSDictionary *classDict = [NSDictionary dictionaryWithObjectsAndKeys:proNames,@"name",proTypes,@"type",proTypeNames,@"typeName",subModelClassDict,@"subModelClasses",propertyTypes,@"propertyTypes",nil];
        initializeClasses[className] = classDict;
    }
    
    return initializeClasses[className];
}

/** 数据库中是否存在表 */
+ (BOOL)isExistInTable
{
    __block BOOL res = NO;
    JDMHelper *jkDB = [JDMHelper shareInstance];
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        res = [db tableExists:tableName];
    }];
    return res;
}

/** 获取列名 */
+ (NSArray *)getColumns
{
    JDMHelper *jkDB = [JDMHelper shareInstance];
    NSMutableArray *columns = [NSMutableArray array];
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        FMResultSet *resultSet = [db getTableSchema:tableName];
        while ([resultSet next]) {
            NSString *column = [resultSet stringForColumn:@"name"];
            [columns addObject:column];
        }
    }];
    return [columns copy];
}

/**
 * 创建表
 * 如果已经创建，返回YES
 */
+ (BOOL)createTable
{
    __block BOOL res = YES;
    NSString *columeAndType = [self.class getColumeAndTypeString];
    JDMHelper *jkDB = [JDMHelper shareInstance];
    [jkDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@);",tableName,columeAndType];
        if (![db executeUpdate:sql]) {
            res = NO;
            *rollback = YES;
            return;
        };
        
        NSMutableArray *columns = [NSMutableArray array];
        FMResultSet *resultSet = [db getTableSchema:tableName];
        while ([resultSet next]) {
            NSString *column = [resultSet stringForColumn:@"name"];
            [columns addObject:column];
        }
        NSDictionary *dict = [self.class getAllProperties];
        NSArray *properties = [dict objectForKey:@"name"];
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)",columns];
        //过滤数组
        NSArray *resultArray = [properties filteredArrayUsingPredicate:filterPredicate];
        for (NSString *column in resultArray) {
            NSUInteger index = [properties indexOfObject:column];
            NSString *proType = [[dict objectForKey:@"type"] objectAtIndex:index];
            NSString *fieldSql = [NSString stringWithFormat:@"%@ %@",column,proType];
            NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ ",NSStringFromClass(self.class),fieldSql];
            if (![db executeUpdate:sql]) {
                res = NO;
                *rollback = YES;
                return ;
            }
        }
    }];
    
    return res;
}

+ (dispatch_queue_t)JD_Queue{
    
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create([NSStringFromClass(self) UTF8String], DISPATCH_QUEUE_SERIAL);
    });
    
    return queue;
}

- (long long)saveOrUpdateByColumnName:(NSString*)columnName AndColumnValue:(NSString*)columnValue
{
    id record = [self.class findFirstByCriteria:[NSString stringWithFormat:@"where %@ = %@",columnName,columnValue]];
    if (record) {
        id primaryValue = [record valueForKey:JDM_primaryId]; //取到了主键PK
        if ([primaryValue intValue] <= 0) {
            return [self save];
        }else{
            self.pk = [primaryValue longLongValue];
            return [self update];
        }
    }else{
        return [self save];
    }
}

- (long long)saveOrUpdate
{
    id primaryValue = [self valueForKey:JDM_primaryId];
    if ([primaryValue intValue] <= 0) {
        return [self save];
    }
    
    return [self update];
}

inline NSArray *modelToData(JDModel *model, BOOL isAdd){
    
    NSString *tableName = NSStringFromClass(model.class);
    NSMutableString *keyString = [NSMutableString string];
    NSMutableString *valueString = [NSMutableString string];
    NSMutableArray *insertValues = [NSMutableArray  array];
    JDMPropertyType *pTypes = (JDMPropertyType *)model.jdm_propertyTypes.bytes;
    
    for (NSUInteger i = 0, count = model.jdm_columeNames.count; i < count; i++) {
        
        NSString *proname = [model.jdm_columeNames objectAtIndex:i];
        JDMPropertyType pType = pTypes[i];
        
        Class modelClass = model.jdm_subModelClasses[proname];
        
        if ([proname isEqualToString:JDM_primaryId]) {
            continue;
        }
        
        if (isAdd) {
            
            [keyString appendFormat:@"%@,", proname];
            [valueString appendString:@"?,"];
            
        }else{
            
            [keyString appendFormat:@" %@=?,", proname];
            
        }
        
        id value = [model valueForKey:proname];
        
        if (pType == JDMPropertyReal || pType == JDMPropertyInteger || pType == JDMPropertyText) {
            
            value = [model valueForKey:proname];
            
        } else if (pType == JDMPropertyModel) {
            
            JDModel *model = value;
            
            if (model && [model isKindOfClass:[JDModel class]]) {
                
                value = @([model saveOrUpdate]);
                
            }
            
        } else if (pType == JDMPropertyModelArray || pType == JDMPropertyMutableModelArray){
            
            if (modelClass) {
                
                NSMutableArray *pksArray = [NSMutableArray new];
                
                for (JDModel *model in value) {
                    
                    if (![model isKindOfClass:[JDModel class]]) {
                        NSLog(@"model is not JDModel!");
                        break;
                    }
                    
                    [pksArray addObject:@([model saveOrUpdate])];
                }
                
                value =  [NSKeyedArchiver archivedDataWithRootObject:pksArray];
                
            }
            
        } else {
            
            if (value != nil) {
                
                value = [NSKeyedArchiver archivedDataWithRootObject:value];
                
            }else{
                
                value = [NSData data];
                
            }
        }
        
        
        if (!value) {
            value = @"";
        }
        [insertValues addObject:value];
    }
    //删除最后那个逗号
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
    
    NSString *sql = nil;
    
    if (isAdd) {
        
        [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
        sql = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);", tableName, keyString, valueString];
        
    }else{
        
        sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@=?;", tableName, keyString, JDM_primaryId];
        [insertValues addObject:[model valueForKey:JDM_primaryId]];
        
    }
    
    return @[sql,insertValues];
}

inline NSArray *dataToModel(FMResultSet *resultSet, Class modelClass){
    
    NSMutableArray *models = [NSMutableArray new];
    
    while ([resultSet next]) {
        JDModel *model = [[modelClass alloc] init];
        JDMPropertyType *pTypes = (JDMPropertyType *)model.jdm_propertyTypes.bytes;
        
        for (int i=0; i< model.jdm_columeNames.count; i++) {
            NSString *columeName = [model.jdm_columeNames objectAtIndex:i];
            JDMPropertyType pType = pTypes[i];
            
            Class modelClass = model.jdm_subModelClasses[columeName];
            
            if (pType == JDMPropertyReal || pType == JDMPropertyInteger) {
                
                [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columeName]] forKey:columeName];
                
            } else if (pType == JDMPropertyText){
                
                [model setValue:[resultSet stringForColumn:columeName] forKey:columeName];
                
            } else if (pType == JDMPropertyModel) {
                
                if (modelClass) {
                    
                    [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columeName]] forKey:columeName];
                    
                }
                
            } else {
                
                NSData *data = [resultSet dataForColumn:columeName];
                
                if (data == nil || data == NULL || [data isEqual:[NSNull null]]) {
                    continue;
                }
                
                if (pType == JDMPropertyModelArray || pType == JDMPropertyMutableModelArray) {
                    
                    if (modelClass) {
                        
                        [model setValue:data forKey:columeName];
                        
                    }
                    
                } else if (pType == JDMPropertyMutableArray) {
                    
                    NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                    
                    if (array && array.count > 0) {
                        
                        [model setValue:[[NSMutableArray alloc]initWithArray:array] forKey:columeName];
                        
                    }
                    
                }else {
                    
                    [model setValue:[NSKeyedUnarchiver unarchiveObjectWithData:data] forKey:columeName];
                    
                }
                
            }
            
        }
        
        [models addObject:model];
        FMDBRelease(model);
    }
    
    return (NSArray *)models;
}

inline NSArray *dataToSubModel(NSArray *models){
    
    for (JDModel *model in models) {
        //        JDModel *model = [[self.class alloc] init];
        JDMPropertyType *pTypes = (JDMPropertyType *)model.jdm_propertyTypes.bytes;
        
        for (int i=0; i< model.jdm_columeNames.count; i++) {
            NSString *columeName = [model.jdm_columeNames objectAtIndex:i];
            JDMPropertyType pType = pTypes[i];
            
            Class modelClass = model.jdm_subModelClasses[columeName];
            
            if (pType == JDMPropertyModel) {
                
                if (modelClass) {
                    
                    [model setValue:[modelClass findByPK:[[model valueForKey:columeName] longLongValue]] forKey:columeName];
                    
                }
                
            } else if (pType == JDMPropertyModelArray || pType == JDMPropertyMutableModelArray){
                
                NSData *data = [model valueForKey:columeName];
                
                if (data == nil || data == NULL || [data isEqual:[NSNull null]]) {
                    continue;
                }
                
                if (modelClass) {
                    
                    NSMutableArray *subModels = [NSMutableArray new];
                    NSMutableArray *pksArray = [NSKeyedUnarchiver unarchiveObjectWithData: data];
                    
                    for (NSNumber *pk in pksArray) {
                        
                        id subModel = [modelClass findByPK:pk.longLongValue];
                        
                        if (subModel) {
                            
                            [subModels addObject:subModel];
                            
                        }
                        
                    }
                    
                    [model setValue:subModels forKey:columeName];
                    
                }
                
            }
            
        }
        
    }
    
    return models;
}

- (long long)save
{
    NSArray *dbInfo = modelToData(self, YES);
    
    JDMHelper *jkDB = [JDMHelper shareInstance];
    __block BOOL res = NO;
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        res = [db executeUpdate:(NSString *)dbInfo[0] withArgumentsInArray:(NSArray *)dbInfo[1]];
        self.pk = res?[NSNumber numberWithLongLong:db.lastInsertRowId].intValue:0;
        NSLog(res?@"插入成功":@"插入失败");
    }];
    
    
    return self.pk;
}

/** 批量保存用户对象 */
+ (NSMutableArray *)saveObjects:(NSArray *)array
{
    //判断是否是JKBaseModel的子类
    for (JDModel *model in array) {
        if (![model isKindOfClass:[JDModel class]]) {
            return [NSMutableArray new];
        }
    }
    
    __block BOOL res = YES;
    __block NSMutableArray *pksArray = [NSMutableArray new];
    __block NSMutableArray *sqlsArray = [NSMutableArray new];
    __block NSMutableArray *insertValuesArray = [NSMutableArray new];
    JDMHelper *jkDB = [JDMHelper shareInstance];
    for (JDModel *model in array) {
        
        NSArray *dbInfo = modelToData(model, YES);
        
        [sqlsArray addObject:(NSString *)dbInfo[0]];
        
        [insertValuesArray addObject:(NSArray *)dbInfo[1]];
        
    }
    
    // 如果要支持事务
    [jkDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        for (NSUInteger i = 0, count = array.count; i < count; i++) {
            
            JDModel *model = array[i];
            NSString *sql = sqlsArray[i];
            NSArray *insertValues = insertValuesArray[i];
            
            BOOL flag = [db executeUpdate:sql withArgumentsInArray:insertValues];
            model.pk = flag?[NSNumber numberWithLongLong:db.lastInsertRowId].intValue:0;
            [pksArray addObject:@(model.pk)];
            NSLog(flag?@"插入成功":@"插入失败");
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
            
        }
    }];
    
    
    return pksArray;
}

- (long long)update
{
    JDMHelper *jkDB = [JDMHelper shareInstance];
    __block BOOL res = NO;
    
    id primaryValue = [self valueForKey:JDM_primaryId];
    
    if (!primaryValue || primaryValue <= 0) {
        return 0;
    }
    
    NSArray *dbInfo = modelToData(self, NO);
    
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        
        res = [db executeUpdate:(NSString *)dbInfo[0] withArgumentsInArray:(NSArray *)dbInfo[1]];
        NSLog(res?@"更新成功":@"更新失败");
    }];
    
    return self.pk;
}

/** 批量更新用户对象*/
+ (NSMutableArray *)updateObjects:(NSArray *)array
{
    for (JDModel *model in array) {
        if (![model isKindOfClass:[JDModel class]]) {
            return [NSMutableArray new];
        }
    }
    __block BOOL res = YES;
    __block NSMutableArray *pksArray = [NSMutableArray new];
    __block NSMutableArray *sqlsArray = [NSMutableArray new];
    __block NSMutableArray *updateValuesArray = [NSMutableArray new];
    
    for (JDModel *model in array) {
        
        id primaryValue = [model valueForKey:JDM_primaryId];
        
        if (!primaryValue || primaryValue <= 0) {
            res = NO;
            return [NSMutableArray new];
        }
        
        NSArray *dbInfo = modelToData(model, NO);
        
        [sqlsArray addObject:(NSString *)dbInfo[0]];
        
        [updateValuesArray addObject:(NSArray *)dbInfo[1]];
        
    }
    
    JDMHelper *jkDB = [JDMHelper shareInstance];
    // 如果要支持事务
    [jkDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        for (NSUInteger i = 0, count = array.count; i < count; i++) {
            
            JDModel *model = array[i];
            NSString *sql = sqlsArray[i];
            NSArray *updateValues = updateValuesArray[i];
            
            id primaryValue = [model valueForKey:JDM_primaryId];
            if (!primaryValue || primaryValue <= 0) {
                res = NO;
                *rollback = YES;
                return;
            }
            
            BOOL flag = [db executeUpdate:sql withArgumentsInArray:updateValues];
            [pksArray addObject:@(model.pk)];
            NSLog(flag?@"更新成功":@"更新失败");
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
        }
        
    }];
    
    return pksArray;
}

/** 删除单个对象 */
- (BOOL)deleteObject
{
    JDMHelper *jkDB = [JDMHelper shareInstance];
    __block BOOL res = NO;
    NSString *tableName = NSStringFromClass(self.class);
    id primaryValue = [self valueForKey:JDM_primaryId];
    if (!primaryValue || primaryValue <= 0) {
        return NO;
    }
    
    JDMPropertyType *pTypes = (JDMPropertyType *)self.jdm_propertyTypes.bytes;
    
    for (int i=0; i< self.jdm_columeNames.count; i++) {
        
        NSString *columeName = [self.jdm_columeNames objectAtIndex:i];
        JDMPropertyType pType = pTypes[i];
        
        if (pType == JDMPropertyModel) {
            
            JDModel *subModel = [self valueForKey:columeName];
            
            if (subModel && [subModel isKindOfClass:[JDModel class]]) {
                
                [subModel deleteObject];
                
            }
            
        } else if (pType == JDMPropertyModelArray || pType == JDMPropertyMutableModelArray) {
            
            NSMutableArray *subModels = [self valueForKey:columeName];
            
            for (JDModel *subModel in subModels) {
                
                if (subModel && [subModel isKindOfClass:[JDModel class]]) {
                    
                    [subModel deleteObject];
                    
                }
                
            }
            
        }
        
    }
    
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",tableName, JDM_primaryId];
        res = [db executeUpdate:sql withArgumentsInArray:@[primaryValue]];
        NSLog(res?@"删除成功":@"删除失败");
    }];
    
    return res;
}

/** 批量删除用户对象 */
+ (BOOL)deleteObjects:(NSArray *)array
{
    for (JDModel *model in array) {
        if (![model isKindOfClass:[JDModel class]]) {
            return NO;
        }
    }
    
    for (JDModel *model in array) {
        
        JDMPropertyType *pTypes = (JDMPropertyType *)model.jdm_propertyTypes.bytes;
        
        for (int i=0; i< model.jdm_columeNames.count; i++) {
            
            NSString *columeName = [model.jdm_columeNames objectAtIndex:i];
            JDMPropertyType pType = pTypes[i];
            
            if (pType == JDMPropertyModel) {
                
                JDModel *subModel = [self valueForKey:columeName];
                
                if (subModel && [subModel isKindOfClass:[JDModel class]]) {
                    
                    [subModel deleteObject];
                    
                }
                
            }else if (pType == JDMPropertyModelArray || pType == JDMPropertyMutableModelArray) {
                
                NSMutableArray *subModels = [model valueForKey:columeName];
                
                for (JDModel *subModel in subModels) {
                    
                    if (subModel && [subModel isKindOfClass:[JDModel class]]) {
                        
                        [subModel deleteObject];
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    
    __block BOOL res = YES;
    JDMHelper *jkDB = [JDMHelper shareInstance];
    // 如果要支持事务
    [jkDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (JDModel *model in array) {
            NSString *tableName = NSStringFromClass(model.class);
            id primaryValue = [model valueForKey:JDM_primaryId];
            if (!primaryValue || primaryValue <= 0) {
                return ;
            }
            
            NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",tableName, JDM_primaryId];
            BOOL flag = [db executeUpdate:sql withArgumentsInArray:@[primaryValue]];
            NSLog(flag?@"删除成功":@"删除失败");
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    return res;
}

/** 通过条件删除数据 */
+ (BOOL)deleteObjectsByCriteria:(NSString *)criteria
{
    
    return [self deleteObjects:[self findByCriteria:criteria]];
    
}

/** 通过条件删除 (多参数）--2 */
+ (BOOL)deleteObjectsWithFormat:(NSString *)format, ...
{
    va_list ap;
    va_start(ap, format);
    NSString *criteria = [[NSString alloc] initWithFormat:format locale:[NSLocale currentLocale] arguments:ap];
    va_end(ap);
    
    return [self deleteObjectsByCriteria:criteria];
}

/** 清空表 */
+ (BOOL)clearTable
{
    JDMHelper *jkDB = [JDMHelper shareInstance];
    __block BOOL res = NO;
    JDModel *model = [[[self class] alloc]init];
    
    for (int i=0; i< model.jdm_columeNames.count; i++) {
        
        NSString *columeName = [model.jdm_columeNames objectAtIndex:i];
        Class modelClass = model.jdm_subModelClasses[columeName];
        
        if (modelClass) {
            
            [modelClass clearTable];
            
        }
    }
    
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@",tableName];
        res = [db executeUpdate:sql];
        NSLog(res?@"清空成功":@"清空失败");
    }];
    
    return res;
}

/** 查询全部数据 */
+ (NSArray *)findAll
{
    NSLog(@"jkdb---%s",__func__);
    JDMHelper *jkDB = [JDMHelper shareInstance];
    __block NSArray *models = [NSArray array];
    
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@",tableName];
        FMResultSet *resultSet = [db executeQuery:sql];
        models = dataToModel(resultSet, self);
    }];
    
    models = dataToSubModel(models);
    
    return models;
}

+ (instancetype)findFirstWithFormat:(NSString *)format, ...
{
    va_list ap;
    va_start(ap, format);
    NSString *criteria = [[NSString alloc] initWithFormat:format locale:[NSLocale currentLocale] arguments:ap];
    va_end(ap);
    
    return [self findFirstByCriteria:criteria];
}

/** 查找某条数据 */
+ (instancetype)findFirstByCriteria:(NSString *)criteria
{
    NSArray *results = [self.class findByCriteria:criteria];
    if (results.count < 1) {
        return nil;
    }
    
    return [results firstObject];
}

+ (instancetype)findByPK:(long long)inPk
{
    NSString *condition = [NSString stringWithFormat:@"WHERE %@=%lld", JDM_primaryId,inPk];
    return [self findFirstByCriteria:condition];
}

+ (NSArray *)findWithFormat:(NSString *)format, ...
{
    va_list ap;
    va_start(ap, format);
    NSString *criteria = [[NSString alloc] initWithFormat:format locale:[NSLocale currentLocale] arguments:ap];
    va_end(ap);
    
    return [self findByCriteria:criteria];
}

/** 通过条件查找数据 */
+ (NSArray *)findByCriteria:(NSString *)criteria
{
    JDMHelper *jkDB = [JDMHelper shareInstance];
    __block NSArray *models = [NSArray array];
    
    [jkDB.dbQueue inDatabase:^(FMDatabase *db) {
        
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ %@",tableName,criteria];
        FMResultSet *resultSet = [db executeQuery:sql];
        models = dataToModel(resultSet, self);
        
    }];
    
    models = dataToSubModel(models);
    
    return models;
}

#pragma mark - util method
+ (NSString *)getColumeAndTypeString
{
    NSMutableString* pars = [NSMutableString string];
    NSDictionary *dict = [self.class getAllProperties];
    
    NSMutableArray *proNames = [dict objectForKey:@"name"];
    NSMutableArray *proTypes = [dict objectForKey:@"type"];
    
    for (int i=0; i< proNames.count; i++) {
        [pars appendFormat:@"%@ %@",[proNames objectAtIndex:i],[proTypes objectAtIndex:i]];
        if(i+1 != proNames.count)
        {
            [pars appendString:@","];
        }
    }
    return pars;
}

- (NSString *)description
{
    NSString *result = @"";
    NSDictionary *dict = [self.class getAllProperties];
    NSMutableArray *proNames = [dict objectForKey:@"name"];
    for (int i = 0; i < proNames.count; i++) {
        NSString *proName = [proNames objectAtIndex:i];
        id  proValue = [self valueForKey:proName];
        result = [result stringByAppendingFormat:@"%@:%@\n",proName,proValue];
    }
    return result;
}

#pragma mark - must be override method
/** 如果子类中有一些property不需要创建数据库字段，那么这个方法必须在子类中重写
 */
+ (NSArray *)transients
{
    return [NSArray array];
}


- (void)saveOrUpdateAsync:(void(^)(long long pk))callback{
    
    dispatch_async([self.class JD_Queue], ^{
        
        long long pk = [self saveOrUpdate];
        
        if (callback) {
            callback(pk);
        }
        
    });
    
}

- (void)saveOrUpdateByColumnNameAsync:(NSString*)columnName AndColumnValue:(NSString*)columnValue callback:(void(^)(long long pk))callback{
    
    dispatch_async([self.class JD_Queue], ^{
        
        long long pk = [self saveOrUpdateByColumnName:columnName AndColumnValue:columnValue];
        
        if (callback) {
            callback(pk);
        }
        
    });
    
}

- (void)saveAsync:(void(^)(long long pk))callback{
    
    dispatch_async([self.class JD_Queue], ^{
        
        long long pk = [self save];
        
        if (callback) {
            callback(pk);
        }
        
    });
    
}

+ (void)saveObjectsAsync:(NSArray *)array callback:(void(^)(NSMutableArray * pks))callback{
    
    dispatch_async([self.class JD_Queue], ^{
        
        NSMutableArray *pks = [self saveObjects:array];
        
        if (callback) {
            callback(pks);
        }
        
    });
    
}
- (void)updateAsync:(void(^)(long long pk))callback{
    
    dispatch_async([self.class JD_Queue], ^{
        
        long long pk = [self update];
        
        if (callback) {
            callback(pk);
        }
        
    });
    
}

+ (void)updateObjectsAsync:(NSArray *)array callback:(void(^)(NSMutableArray * pks))callback{
    
    dispatch_async([self.class JD_Queue], ^{
        
        NSMutableArray *pks = [self updateObjects:array];
        
        if (callback) {
            callback(pks);
        }
        
    });
    
}

- (void)deleteObjectAsync:(void(^)(BOOL isSuccessed))callback{
    
    dispatch_async([self.class JD_Queue], ^{
        
        BOOL isSuccessed = [self deleteObject];
        
        if (callback) {
            callback(isSuccessed);
        }
        
    });
    
}

+ (void)deleteObjectsAsync:(NSArray *)array callback:(void(^)(BOOL isSuccessed))callback{
    
    dispatch_async([self.class JD_Queue], ^{
        
        BOOL isSuccessed = [self deleteObjects:array];
        
        if (callback) {
            callback(isSuccessed);
        }
        
    });
    
}

+ (void)deleteObjectsByCriteriaAsync:(NSString *)criteria callback:(void(^)(BOOL isSuccessed))callback{
    
    dispatch_async([self.class JD_Queue], ^{
        
        BOOL isSuccessed = [self deleteObjectsByCriteria:criteria];
        
        if (callback) {
            callback(isSuccessed);
        }
        
    });
    
}

+ (void)deleteObjectsWithFormatAsync:(void(^)(BOOL isSuccessed))callback format:(NSString *)format, ...{
    
    
    va_list ap;
    va_start(ap, format);
    NSString *criteria = [[NSString alloc] initWithFormat:format locale:[NSLocale currentLocale] arguments:ap];
    va_end(ap);
    
    dispatch_async([self.class JD_Queue], ^{
        
        BOOL isSuccessed = [self deleteObjectsWithFormat:criteria];
        
        if (callback) {
            callback(isSuccessed);
        }
        
    });
    
}

+ (void)clearTableAsync:(void(^)(BOOL isSuccessed))callback{
    
    dispatch_async([self.class JD_Queue], ^{
        
        BOOL isSuccessed = [self clearTable];
        
        if (callback) {
            callback(isSuccessed);
        }
        
    });
    
}

+ (void)findAllAsync:(void(^)(NSArray *models))callback{
    
    dispatch_async([self.class JD_Queue], ^{
        
        NSArray *models = [self findAll];
        
        if (callback) {
            callback(models);
        }
        
    });
    
}

+ (void)findByPK:(long long)inPk callback:(void(^)(JDModel *model))callback{
    
    dispatch_async([self.class JD_Queue], ^{
        
        JDModel *model = [self findByPK:inPk];
        
        if (callback) {
            callback(model);
        }
        
    });
    
}

+ (void)findFirstWithFormatAsync:(void(^)(JDModel *model))callback format:(NSString *)format, ...{
    
    va_list ap;
    va_start(ap, format);
    NSString *criteria = [[NSString alloc] initWithFormat:format locale:[NSLocale currentLocale] arguments:ap];
    va_end(ap);
    
    dispatch_async([self.class JD_Queue], ^{
        
        JDModel *model = [self findFirstWithFormat:criteria];
        
        if (callback) {
            callback(model);
        }
        
    });
    
}

+ (void)findFirstByCriteriaAsync:(NSString *)criteria callback:(void(^)(JDModel *model))callback{
    
    dispatch_async([self.class JD_Queue], ^{
        
        JDModel *model = [self findFirstByCriteria:criteria];
        
        if (callback) {
            callback(model);
        }
        
    });
    
}

+ (void)findWithFormatAsync:(void(^)(NSArray *models))callback format:(NSString *)format, ...{
    
    va_list ap;
    va_start(ap, format);
    NSString *criteria = [[NSString alloc] initWithFormat:format locale:[NSLocale currentLocale] arguments:ap];
    va_end(ap);
    
    dispatch_async([self.class JD_Queue], ^{
        
        NSArray *models = [self findWithFormat:criteria];
        
        if (callback) {
            callback(models);
        }
        
    });
    
}

+ (void)findByCriteriaAsync:(NSString *)criteria callback:(void(^)(NSArray *models))callback{
    
    dispatch_async([self.class JD_Queue], ^{
        
        NSArray *models = [self findByCriteria:criteria];
        
        if (callback) {
            callback(models);
        }
        
    });
    
}

@end

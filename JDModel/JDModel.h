//
//  JDModel.h
//  JDModelDemo
//
//  Created by SC on 16/8/18.
//  Copyright © 2016年 SDJY. All rights reserved.
//

#import <Foundation/Foundation.h>
/** SQLite五种数据类型 */
#define JDM_SQLTEXT     @"TEXT"
#define JDM_SQLINTEGER  @"INTEGER"
#define JDM_SQLREAL     @"REAL"
#define JDM_SQLBLOB     @"BLOB"
#define JDM_SQLNULL     @"NULL"
#define JDM_PrimaryKey  @"primary key"

#define JDM_primaryId   @"pk"

#define JDM_ARRAY_TYPE(JDM_OBJECT_SUBCLASS)\
@protocol JDM_OBJECT_SUBCLASS <NSObject>   \
@end

typedef NS_ENUM(uint8_t,JDMPropertyType) {
    JDMPropertyText = 1,
    JDMPropertyInteger,
    JDMPropertyReal,
    JDMPropertyModel,
    JDMPropertyModelArray,
    JDMPropertyMutableModelArray,
    JDMPropertyArray,
    JDMPropertyMutableArray,
    JDMPropertyBlob,
};

@protocol JDModel <NSObject>

@end

@interface JDModel : NSObject

/** 主键 id */
@property (nonatomic, assign) long long        pk;
/** 列名 */
@property (retain, readonly, nonatomic) NSArray         *jdm_columeNames;
/** 列类型 */
@property (retain, readonly, nonatomic) NSData          *jdm_propertyTypes;

@property (retain, readonly, nonatomic) NSDictionary    *jdm_subModelClasses;

/**
 *  获取该类的所有属性
 */
+ (NSDictionary *)getPropertys;

/** 获取所有属性，包括主键 */
+ (NSDictionary *)getAllProperties;

/** 数据库中是否存在表 */
+ (BOOL)isExistInTable;

/** 表中的字段*/
+ (NSArray *)getColumns;

/** 保存或更新
 * 如果不存在主键，保存，
 * 有主键，则更新
 */
- (long long)saveOrUpdate;

- (void)saveOrUpdateAsync:(void(^)(long long pk))callback;

/** 保存或更新
 * 如果根据特定的列数据可以获取记录，则更新，
 * 没有记录，则保存
 */
- (long long)saveOrUpdateByColumnName:(NSString*)columnName AndColumnValue:(NSString*)columnValue;

- (void)saveOrUpdateByColumnNameAsync:(NSString*)columnName AndColumnValue:(NSString*)columnValue callback:(void(^)(long long pk))callback;

/** 保存单个数据 */
- (long long)save;

- (void)saveAsync:(void(^)(long long pk))callback;

/** 批量保存数据 */
+ (NSMutableArray *)saveObjects:(NSArray *)array;

+ (void)saveObjectsAsync:(NSArray *)array callback:(void(^)(NSMutableArray * pks))callback;

/** 更新单个数据 */
- (long long)update;

- (void)updateAsync:(void(^)(long long pk))callback;

/** 批量更新数据*/
+ (NSMutableArray *)updateObjects:(NSArray *)array;

+ (void)updateObjectsAsync:(NSArray *)array callback:(void(^)(NSMutableArray * pks))callback;

/** 删除单个数据 */
- (BOOL)deleteObject;

- (void)deleteObjectAsync:(void(^)(BOOL isSuccessed))callback;

/** 批量删除数据 */
+ (BOOL)deleteObjects:(NSArray *)array;

+ (void)deleteObjectsAsync:(NSArray *)array callback:(void(^)(BOOL isSuccessed))callback;

/** 通过条件删除数据 */
+ (BOOL)deleteObjectsByCriteria:(NSString *)criteria;

+ (void)deleteObjectsByCriteriaAsync:(NSString *)criteria callback:(void(^)(BOOL isSuccessed))callback;

/** 通过条件删除 (多参数）--2 */
+ (BOOL)deleteObjectsWithFormat:(NSString *)format, ...;

+ (void)deleteObjectsWithFormatAsync:(void(^)(BOOL isSuccessed))callback format:(NSString *)format, ...;

/** 清空表 */
+ (BOOL)clearTable;

+ (void)clearTableAsync:(void(^)(BOOL isSuccessed))callback;

/** 查询全部数据 */
+ (NSArray *)findAll;

+ (void)findAllAsync:(void(^)(NSArray *models))callback;

/** 通过主键查询 */
+ (instancetype)findByPK:(long long)inPk;

+ (void)findByPK:(long long)inPk callback:(void(^)(JDModel *model))callback;

+ (instancetype)findFirstWithFormat:(NSString *)format, ...;

+ (void)findFirstWithFormatAsync:(void(^)(JDModel *model))callback format:(NSString *)format, ...;

/** 查找某条数据 */
+ (instancetype)findFirstByCriteria:(NSString *)criteria;

+ (void)findFirstByCriteriaAsync:(NSString *)criteria callback:(void(^)(JDModel *model))callback;

+ (NSArray *)findWithFormat:(NSString *)format, ...;

+ (void)findWithFormatAsync:(void(^)(NSArray *models))callback format:(NSString *)format, ...;

/** 通过条件查找数据
 * 这样可以进行分页查询 @" WHERE pk > 5 limit 10"
 */
+ (NSArray *)findByCriteria:(NSString *)criteria;

+ (void)findByCriteriaAsync:(NSString *)criteria callback:(void(^)(NSArray *models))callback;
/**
 * 创建表
 * 如果已经创建，返回YES
 */
+ (BOOL)createTable;

#pragma mark - must be override method
/** 如果子类中有一些property不需要创建数据库字段，那么这个方法必须在子类中重写
 */
+ (NSArray *)transients;

@end

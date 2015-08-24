#import <Foundation/Foundation.h>

@interface QBaseSqlGenerator : NSObject

#pragma mark - 表操作

/** 数据表是否存在 */
+ (NSString *)sql_IsExistTable:(Class)qbase_class;

/** 建表 */
+ (NSString *)sql_CreateTable:(Class)qbase_class;

/** 删表 */
+ (NSString *)sql_DropTable:(Class)qbase_class;

/** 创建唯一索引 */
+ (NSString *)sql_CreateUniqueIndex:(Class)qbase_class indexName:(NSString *)indexName;


#pragma mark - 增删改 - JsonValue

/** 增 */
+ (NSString *)sql_InsertTable:(Class)qbase_class
                    jsonValue:(NSDictionary *)jsonValue;

/** 删 */
+ (NSString *)sql_DelegateTable:(Class)qbase_class
                      condition:(NSObject *)conditions;

/** 改 */
+ (NSString *)sql_UpdateTable:(Class)qbase_class
                    jsonValue:(NSDictionary *)jsonValue;


#pragma mark - 查询语句

/** 查询个数 */
+ (NSString *)sql_QueryCount:(Class)qbase_class
                  conditions:(NSString *)conditions;

/** 查询所有 */
+ (NSString *)sql_QueryAll:(Class)qbase_class;

/** 条件查询 */
+ (NSString *)sql_QueryAll:(Class)qbase_class
                 condition:(NSString *)conditions
                     order:(NSString *)order;

/** 条件查询 */
+ (NSString *)sql_QueryAll:(Class)qbase_class
                 condition:(NSString *)conditions
                     order:(NSString *)order
                     limit:(NSInteger)limit;
@end

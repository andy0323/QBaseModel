#import "QBaseSqlGenerator.h"

#import <objc/runtime.h>
#import <objc/message.h>

/** 类型参数 */
#define qbase_bool      @"B"
#define qbase_char      @"c"
#define qbase_short     @"s"
#define qbase_int       @"i"
#define qbase_float     @"f"
#define qbase_double    @"d"
#define qbase_long      @"l"
#define qbase_long_long @"q"
#define qbase_object    @"@"

/** 配置主键. 忽略扩展 */
#ifndef Q_PRIMARY_KEY
    #define Q_PRIMARY_KEY     @"qbase_id"
    #define Q_IGNORE_PREFIX_KEY @"_"
#endif

@implementation QBaseSqlGenerator

#pragma mark - 表操作

/** 数据表是否存在 */
+ (NSString *)sql_IsExistTable:(Class)qbase_class
{
    NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) AS 'count' FROM sqlite_master WHERE type ='table' AND name = '%@'", qbase_class];
    return sql;
}

/**  
 *  创建数据表
 */
+ (NSString *)sql_CreateTable:(Class)qbase_class
{
    NSMutableString *sql = [NSMutableString string];;
    [sql appendFormat:@"CREATE TABLE IF NOT EXISTS %@(",[qbase_class class]];

    NSMutableArray *keys = [NSMutableArray array];
    
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList(qbase_class, &count);
    
    BOOL haveKey = NO;
    NSString *primary=@"";
    for (int i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        NSString *name = [NSString stringWithUTF8String:property_getName(property)];
        NSString *attr = [NSString stringWithUTF8String:property_getAttributes(property)];

        if ([name hasPrefix:Q_IGNORE_PREFIX_KEY]) {
            continue;
        }
        
        NSString *classType = [attr substringWithRange:NSMakeRange(1, 1)];
        if ([name isEqualToString:Q_PRIMARY_KEY]) {
            haveKey = YES;
            primary=@"PRIMARY KEY AUTOINCREMENT DEFAULT NULL";
        }
        
        if ([classType isEqualToString:qbase_long] ||
            [classType isEqualToString:qbase_long_long] ||
            [classType isEqualToString:qbase_int]) {
            [keys addObject:[NSString stringWithFormat:@"%@ INTEGER %@", name, primary]];
        }else if([classType isEqualToString:qbase_object]) {
            if ([attr length] > 12 && [[attr substringToIndex:12] isEqualToString:@"T@\"NSString\""])
            {
                [keys addObject:[NSString stringWithFormat:@"%@ TEXT ", name]];
            }
        }else if ([classType isEqualToString:qbase_float] ||
                  [classType isEqualToString:qbase_double]) {
            [keys addObject:[NSString stringWithFormat:@"%@ REAL ", name]];
        }else if ([classType isEqualToString:qbase_short] ||
                  [classType isEqualToString:qbase_char]) {
            [keys addObject:[NSString stringWithFormat:@"%@ INTEGER", name]];
        }
    }
    
    if (haveKey) {
        [sql appendString:[keys componentsJoinedByString:@","]];
    }else {
        [sql appendFormat:@"%@ INTEGER PRIMARY KEY AUTOINCREMENT DEFAULT NULL, %@",Q_PRIMARY_KEY, [keys componentsJoinedByString:@","]];
    }
    
    free(properties);
    [sql appendString:@")"];
    return sql;
}

/** 销毁数据表 */
+ (NSString *)sql_DropTable:(Class)qbase_class
{
    return [NSString stringWithFormat:@"DROP TABLE %@", [qbase_class class]];
}

/**
 *  创建唯一索引
 */
+ (NSString *)sql_CreateUniqueIndex:(Class)qbase_class indexName:(NSString *)indexName
{
    NSString *sql = [NSString stringWithFormat:
                     @"CREATE UNIQUE INDEX idx_%@ ON %@(%@)",
                     indexName, NSStringFromClass([self class]), indexName];
    return sql;
}


#pragma mark -
#pragma mark 增

+ (NSString *)sql_InsertTable:(Class)qbase_class jsonValue:(NSDictionary *)jsonValue
{
    NSMutableDictionary *mJsonValue = jsonValue.mutableCopy;
    
    NSMutableString *sql = [NSMutableString string];
    [sql appendFormat:@"INSERT INTO %@(", [qbase_class class]];
    
    NSMutableArray *keys = [NSMutableArray array];
    
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList(qbase_class, &count);
    
    NSMutableArray *nameArray = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        NSString *name = [NSString stringWithUTF8String:property_getName(property)];
        [nameArray addObject:name];
        
        if ([name hasPrefix:Q_IGNORE_PREFIX_KEY]) {
            continue;
        }
        
        if (!mJsonValue[name] || ![mJsonValue.allKeys containsObject:name]) {
            continue;
        }
        
        if (![name hasPrefix:Q_PRIMARY_KEY]) {
            [keys addObject:name];
        }
    }
    [mJsonValue enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![nameArray containsObject:key]) {
            [mJsonValue removeObjectForKey:key];
        }
    }];
    
    [sql appendString:[keys componentsJoinedByString:@","]];
    [sql appendString:@") VALUES("];
    
    int i = 0;
    for (NSString *key in keys) {
        if (i++) {
            [sql appendString:@","];
        }
        [sql appendFormat:@":%@", key];
    }
    
    [sql appendString:@")"];
    free(properties);
    return sql;
}

#pragma mark -
#pragma mark 删

+ (NSString *)sql_DelegateTable:(Class)qbase_class condition:(NSString *)conditions
{
    NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM %@", [qbase_class class]];
    if (conditions) {
        [sql appendFormat:@" WHERE %@", conditions];
    }
    return sql;
}

#pragma mark -
#pragma mark 改

+ (NSString *)sql_UpdateTable:(Class)qbase_class jsonValue:(NSDictionary *)jsonValue
{
    NSMutableDictionary *mJsonValue = jsonValue.mutableCopy;

    NSMutableString *sql = [NSMutableString string];
    [sql appendFormat:@"UPDATE %@ SET ", [qbase_class class]];
    
    NSMutableArray *keys = [NSMutableArray array];
    
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList(qbase_class, &count);
    
    NSMutableArray *nameArray = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        NSString *name = [NSString stringWithUTF8String:property_getName(property)];
        [nameArray addObject:name];
        
        if (!mJsonValue[name] || ![mJsonValue.allKeys containsObject:name]) {
            continue;
        }
        
        if ([name hasPrefix:Q_PRIMARY_KEY]) {
            continue;
        }
        
        [keys addObject:name];
    }
    
    for (NSString *key in mJsonValue.allKeys) {
        if (![nameArray containsObject:key] && ![key isEqual:Q_PRIMARY_KEY]) {
            [mJsonValue removeObjectForKey:key];
        }
    }
    
    int i = 0;
    for (NSString *key in keys) {
        if (i++) {
            [sql appendString:@","];
        }
        
        [sql appendFormat:@"%@=:%@", key, key];
    }
    
    [sql appendFormat:@" WHERE %@=:%@", Q_PRIMARY_KEY, Q_PRIMARY_KEY];
    free(properties);
    return sql;
}

#pragma mark -
#pragma mark 查

/// 查询个数
+ (NSString *)sql_QueryCount:(Class)qbase_class conditions:(NSString *)conditions
{
    NSMutableString *sql = [NSMutableString stringWithFormat:@"SELECT COUNT(*) FROM %@", [qbase_class class]];
    if (conditions) {
        [sql appendFormat:@" WHERE %@", conditions];
    }
    return sql;
}

/// 查询所有
+ (NSString *)sql_QueryAll:(Class)qbase_class
{
    return [self sql_QueryAll:qbase_class condition:nil order:nil limit:0];
}


/// 条件查询
+ (NSString *)sql_QueryAll:(Class)qbase_class
                 condition:(NSString *)conditions
                     order:(NSString *)order
{
    return [self sql_QueryAll:qbase_class condition:conditions order:order limit:0];
}

/// 条件查询
+ (NSString *)sql_QueryAll:(Class)qbase_class condition:(NSString *)conditions order:(NSString *)order limit:(NSInteger)limit
{
    NSMutableString *sql = [NSMutableString stringWithFormat:@"SELECT * FROM %@", [qbase_class class]];
    if (conditions) {
        [sql appendFormat:@" WHERE %@", conditions];
    }
    
    if (order.length) {
        [sql appendFormat:@" ORDER BY %@", order];
    }
    
    if (limit) {
        [sql appendFormat:@" LIMIT %ld", limit];
    }
    
    return sql;
}

@end

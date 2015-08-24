#import <Foundation/Foundation.h>
#import "QBaseDatabaseObject.h"

#import "FMDB.h"
typedef FMResultSet QBaseResultSet;

/**
 *  数据库工具类
 */
@interface QBaseDatabase : FMDatabaseQueue

/** 获取数据库对象.
 *  初始化以后，需自定义路径，请调用 [[QBaseDatabase sharedDatabase] checkout:$PATH]，否则其他操作无效. 
 *  注意：check配置一次以后，客户端会记录下用户当前的数据路径，以后启动初始化则会自动使用路径，想要覆盖则再次调用该方法。
 */
+ (QBaseDatabase *)sharedDatabase;


/** 数据库切换操作. 
 *  正常使用可以直接使用默认数据库，不需要进行该函数操作，当出现一个用户数据需要进行一个.db文件进行存储的情况下，可以使用该函数进行切换数据库. 保证不同用户下的数据分离.
 *  注意：check配置一次以后，客户端会记录下用户当前的数据路径，以后启动初始化则会自动使用路径，想要覆盖则再次调用该方法。
 */
- (void)checkout:(NSString *)dbPath;


#pragma mark - 表操作基础能力

/** 是否存在该类对应的数据表 */
- (BOOL)db_isExistTable:(Class)qbase_Class;

/** 创建数据表*/
- (BOOL)db_CreateTable:(Class)qbase_Class;

/** 销毁数据表 */
- (BOOL)db_DropTable:(Class)qbase_Class;

/** 为数据表创建唯一索引 **/
- (BOOL)db_CreateUniqueIndex:(Class)qbase_Class uniqueIndex:(NSString *)uniqueIndex;


#pragma mark - 数据库基础操作（增删改查）

/** 数据库插入一条数据信息 */
- (BOOL)db_InsertTable:(NSObject<QBaseDatabaseObject> *)object;

/** 数据库更新一条数据信息 */
- (BOOL)db_UpdateTable:(NSObject<QBaseDatabaseObject> *)object;

/** 数据库删除一条信息 
    若 where=nil，则会清空所有数据
 */
- (BOOL)db_DeleteTable:(NSObject<QBaseDatabaseObject> *)object where:(NSString *)where;

/** 数据库条件查询信息
    若 where=nil，则会查出所有数据
 */
- (NSArray *)db_SelectTable:(Class)qbase_Class where:(NSString *)where offset:(NSInteger)offset limit:(NSInteger)limit order:(NSString *)order;

/** 查询数据库内容条数 */
- (NSInteger)db_SelectCount:(Class)qbase_Class where:(NSString *)where;

@end

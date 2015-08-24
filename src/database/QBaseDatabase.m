#import "QBaseDatabase.h"
#import "QBaseSqlGenerator.h"
#import "NSObject+QBaseRuntime.h"

/** 当切换数据库时，缓存每个不同类型的数据库的最近打开.db文件路径。每个不同类型的数据库创建只要继承QBaseDatabase，然后创建一个对应的数据库，里面的表名有相应的配置文件构成。而该函数则是生成查询Key的方法*/
#define Q_DB_PATH_KEY(__class) \
    ([NSString stringWithFormat:@"Q_DB_PATH_KEY_%@", __class])

@interface QBaseDatabase ()

@end

@implementation QBaseDatabase

- (instancetype)initWithPath:(NSString *)path
{
    // 数据库上级目录不存在，自动创建路径
    qbase_mkdir(path);
    
    // 创建数据库
    if (self = [super initWithPath:path]) {
    
    }
    return self;
}

static QBaseDatabase *db;
+ (QBaseDatabase *)sharedDatabase
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 如果有缓存数据库
        NSString *dbPath = [self objectForKey:Q_DB_PATH_KEY([self class])];
        if (dbPath) {
            db = [[self alloc] initWithPath:dbPath];
        }else {
            db = [[self alloc] init];
        }
    });
    return db;
}


#pragma mark -
#pragma mark 表操作基础能力

/**
 *  切换数据库路径
 */
- (void)checkout:(NSString *)dbPath
{
    if ([db openFlags]) {
        [db close];
        db = nil;
    }
    
    // 重新开启客户端
    db = [[[self class] alloc] initWithPath:dbPath];
    
    // 初始化数据表
    [self loadDBConfig];
    
    // 记录数据库路径
    [QBaseDatabase setObject:dbPath forKey:Q_DB_PATH_KEY([self class])];
}

/**
 *  是否存在该类对应的数据表
 */
- (BOOL)db_isExistTable:(Class)qbase_Class
{
    NSString *sql = [QBaseSqlGenerator sql_IsExistTable:qbase_Class];
    QBaseResultSet *set = [self executeQuery:sql];
    
    while ([set next]) {
        NSInteger count = [set intForColumn:@"count"];
        if (count == 0) return NO;
        else return YES;
    }
    return NO;
}

/**
 *  创建数据表
 */
- (BOOL)db_CreateTable:(Class)qbase_Class
{
    NSString *sql = [QBaseSqlGenerator sql_CreateTable:qbase_Class];
    return [db executeUpdate:sql, nil];

}

/**
 *  销毁数据表
 */
- (BOOL)db_DropTable:(Class)qbase_Class
{
    NSString *sql = [QBaseSqlGenerator sql_DropTable:qbase_Class];
    return [db executeUpdate:sql, nil];
}

/**
 *  为数据表创建唯一索引
 */
- (BOOL)db_CreateUniqueIndex:(Class)qbase_Class uniqueIndex:(NSString *)uniqueIndex
{
    NSString *sql = [QBaseSqlGenerator sql_CreateUniqueIndex:qbase_Class
                                                   indexName:uniqueIndex];
    return [db executeUpdate:sql, nil];
}


#pragma mark -
#pragma mark 数据库基础操作（增删改查）

/**
 *  数据库插入一条数据信息
 */
- (BOOL)db_InsertTable:(NSObject<QBaseDatabaseObject> *)object
{
    NSDictionary *json = [object qbase_JsonValue];
    NSString *sql = [QBaseSqlGenerator sql_InsertTable:object.class jsonValue:json];
    return [db executeUpdate:sql withParameterDictionary:json];
}

/**
 *  数据库更新一条数据信息
 */
- (BOOL)db_UpdateTable:(NSObject<QBaseDatabaseObject> *)object
{
    NSDictionary *json = [object qbase_JsonValue];
    NSString *sql = [QBaseSqlGenerator sql_UpdateTable:object.class jsonValue:json];
    return [db executeUpdate:sql withParameterDictionary:json];
}

/**
 *  数据库删除一条信息
 */
- (BOOL)db_DeleteTable:(NSObject<QBaseDatabaseObject> *)object where:(NSString *)where
{
    NSString *sql = [QBaseSqlGenerator sql_DelegateTable:object.class condition:where];
    return [db executeUpdate:sql, nil];
}

/**
 *  数据库条件查询信息
 */
- (NSArray *)db_SelectTable:(Class)qbase_Class where:(NSString *)where offset:(NSInteger)offset limit:(NSInteger)limit order:(NSString *)order
{
    NSString *sql = [QBaseSqlGenerator sql_QueryAll:qbase_Class condition:where order:order limit:limit];
    QBaseResultSet *set = [db executeQuery:sql];
    return [db convert:qbase_Class resultSet:set];
}

/** 
 * 查询数据库内容条数 
 */
- (NSInteger)db_SelectCount:(Class)qbase_Class where:(NSString *)where
{
    NSString *sql = [QBaseSqlGenerator sql_QueryCount:qbase_Class conditions:where];
    return [self intForQuery:sql];
}


#pragma mark -
#pragma mark FMDBQueue DB基层处理

/**
 *  查询语句
 */
- (QBaseResultSet *)executeQuery:(NSString *)sql, ...
{
    __block QBaseResultSet *set = nil;
    [self inDatabase:^(FMDatabase *db) {
        set = [db executeQuery:sql];
    }];
    return set;
}

/**
 *  查询数据源个数
 */
- (NSInteger)intForQuery:(NSString *)sql, ...
{
    __block int count = 0;
    [self inDatabase:^(FMDatabase *db) {
        count = [db intForQuery:sql];
    }];
    return count;
}

/**
 *  SQL执行
 */
- (BOOL)executeUpdate:(NSString *)sql, ...
{
    __block BOOL success;
    [self inDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:sql];
    }];
    return success;
}

/**
 *  SQL执行
 */
- (BOOL)executeUpdate:(NSString *)sql withParameterDictionary:(NSDictionary *)arguments
{
    __block BOOL success;
    [self inDatabase:^(FMDatabase *db) {
        success = [db executeUpdate:sql withParameterDictionary:arguments];
    }];
    return success;
}


#pragma mark -
#pragma mark Helper

/**
 *  创建数据库所在的文件夹
 */
BOOL qbase_mkdir(NSString *dbPath)
{
    NSFileManager *fs = [NSFileManager defaultManager];
    
    NSMutableArray *components = [fs componentsToDisplayForPath:dbPath].mutableCopy;

    int i = 0;
    NSMutableString *dirPath = [NSMutableString string];
    for (NSString *component in components) {
        if (i++ == 0) continue;
        if (i == components.count) break;
        
        [dirPath appendFormat:@"/%@", component];
    }
    
    if ([fs fileExistsAtPath:dirPath]) {
        return YES;
    }
    
    return [fs createDirectoryAtPath:dirPath
         withIntermediateDirectories:YES
                          attributes:nil
                               error:nil];
}

/**
 *  转换元素为QBaseModel
 */
- (NSArray *)convert:(Class)qbase_Class resultSet:(QBaseResultSet *)resultSet
{
    NSMutableArray *array = [NSMutableArray array];
    while ([resultSet next]) {
        NSObject *object = [[[qbase_Class class] alloc] init];
        [object qbase_InitWithJsonValue:[resultSet resultDictionary]];
        [array addObject:object];
    }
    return array;
}

/**
 *  初始化数据表
 */
- (void)loadDBConfig
{
    // 获取配置信息
    NSString *path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@", self.class] ofType:@"plist"];
    
    if (!path) NSAssert(path, @"请配置对应的配置文件. %@.plist", self.class);
    
    NSDictionary *json = [NSDictionary dictionaryWithContentsOfFile:path];
    
    // 数据表列表
    NSArray *list = json[@"tb_list"];
    for (NSDictionary *dict in list) {
        // 表名
        NSString *name = dict[@"tb_name"];
        // 唯一索引列表
        NSArray *uniqueIndexs = dict[@"tb_unique_indexs"];
        
        // 建表
        Class TableClass = NSClassFromString(name);
        if (![db db_isExistTable:TableClass]) {
            [db db_CreateTable:TableClass];
        }
        
        // 创建唯一索引
        for (NSString *uniqueIndex in uniqueIndexs) {
            [db db_CreateUniqueIndex:TableClass uniqueIndex:uniqueIndex];
        }
    }
}

#pragma mark -
#pragma mark Cache

+ (void)setObject:(id)value forKey:(NSString *)defaultName
{
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:defaultName];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (id)objectForKey:(NSString *)defaultName
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:defaultName];
}

@end

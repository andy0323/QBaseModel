#import <Foundation/Foundation.h>
#import "QBaseDatabase.h"

/**
 *  数据模型基类
 */
@interface QBaseModel : NSObject<QBaseDatabaseObject>

//========================================
#pragma mark 协议声明的属性，请不要进行手动修改
//========================================

/** 主键 */
@property (nonatomic, assign) NSInteger qbase_id;

/** 关联表查询，父表中的qbase_id */
@property (nonatomic, assign) NSInteger qbase_pid;

/** 关联表查询，父表中的表名*/
@property (nonatomic, copy) NSString *qbase_parent;



/** 初始化数据模型，传入字段中，key与模型属性匹配，则会进行赋值操作，数据字典中不需要配置 [qbase_id，qbase_pid，qbase_parent]
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

@interface QBaseModel (DBHandler)

/** 数据表插入 */
- (BOOL)db_Insert;

/** 数据表更新 */
- (BOOL)db_Update;

/** 数据表删除*/
- (BOOL)db_Delete;

/** 数据表查询 */
+ (NSArray *)db_SelectWithWhere:(NSString *)where
                         offset:(NSInteger)offset
                          limit:(NSInteger)limit
                          order:(NSString *)order;
@end
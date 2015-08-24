#import <Foundation/Foundation.h>

@protocol QBaseDatabaseObject <NSObject>

@required

/** 主键 */
@property (nonatomic, assign) NSInteger qbase_id;

/** 关联表查询，父表中的qbase_id */
@property (nonatomic, assign) NSInteger qbase_pid;

/** 关联表查询，父表中的表名*/
@property (nonatomic, copy) NSString *qbase_parent;


@optional

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

#import "QBaseModel.h"
#import "NSObject+QBaseRuntime.h"

@implementation QBaseModel

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        _qbase_id = -1;
        
        [self qbase_InitWithJsonValue:dictionary];
    }
    return self;
}

/** 数据表插入 */
- (BOOL)db_Insert
{
    return [[QBaseDatabase sharedDatabase] db_InsertTable:self];
}

/** 数据表更新 */
- (BOOL)db_Update
{
    return [[QBaseDatabase sharedDatabase] db_UpdateTable:self];
}

/** 数据表删除*/
- (BOOL)db_Delete
{
    return [[QBaseDatabase sharedDatabase] db_DeleteTable:self where:[NSString stringWithFormat:@"qbase_id=%ld", self.qbase_id]];
}

/** 数据表查询 */
+ (NSArray *)db_SelectWithWhere:(NSString *)where
                         offset:(NSInteger)offset
                          limit:(NSInteger)limit
                          order:(NSString *)order
{
    return [[QBaseDatabase sharedDatabase] db_SelectTable:self
                                                    where:where
                                                   offset:offset
                                                    limit:limit
                                                    order:order];
}
@end

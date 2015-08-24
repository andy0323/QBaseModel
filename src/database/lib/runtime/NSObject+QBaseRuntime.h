#import <Foundation/Foundation.h>

@interface NSObject (QBaseRuntime)

/** 将对象属性转换为字典 */
- (NSDictionary *)qbase_JsonValue;

/** 将字典属性填充到对象 */
- (void)qbase_InitWithJsonValue:(NSDictionary *)jsonValue;

@end

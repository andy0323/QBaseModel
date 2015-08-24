#import "NSObject+QBaseRuntime.h"
#import "QBaseDatabaseObject.h"

#import <objc/runtime.h>
#import <objc/message.h>

#define qbase_bool      @"B"
#define qbase_char      @"c"
#define qbase_short     @"s"
#define qbase_int       @"i"
#define qbase_float     @"f"
#define qbase_double    @"d"
#define qbase_long      @"l"
#define qbase_long_long @"q"
#define qbase_object    @"@"

#define qbase_NSString    @"NSString"

@implementation NSObject (QBaseRuntime)

- (NSDictionary *)qbase_JsonValue
{
    NSMutableDictionary *ret = [[NSMutableDictionary alloc] init];

    // 获取对象属性、属性个数
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList([self class], &propertyCount);

    for (int i = 0; i < propertyCount; i++) {
        // 属性对象
        objc_property_t property = properties[i];
        
        // 属性名称
        NSString *name = [NSString stringWithUTF8String:property_getName(property)];
        
        // 属性值
        NSString *attr = [NSString stringWithUTF8String:property_getAttributes(property)];
        
        // 属性值对应的 get 函数
        SEL selector = NSSelectorFromString(name);
        
        if ([self respondsToSelector:selector])
        {
            NSString *classType = [attr substringWithRange:NSMakeRange(1, 1)];
            
            if ([classType isEqualToString:qbase_object])
            {
                id str = ((id (*)(id obj, SEL selector))objc_msgSend)(self, selector);

                if ([attr length] > 12 && [[attr substringToIndex:12] isEqualToString:@"T@\"NSString\""])
                {
                    [ret setObject:[NSString stringWithFormat:@"%@",str] forKey:name];
                }
            }
            else if ([classType isEqualToString:qbase_int])
            {
                int str = ((int(*)(id obj, SEL selector))objc_msgSend)(self, selector);
                [ret setObject:[NSString stringWithFormat:@"%d", str] forKey:name];
            }
            else if ([classType isEqualToString:qbase_bool])
            {
                bool str = ((bool(*)(id obj, SEL selector))objc_msgSend)(self, selector);
                [ret setObject:[NSString stringWithFormat:@"%d", str] forKey:name];
            }
            else if ([classType isEqualToString:qbase_float])
            {
                float str = ((float(*)(id obj, SEL selector))objc_msgSend)(self, selector);
                [ret setObject:[NSString stringWithFormat:@"%f", str] forKey:name];
            }
            else if ([classType isEqualToString:qbase_double])
            {
                double str = ((double(*)(id obj, SEL selector))objc_msgSend)(self, selector);
                [ret setObject:[NSString stringWithFormat:@"%f",str] forKey:name];
            }
            else if ([classType isEqualToString:qbase_long])
            {
                long str = ((long(*)(id obj, SEL selector))objc_msgSend)(self, selector);
                [ret setObject:[NSString stringWithFormat:@"%ld", str] forKey:name];
            }
            else if ([classType isEqualToString:qbase_long_long])
            {
                long long str = ((long long(*)(id obj, SEL selector))objc_msgSend)(self, selector);
                [ret setObject:[NSString stringWithFormat:@"%lld", str] forKey:name];
            }
            else if ([classType isEqualToString:qbase_char])
            {
                char str = ((char(*)(id obj, SEL selector))objc_msgSend)(self, selector);
                [ret setObject:[NSString stringWithFormat:@"%c", str] forKey:name];
            }
            else if ([classType isEqualToString:qbase_short])
            {
                short str = ((short(*)(id obj, SEL selector))objc_msgSend)(self, selector);
                [ret setObject:[NSString stringWithFormat:@"%d", str] forKey:name];
            }
            else
            {
                NSLog(@"请新增数据类型：%@",classType);
            }
        }
    }
    
    // 这里做处理的原因是. runtime无法获取父类几个核心元素. 需要判断内置
    if ([self conformsToProtocol:@protocol(QBaseDatabaseObject)]) {
        // 调用qbase_id 获取元素值
        SEL method_qbase_id = NSSelectorFromString(@"qbase_id");
        NSInteger qbase_id = ((NSInteger(*)(id obj, SEL selector))objc_msgSend)(self, method_qbase_id);

        // 如果为-1. 则是默认生成的模型. 不是查询出来的模型. 因此跳过
        if (qbase_id >= 0) {
            // 存入qbase_id
            [ret setObject:@(qbase_id) forKey:@"qbase_id"];
            
            // 存入qbase_pid
            SEL method_qbase_pid = NSSelectorFromString(@"qbase_pid");
            NSInteger qbase_pid = ((NSInteger(*)(id obj, SEL selector))objc_msgSend)(self, method_qbase_pid);
            [ret setObject:@(qbase_pid) forKey:@"qbase_pid"];

            // 存入qbase_parent
            SEL method_qbase_parent = NSSelectorFromString(@"qbase_parent");
            id qbase_parent = ((id (*)(id obj, SEL selector))objc_msgSend)(self, method_qbase_parent);
            [ret setObject:[NSString stringWithFormat:@"%@", qbase_parent] forKey:@"method_qbase_parent"];
        }
    }
    
    free(properties);
    return ret;
}

- (void)qbase_InitWithJsonValue:(NSDictionary *)qbase_JsonValue;
{
    for (NSString *key in qbase_JsonValue) {
        // set selector
        NSString *selectorStr = [NSString stringWithFormat:@"set%@%@:",[key substringToIndex:1].uppercaseString, [key substringFromIndex:1]];
        SEL setSelector = NSSelectorFromString(selectorStr);
        
        if ([self respondsToSelector:setSelector]) {
            id value = [qbase_JsonValue objectForKey:key];
            // 获取属性的类型
            NSString *type = [self propertyTypeWithPropertyName:key];
            
            // 类型为字符串
            if ([type isEqualToString:qbase_NSString])
            {
                if (!value || [value isKindOfClass:[NSNull class]]) {
                    value = @"";
                }
                ((void (*)(id obj, SEL selector, NSString *str))objc_msgSend)(self, setSelector, value);
            }
            else
            {
                if (!value || [value isKindOfClass:[NSNull class]])
                {
                    continue;
                }
                else
                {
                    if ([type isEqualToString:qbase_double])
                    {
                        if ([value respondsToSelector:NSSelectorFromString(@"doubleValue")]) {
                            ((void(*)(id, SEL, double))objc_msgSend)(self, setSelector, [value doubleValue]);
                        }
                    }
                    else if ([type isEqualToString:qbase_float])
                    {
                        if ([value respondsToSelector:NSSelectorFromString(@"floatValue")]) {
                            ((void(*)(id, SEL, float))objc_msgSend)(self, setSelector, [value floatValue]);
                        }
                    }
                    else if ([type isEqualToString:qbase_bool])
                    {
                        if ([value respondsToSelector:NSSelectorFromString(@"boolValue")]) {
                            ((void(*)(id, SEL, BOOL))objc_msgSend)(self, setSelector, [value boolValue]);
                        }
                    }
                    else if ([type isEqualToString:qbase_long])
                    {
                        if ([value respondsToSelector:NSSelectorFromString(@"longValue")]) {
                            ((void(*)(id, SEL, long))objc_msgSend)(self, setSelector, [value longValue]);
                        }
                    }
                    else if ([type isEqualToString:qbase_long_long])
                    {
                        if ([value respondsToSelector:NSSelectorFromString(@"longLongValue")]) {
                            ((void(*)(id, SEL, long long))objc_msgSend)(self, setSelector, [value longLongValue]);
                        }
                    }
                    else if ([type isEqualToString:qbase_int])
                    {
                        if ([value respondsToSelector:NSSelectorFromString(@"intValue")]) {
                            ((void(*)(id, SEL, int))objc_msgSend)(self, setSelector, [value intValue]);
                        }
                    }
                    else if ([type isEqualToString:qbase_short])
                    {
                        if ([value respondsToSelector:NSSelectorFromString(@"shortValue")]) {
                            ((void(*)(id, SEL, short))objc_msgSend)(self, setSelector, [value shortValue]);
                        }
                    }
                    else if ([type isEqualToString:qbase_char])
                    {
                        if ([value respondsToSelector:NSSelectorFromString(@"charValue")]) {
                            ((void(*)(id, SEL, char))objc_msgSend)(self, setSelector, [value charValue]);
                        }
                    }
                }
            }
        }
    }
}

/**
 *  获取属性类型
 */
- (NSString *)propertyTypeWithPropertyName:(NSString *)propertyName
{
    NSString *ret = nil;
    
    // 属性对象
    objc_property_t property = class_getProperty(self.class, [propertyName cStringUsingEncoding:NSUTF8StringEncoding]);
    
    // 属性名称
    NSString *name = [NSString stringWithUTF8String:property_getName(property)];
    
    // 属性值
    NSString *attr = [NSString stringWithUTF8String:property_getAttributes(property)];
    
    if ([name isEqualToString:propertyName]) {
        NSString *classType = [attr substringWithRange:NSMakeRange(1, 1)];
        
        if ([classType isEqualToString:qbase_object])
        {
            if ([attr length] > 12 && [[attr substringToIndex:12] isEqualToString:@"T@\"NSString\""])
            {
                ret = qbase_NSString;
            }
        }
        else
        {
            ret = classType;
        }
    }
    
    return ret;
}

@end
#import "QBaseModel.h"

@interface User : QBaseModel

@property (nonatomic, copy) NSString *username;
@property (nonatomic, assign) NSInteger age;

@end

#import "ExampleViewController.h"
#import "HomeViewController.h"
#import "QBaseDatabase.h"

@interface ExampleViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTF;
@end

@implementation ExampleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)initDatabase:(id)sender
{
    if (!_usernameTF.text.length) {
        [[[UIAlertView alloc] initWithTitle:@"提示"
                                    message:@"请输入用户名"
                                   delegate:nil
                          cancelButtonTitle:@"好的"
                          otherButtonTitles:nil, nil] show];
        return;
    }

    // 初始化数据库
    NSString *dbPath = [NSString stringWithFormat:@"/Users/andy/Desktop/QBaseDB_Cache/%@.db", _usernameTF.text];
    [[QBaseDatabase sharedDatabase] checkout:dbPath];

    // 进入首页
    HomeViewController *home = [[HomeViewController alloc] init];
    [self.navigationController pushViewController:home animated:YES];
}

@end

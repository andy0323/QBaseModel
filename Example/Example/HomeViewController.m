#import "HomeViewController.h"
#import "QBaseDatabase.h"

@interface HomeViewController ()<UITableViewDataSource, UITableViewDelegate>

/** 列表 */
@property (nonatomic, strong) UITableView *listView;

/** 数据源 */
@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation HomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 读取配置信息
    NSString *path = [[NSBundle mainBundle] pathForResource:@"QBaseDatabase" ofType:@"plist"];
    NSDictionary *conf = [NSDictionary dictionaryWithContentsOfFile:path];
    
    // 获取数据源
    NSArray *tables = conf[@"tb_list"];
    _dataArray = tables.mutableCopy;

    // UI界面
    _listView = [[UITableView alloc] initWithFrame:self.view.bounds
                                             style:UITableViewStylePlain];
    _listView.delegate = self;
    _listView.dataSource = self;
    [self.view addSubview:_listView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellId = @"UITableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellId];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellId];
    }
 
    // 数据源
    NSDictionary *dic = _dataArray[indexPath.row];

    // 解析
    NSString *name = dic[@"tb_name"];
    
    // 数据库有多少条数据
    Class Schema = NSClassFromString(name);
    NSInteger listCount = [[QBaseDatabase sharedDatabase] db_SelectCount:Schema where:nil];
    
    // 配置参数
    cell.textLabel.text = name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", listCount];
    
    return cell;
}


@end

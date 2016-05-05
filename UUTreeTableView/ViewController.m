//
//  ViewController.m
//  UUTreeTableView
//
//  Created by zhuochenming on 26/12/15.
//  Copyright (c) 2015 zhuochenming. All rights reserved.
//

#import "ViewController.h"
#import "UUTreeTableView.h"

@interface ViewController ()<UUTreeTableViewDelegate>

@property (nonatomic, strong) UUTreeTableView *tableView;

@property (nonatomic, strong) NSArray *contents;

@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation ViewController

- (void)netWorkData {
    self.dataArray = [NSMutableArray array];
    
    TreeTableModel *dataModel = [[TreeTableModel alloc] init];
    dataModel.title = @"医院选择";
    dataModel.shouldExpandSubRows = NO;
    
    [dataModel addSecondDataFromArray:@[@"莆田医院A", @"莆田医院B", @"莆田医院C"]];
    [_dataArray addObject:dataModel];
    
    TreeTableModel *dataModel2 = [[TreeTableModel alloc] init];
    dataModel2.title = @"推广方式";
    dataModel2.shouldExpandSubRows = YES;
    
    [dataModel2 addSecondDataFromArray:@[@"百毒", @"谷歌", @"必应", @"360", @"企鹅"]];

    [_dataArray addObject:dataModel2];
    
    
    TreeTableModel *dataModel3 = [[TreeTableModel alloc] init];
    dataModel3.title = @"大神";
    [dataModel3 addSecondDataFromArray:@[@"风神", @"盗版"]];
    [_dataArray addObject:dataModel3];
    
    TreeTableModel *dataModel4 = [[TreeTableModel alloc] init];
    dataModel4.title = @"大白";
    [dataModel4 addSecondDataFromArray:@[@"小八"]];
    [_dataArray addObject:dataModel4];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = @"UUTableView";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"全部收缩起来" style:UIBarButtonItemStylePlain target:self action:@selector(collapseSubrows)];
    
    self.tableView = [[UUTreeTableView alloc] initWithFrame:self.view.bounds];
    self.tableView.treeDelegate = self;
    [self.view addSubview:_tableView];
    
    [self netWorkData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_dataArray count];
}

- (NSInteger)tableView:(UUTreeTableView *)tableView numberOfSubRowsAtIndexPath:(NSIndexPath *)indexPath {
    TreeTableModel *dataModel = _dataArray[indexPath.row];
    return dataModel.secondCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TreeTableModel *dataModel = _dataArray[indexPath.row];
    static NSString *CellIdentifier = @"WSTableViewCell";
    
    RootLeverTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[RootLeverTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = dataModel.title;
    
    cell.expandable = dataModel.expandable;

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForSubRowAtIndexPath:(NSIndexPath *)indexPath {
    TreeTableModel *dataModel = _dataArray[indexPath.row];
    static NSString *CellIdentifier = @"UITableViewCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    if ([[dataModel getSecondDataWithRow:indexPath.subRow] isKindOfClass:[NSArray class]]) {
        cell.textLabel.text = @"数组";
    } else {
        cell.textLabel.text = [dataModel getSecondDataWithRow:indexPath.subRow];
    }

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (CGFloat)tableView:(UUTreeTableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    TreeTableModel *dataModel = _dataArray[indexPath.row];
    dataModel.shouldExpandSubRows = !dataModel.shouldExpandSubRows;
    
    NSLog(@"Section: %ld, Row:%ld", (long)indexPath.section, (long)indexPath.row);
    
}

- (void)tableView:(UUTreeTableView *)tableView didSelectSubRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Section: %ld, Row:%ld, Subrow:%ld", (long)indexPath.section, (long)indexPath.row, (long)indexPath.subRow);
}

#pragma mark - Actions

- (void)collapseSubrows {
    [self.tableView collapseCurrentlyExpandedIndexPaths];
}

//- (void)refreshData
//{
//    NSArray *array = @[
//                       @[
//                           @[@"Section0_Row0", @"Row0_Subrow1",@"Row0_Subrow2"],
//                           @[@"Section0_Row1", @"Row1_Subrow1", @"Row1_Subrow2", @"Row1_Subrow3", @"Row1_Subrow4", @"Row1_Subrow5", @"Row1_Subrow6", @"Row1_Subrow7", @"Row1_Subrow8", @"Row1_Subrow9", @"Row1_Subrow10", @"Row1_Subrow11", @"Row1_Subrow12"],
//                           @[@"Section0_Row2"]
//                        ]
//                     ];
//    [self reloadTableViewWithData:array];
//    
//    [self setDataManipulationButton:UIBarButtonSystemItemUndo];
//}

//- (void)undoData
//{
//    [self reloadTableViewWithData:nil];
//    
//    [self setDataManipulationButton:UIBarButtonSystemItemRefresh];
//}

//- (void)reloadTableViewWithData:(NSArray *)array
//{
//    self.contents = array;
//    
//    // Refresh data not scrolling
////    [self.tableView refreshData];
//    
//    [self.tableView refreshDataWithScrollingToIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
//}

#pragma mark - Helpers
//
//- (void)setDataManipulationButton:(UIBarButtonSystemItem)item
//{
//    switch (item) {
//        case UIBarButtonSystemItemUndo:
//            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemUndo
//                                                                                                  target:self
//                                                                                                  action:@selector(undoData)];
//            break;
//            
//        default:
//            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
//                                                                                                  target:self
//                                                                                                  action:@selector(refreshData)];
//            break;
//    }
//}

@end

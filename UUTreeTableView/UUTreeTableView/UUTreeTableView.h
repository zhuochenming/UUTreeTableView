//
//  UUTreeTableView.h
//  UUTreeTableView
//
//  Created by zhuochenming on 16/5/5.
//  Copyright © 2016年 zhuochenming. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RootLeverTableViewCell.h"
#import "TreeTableModel.h"

@class UUTreeTableView;
@protocol UUTreeTableViewDelegate <UITableViewDataSource, UITableViewDelegate>

@required
- (NSInteger)tableView:(UUTreeTableView *)tableView numberOfSubRowsAtIndexPath:(NSIndexPath *)indexPath;

- (UITableViewCell *)tableView:(UUTreeTableView *)tableView cellForSubRowAtIndexPath:(NSIndexPath *)indexPath;

@optional
- (CGFloat)tableView:(UUTreeTableView *)tableView heightForSubRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)tableView:(UUTreeTableView *)tableView didSelectSubRowAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)tableView:(UUTreeTableView *)tableView shouldExpandSubRowsOfCellAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface UUTreeTableView : UITableView

@property (nonatomic, weak) id <UUTreeTableViewDelegate> treeDelegate;

//只展开一个cell，默认为NO;
@property (nonatomic, assign) BOOL shouldExpandOnlyOneCell;

- (void)refreshData;

- (void)refreshDataWithScrollingToIndexPath:(NSIndexPath *)indexPath;

- (void)collapseCurrentlyExpandedIndexPaths;

@end

@interface NSIndexPath (UUTreeTableView)

@property (nonatomic, assign) NSInteger subRow;

+ (NSIndexPath *)indexPathForSubRow:(NSInteger)subrow inRow:(NSInteger)row inSection:(NSInteger)section;

@end

//
//  TreeTableModel.h
//  UUTreeTableView
//
//  Created by zhuochenming on 16/5/5.
//  Copyright © 2016年 zhuochenming. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TreeTableModel : NSObject

@property (nonatomic, copy) NSString *title;

//第二级数据个数
@property (nonatomic, assign, readonly) NSInteger secondCount;

//是否支持展开
@property (nonatomic, assign) BOOL expandable;

//是否展开
@property (nonatomic, assign) BOOL shouldExpandSubRows;

//添加二级数据
- (void)addSecondDataFromArray:(NSArray *)secondArray;

//获取某一行二级数据
- (id)getSecondDataWithRow:(NSInteger)row;

- (void)setCheckedSecondLevel:(BOOL)checked withSubRow:(NSInteger)subRow;

- (BOOL)isCheckedSubRow:(NSInteger)subRow;

@end

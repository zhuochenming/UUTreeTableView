//
//  RootLeverTableViewCell.h
//  UUTreeTableView
//
//  Created by zhuochenming on 16/5/5.
//  Copyright © 2016年 zhuochenming. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TreeTableCellLine : UIView

+ (UIColor *)indicatorColor;

+ (void)setIndicatorColor:(UIColor *)indicatorColor;

@end

@interface RootLeverTableViewCell : UITableViewCell

//是否支持展开，如果支持，则添加下箭头
@property (nonatomic, assign, getter = isExpandable) BOOL expandable;

@property (nonatomic, assign, getter = isExpanded) BOOL expanded;

- (void)addIndicatorView;

- (void)removeIndicatorView;

- (BOOL)containsIndicatorView;

- (void)accessoryViewAnimation;

@end
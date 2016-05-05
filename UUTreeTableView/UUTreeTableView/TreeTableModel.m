//
//  TreeTableModel.m
//  UUTreeTableView
//
//  Created by zhuochenming on 16/5/5.
//  Copyright © 2016年 zhuochenming. All rights reserved.
//

#import "TreeTableModel.h"

@interface TreeTableModel ()

@property (nonatomic, strong) NSMutableArray *secondLevelArray;

@end

@implementation TreeTableModel

- (instancetype)init {
    if (self = [super init]) {
        self.secondLevelArray = [NSMutableArray arrayWithCapacity:0];
        self.shouldExpandSubRows = NO;
        self.expandable = NO;
    }
    return self;
}

#pragma mark － 添加第二级数据
- (void)addSecondDataFromArray:(NSArray *)secondArray {
    for (NSInteger i = 0; i < secondArray.count; i++) {        
        if ([secondArray[i] isKindOfClass:[NSArray class]]) {
            NSAssert(NO, @"仅支持二级展开");
        } else {
            NSMutableDictionary *mDic = [[NSMutableDictionary alloc] initWithObjectsAndKeys:secondArray[i], @"secondData", @0, @"isChecked", nil];
            [self.secondLevelArray addObject:mDic];
        }
    }
    self.expandable = YES;
}

#pragma mark － 获取第二级数据
- (id)getSecondDataWithRow:(NSInteger)row {
    if (!self.secondLevelArray || self.secondLevelArray.count == 0) {
        return nil;
    }
    return [self.secondLevelArray[row] objectForKey:@"secondData"];
}

- (void)setCheckedSecondLevel:(BOOL)checked withSubRow:(NSInteger)subRow {
    if (checked) {
        [self.secondLevelArray[subRow] setObject:@1 forKey:@"isChecked"];
    } else {
        [self.secondLevelArray[subRow] setObject:@0 forKey:@"isChecked"];
    }
}
- (BOOL)isCheckedSubRow:(NSInteger)subRow {
    return [[self.secondLevelArray[subRow] objectForKey:@"isChecked"] boolValue];
}

- (NSInteger)secondCount {
    return self.secondLevelArray.count;
}

@end

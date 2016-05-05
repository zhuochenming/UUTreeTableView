//
//  UUTreeTableView.m
//  UUTreeTableView
//
//  Created by zhuochenming on 16/5/5.
//  Copyright © 2016年 zhuochenming. All rights reserved.
//

#import "UUTreeTableView.h"
#import <objc/runtime.h>

static NSString * const kIsExpandedKey = @"isExpanded";
static NSString * const kSubrowsKey = @"subrowsCount";
CGFloat const kDefaultCellHeight = 44.0f;

@interface UUTreeTableView () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, copy) NSMutableDictionary *cellStateDic;

- (NSInteger)numberOfExpandedSubrowsInSection:(NSInteger)section;

- (void)setExpanded:(BOOL)isExpanded forCellAtIndexPath:(NSIndexPath *)indexPath;

- (IBAction)expandableButtonTouched:(id)sender event:(id)event;

- (NSInteger)numberOfSubRowsAtIndexPath:(NSIndexPath *)indexPath;

@end

@implementation UUTreeTableView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        _shouldExpandOnlyOneCell = NO;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _shouldExpandOnlyOneCell = NO;
    }
    
    return self;
}

- (void)setTreeDelegate:(id<UUTreeTableViewDelegate>)treeDelegate {
    self.dataSource = self;
    self.delegate = self;
    
    [self setSeparatorColor:[UIColor colorWithRed:236.0 / 255.0 green:236.0 / 255.0 blue:236.0 / 255.0 alpha:1.0]];
    
    if (treeDelegate) {
        _treeDelegate = treeDelegate;
    }
}

- (void)setSeparatorColor:(UIColor *)separatorColor {
    [super setSeparatorColor:separatorColor];
    [TreeTableCellLine setIndicatorColor:separatorColor];
}

- (NSMutableDictionary *)cellStateDic {
    if (!_cellStateDic) {
        _cellStateDic = [NSMutableDictionary dictionary];
        
        NSInteger numberOfSections = [self.treeDelegate numberOfSectionsInTableView:self];
        for (NSInteger section = 0; section < numberOfSections; section++) {
            NSInteger numberOfRowsInSection = [self.treeDelegate tableView:self numberOfRowsInSection:section];
            
            NSMutableArray *rowArray = [NSMutableArray array];
            for (NSInteger row = 0; row < numberOfRowsInSection; row++) {
                NSIndexPath *rowIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
                NSInteger numberOfSubrows = [self.treeDelegate tableView:self numberOfSubRowsAtIndexPath:rowIndexPath];
                BOOL isExpandedInitially = NO;
                if ([self.treeDelegate respondsToSelector:@selector(tableView:shouldExpandSubRowsOfCellAtIndexPath:)]) {
                    isExpandedInitially = [self.treeDelegate tableView:self shouldExpandSubRowsOfCellAtIndexPath:rowIndexPath];
                }
                
                NSMutableDictionary *rowInfo = [NSMutableDictionary dictionaryWithObjects:@[@(isExpandedInitially), @(numberOfSubrows)] forKeys:@[kIsExpandedKey, kSubrowsKey]];
                
                [rowArray addObject:rowInfo];
            }
            
            [_cellStateDic setObject:rowArray forKey:@(section)];
        }
    }
    
    return _cellStateDic;
}

- (void)refreshData {
    self.cellStateDic = nil;
    [super reloadData];
}

- (void)refreshDataWithScrollingToIndexPath:(NSIndexPath *)indexPath {
    [self refreshData];
    
    if (indexPath.section < [self numberOfSections] && indexPath.row < [self numberOfRowsInSection:indexPath.section]) {
        [self scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

#pragma mark - 计算相应的的NSIndexPath
- (NSIndexPath *)correspondingIndexPathAtIndexPath:(NSIndexPath *)indexPath {
    __block NSIndexPath *correspondingIndexPath = nil;
    __block NSInteger expandedSubrows = 0;
    
    NSArray *rows = self.cellStateDic[@(indexPath.section)];
    [rows enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        BOOL isExpanded = [obj[kIsExpandedKey] boolValue];
        NSInteger numberOfSubrows = 0;
        if (isExpanded) {
            numberOfSubrows = [obj[kSubrowsKey] integerValue];
        }
        
        NSInteger subrow = indexPath.row - expandedSubrows - idx;
        if (subrow > numberOfSubrows) {
            expandedSubrows += numberOfSubrows;
        } else {
            correspondingIndexPath = [NSIndexPath indexPathForSubRow:subrow inRow:idx inSection:indexPath.section];
            *stop = YES;
        }
    }];
    return correspondingIndexPath;
}

#pragma mark - Cell高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *correspondingIndexPath = [self correspondingIndexPathAtIndexPath:indexPath];
    if ([correspondingIndexPath subRow] == 0) {
        if ([_treeDelegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
            return [_treeDelegate tableView:tableView heightForRowAtIndexPath:correspondingIndexPath];
        }
        
        return kDefaultCellHeight;
    } else {
        if ([_treeDelegate respondsToSelector:@selector(tableView:heightForSubRowAtIndexPath:)]) {
            NSIndexPath *correspondingIndexPath = [self correspondingIndexPathAtIndexPath:indexPath];
            correspondingIndexPath = [NSIndexPath indexPathForSubRow:correspondingIndexPath.subRow-1
                                                               inRow:correspondingIndexPath.row
                                                           inSection:correspondingIndexPath.section];
            return [_treeDelegate tableView:self heightForSubRowAtIndexPath:correspondingIndexPath];
        }
        
        return kDefaultCellHeight;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([_treeDelegate respondsToSelector:@selector(tableView:heightForHeaderInSection:)]) {
        return [_treeDelegate tableView:tableView heightForHeaderInSection:section];
        
    }
    return 0.1f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if ([_treeDelegate respondsToSelector:@selector(tableView:heightForFooterInSection:)]) {
        return  [_treeDelegate tableView:tableView heightForFooterInSection:section];
    }
    
    return 0.1f;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_treeDelegate tableView:tableView numberOfRowsInSection:section] + [self numberOfExpandedSubrowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *correspondingIndexPath = [self correspondingIndexPathAtIndexPath:indexPath];
    if ([correspondingIndexPath subRow] == 0) {
        RootLeverTableViewCell *expandableCell = (RootLeverTableViewCell *)[_treeDelegate tableView:tableView cellForRowAtIndexPath:correspondingIndexPath];
        if ([expandableCell respondsToSelector:@selector(setSeparatorInset:)]) {
            expandableCell.separatorInset = UIEdgeInsetsZero;
        }
        
        BOOL isExpanded = [self.cellStateDic[@(correspondingIndexPath.section)][correspondingIndexPath.row][kIsExpandedKey] boolValue];
        if (expandableCell.isExpandable) {
            expandableCell.expanded = isExpanded;
            
            UIButton *expandableButton = (UIButton *)expandableCell.accessoryView;
            [expandableButton addTarget:tableView action:@selector(expandableButtonTouched:event:) forControlEvents:UIControlEventTouchUpInside];
            
            if (isExpanded) {
                expandableCell.accessoryView.transform = CGAffineTransformMakeRotation(M_PI);
            } else {
                if ([expandableCell containsIndicatorView]) {
                    [expandableCell removeIndicatorView];
                }
            }
        } else {
            expandableCell.expanded = NO;
            expandableCell.accessoryView = nil;
            [expandableCell removeIndicatorView];
        }
        
        return expandableCell;
    } else {
        correspondingIndexPath = [NSIndexPath indexPathForSubRow:correspondingIndexPath.subRow - 1 inRow:correspondingIndexPath.row inSection:correspondingIndexPath.section];
        UITableViewCell *cell = [_treeDelegate tableView:(UUTreeTableView *)tableView cellForSubRowAtIndexPath:correspondingIndexPath];
        cell.backgroundColor = [self separatorColor];
        cell.backgroundView = nil;
        cell.indentationLevel = 2;
        
        return cell;
    }
}

#pragma mark - 分区个数
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([_treeDelegate respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
        return [_treeDelegate numberOfSectionsInTableView:tableView];
    }
    return 1;
}

#pragma mark - 插入cell
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    RootLeverTableViewCell *cell = (RootLeverTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    //是否支持展开或者关闭
    if ([cell respondsToSelector:@selector(isExpandable)]) {
        if (cell.isExpandable) {
            cell.expanded = !cell.isExpanded;
            
            NSIndexPath *_indexPath = indexPath;
            NSIndexPath *correspondingIndexPath = [self correspondingIndexPathAtIndexPath:indexPath];
            if (cell.isExpanded && _shouldExpandOnlyOneCell) {
                _indexPath = correspondingIndexPath;
                [self collapseCurrentlyExpandedIndexPaths];
            }
            
            if (_indexPath) {
                NSInteger numberOfSubRows = [self numberOfSubRowsAtIndexPath:correspondingIndexPath];
                
                NSMutableArray *expandedIndexPaths = [NSMutableArray array];
                NSInteger row = _indexPath.row;
                NSInteger section = _indexPath.section;
                
                for (NSInteger index = 1; index <= numberOfSubRows; index++) {
                    NSIndexPath *expIndexPath = [NSIndexPath indexPathForRow:row+index inSection:section];
                    [expandedIndexPaths addObject:expIndexPath];
                }
                
                if (cell.isExpanded) {
                    [self setExpanded:YES forCellAtIndexPath:correspondingIndexPath];
                    [self insertRowsAtIndexPaths:expandedIndexPaths withRowAnimation:UITableViewRowAnimationTop];
                } else {
                    [self setExpanded:NO forCellAtIndexPath:correspondingIndexPath];
                    [self deleteRowsAtIndexPaths:expandedIndexPaths withRowAnimation:UITableViewRowAnimationTop];
                }
                
                [cell accessoryViewAnimation];
            }
        }
        
        if ([_treeDelegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
            NSIndexPath *correspondingIndexPath = [self correspondingIndexPathAtIndexPath:indexPath];
            
            if (correspondingIndexPath.subRow == 0) {
                [_treeDelegate tableView:tableView didSelectRowAtIndexPath:correspondingIndexPath];
            } else {
                correspondingIndexPath = [NSIndexPath indexPathForSubRow:correspondingIndexPath.subRow - 1 inRow:correspondingIndexPath.row inSection:correspondingIndexPath.section];
                [_treeDelegate tableView:self didSelectSubRowAtIndexPath:correspondingIndexPath];
            }
        }
    } else {
        if ([_treeDelegate respondsToSelector:@selector(tableView:didSelectSubRowAtIndexPath:)]) {
            NSIndexPath *correspondingIndexPath = [self correspondingIndexPathAtIndexPath:indexPath];
            correspondingIndexPath = [NSIndexPath indexPathForSubRow:correspondingIndexPath.subRow - 1 inRow:correspondingIndexPath.row inSection:correspondingIndexPath.section];
            [_treeDelegate tableView:self didSelectSubRowAtIndexPath:correspondingIndexPath];
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if ([_treeDelegate respondsToSelector:@selector(tableView:accessoryButtonTappedForRowWithIndexPath:)])
        [_treeDelegate tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
    
    [self.delegate tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - WSTableViewUtils
- (NSInteger)numberOfExpandedSubrowsInSection:(NSInteger)section {
    NSInteger totalExpandedSubrows = 0;
    
    NSArray *rows = self.cellStateDic[@(section)];
    for (id row in rows) {
        if ([row[kIsExpandedKey] boolValue] == YES) {
            totalExpandedSubrows += [row[kSubrowsKey] integerValue];
        }
    }
    
    return totalExpandedSubrows;
}

- (IBAction)expandableButtonTouched:(id)sender event:(id)event {
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self];
    
    NSIndexPath *indexPath = [self indexPathForRowAtPoint:currentTouchPosition];
    
    if (indexPath) {
        [self tableView:self accessoryButtonTappedForRowWithIndexPath:indexPath];
    }
}

- (NSInteger)numberOfSubRowsAtIndexPath:(NSIndexPath *)indexPath {
    return [_treeDelegate tableView:self numberOfSubRowsAtIndexPath:indexPath];
}

- (void)setExpanded:(BOOL)isExpanded forCellAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *cellInfo = self.cellStateDic[@(indexPath.section)][indexPath.row];
    [cellInfo setObject:@(isExpanded) forKey:kIsExpandedKey];
}

- (void)collapseCurrentlyExpandedIndexPaths {
    NSMutableArray *totalExpandedIndexPaths = [NSMutableArray array];
    NSMutableArray *totalExpandableIndexPaths = [NSMutableArray array];
    
    [self.cellStateDic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        __block NSInteger totalExpandedSubrows = 0;
        
        [obj enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            NSInteger currentRow = idx + totalExpandedSubrows;
            
            BOOL isExpanded = [obj[kIsExpandedKey] boolValue];
            if (isExpanded) {
                NSInteger expandedSubrows = [obj[kSubrowsKey] integerValue];
                for (NSInteger index = 1; index <= expandedSubrows; index++) {
                    NSIndexPath *expandedIndexPath = [NSIndexPath indexPathForRow:currentRow + index
                                                                        inSection:[key integerValue]];
                    [totalExpandedIndexPaths addObject:expandedIndexPath];
                }
                
                [obj setObject:@(NO) forKey:kIsExpandedKey];
                totalExpandedSubrows += expandedSubrows;
                
                [totalExpandableIndexPaths addObject:[NSIndexPath indexPathForRow:currentRow inSection:[key integerValue]]];
            }
        }];
    }];
    
    for (NSIndexPath *indexPath in totalExpandableIndexPaths) {
        RootLeverTableViewCell *cell = (RootLeverTableViewCell *)[self cellForRowAtIndexPath:indexPath];
        cell.expanded = NO;
        [cell accessoryViewAnimation];
    }
    
    [self deleteRowsAtIndexPaths:totalExpandedIndexPaths withRowAnimation:UITableViewRowAnimationTop];
}

/*
 *  Uncomment the implementations of the required methods.
 */

//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
//}
//
//- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:willDisplayHeaderView:forSection:)])
//        [_WSTableViewDelegate tableView:tableView willDisplayHeaderView:view forSection:section];
//}
//
//- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:willDisplayFooterView:forSection:)])
//        [_WSTableViewDelegate tableView:tableView willDisplayFooterView:view forSection:section];
//}
//
//- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:didEndDisplayingCell:forRowAtIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView didEndDisplayingCell:cell forRowAtIndexPath:indexPath];
//}
//
//- (void)tableView:(UITableView *)tableView didEndDisplayingHeaderView:(UIView *)view forSection:(NSInteger)section
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:didEndDisplayingHeaderView:forSection:)])
//        [_WSTableViewDelegate tableView:tableView didEndDisplayingHeaderView:view forSection:section];
//}
//
//- (void)tableView:(UITableView *)tableView didEndDisplayingFooterView:(UIView *)view forSection:(NSInteger)section
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:didEndDisplayingFooterView:forSection:)])
//        [_WSTableViewDelegate tableView:tableView didEndDisplayingFooterView:view forSection:section];
//}
//
//
//- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:estimatedHeightForRowAtIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
//
//    return 0;
//}
//
//- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:estimatedHeightForHeaderInSection:)])
//        [_WSTableViewDelegate tableView:tableView estimatedHeightForHeaderInSection:section];
//
//    return 0;
//}
//
//- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForFooterInSection:(NSInteger)section
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:estimatedHeightForFooterInSection:)])
//        [_WSTableViewDelegate tableView:tableView estimatedHeightForFooterInSection:section];
//
//    return 0;
//}
//
//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:viewForHeaderInSection:)])
//        [_WSTableViewDelegate tableView:tableView viewForHeaderInSection:section];
//
//    return nil;
//}
//
//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:viewForFooterInSection:)])
//        [_WSTableViewDelegate tableView:tableView viewForFooterInSection:section];
//
//    return nil;
//}
//
//- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:shouldHighlightRowAtIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView shouldHighlightRowAtIndexPath:indexPath];
//
//    return NO;
//}
//
//- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:didHighlightRowAtIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView didHighlightRowAtIndexPath:indexPath];
//}
//
//- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:didUnhighlightRowAtIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView didUnhighlightRowAtIndexPath:indexPath];
//}
//
//- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:willSelectRowAtIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView willSelectRowAtIndexPath:indexPath];
//
//    return nil;
//}
//
//- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:willDeselectRowAtIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView willDeselectRowAtIndexPath:indexPath];
//
//    return nil;
//}
//
//- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:didDeselectRowAtIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView didDeselectRowAtIndexPath:indexPath];
//}
//
//- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:editingStyleForRowAtIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView editingStyleForRowAtIndexPath:indexPath];
//
//    return UITableViewCellEditingStyleNone;
//}
//
//- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:titleForDeleteConfirmationButtonForRowAtIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView titleForDeleteConfirmationButtonForRowAtIndexPath:indexPath];
//
//    return nil;
//}
//
//- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:shouldIndentWhileEditingRowAtIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView shouldIndentWhileEditingRowAtIndexPath:indexPath];
//
//    return NO;
//}
//
//- (void)tableView:(UITableView*)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:willBeginEditingRowAtIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView willBeginEditingRowAtIndexPath:indexPath];
//}
//
//- (void)tableView:(UITableView*)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:didEndEditingRowAtIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView didEndEditingRowAtIndexPath:indexPath];
//}
//
//- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView targetIndexPathForMoveFromRowAtIndexPath:sourceIndexPath toProposedIndexPath:proposedDestinationIndexPath];
//
//    return nil;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:indentationLevelForRowAtIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView indentationLevelForRowAtIndexPath:indexPath];
//
//    return 0;
//}
//
//- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:shouldShowMenuForRowAtIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView shouldShowMenuForRowAtIndexPath:indexPath];
//
//    return NO;
//}
//
//- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:canPerformAction:forRowAtIndexPath:withSender:)])
//        [_WSTableViewDelegate tableView:tableView canPerformAction:action forRowAtIndexPath:indexPath withSender:sender];
//
//    return NO;
//}
//
//- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:performAction:forRowAtIndexPath:withSender:)])
//        [_WSTableViewDelegate tableView:tableView performAction:action forRowAtIndexPath:indexPath withSender:sender];
//}

/*
 *  Uncomment the implementations of the required methods.
 */

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:titleForHeaderInSection:)])
//        return [_WSTableViewDelegate tableView:tableView titleForHeaderInSection:section];
//
//    return nil;
//}
//
//- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:titleForFooterInSection:)])
//        return [_WSTableViewDelegate tableView:tableView titleForFooterInSection:section];
//
//    return nil;
//}
//
//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:canEditRowAtIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView canEditRowAtIndexPath:indexPath];
//
//    return NO;
//}
//
//- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:canMoveRowAtIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView canMoveRowAtIndexPath:indexPath];
//
//    return NO;
//}
//
//- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(sectionIndexTitlesForTableView:)])
//        [_WSTableViewDelegate sectionIndexTitlesForTableView:tableView];
//
//    return nil;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:sectionForSectionIndexTitle:atIndex:)])
//        [_WSTableViewDelegate tableView:tableView sectionForSectionIndexTitle:title atIndex:index];
//
//    return 0;
//}
//
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:commitEditingStyle:forRowAtIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
//}
//
//- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
//{
//    if ([_WSTableViewDelegate respondsToSelector:@selector(tableView:moveRowAtIndexPath:toIndexPath:)])
//        [_WSTableViewDelegate tableView:tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
//}

@end

#pragma mark - NSIndexPath (WSTableView)
static void *SubRowObjectKey;

@implementation NSIndexPath (UUTreeTableView)

- (NSInteger)subRow {
    id subRowObj = objc_getAssociatedObject(self, SubRowObjectKey);
    return [subRowObj integerValue];
}

- (void)setSubRow:(NSInteger)subRow {
    id subRowObj = [NSNumber numberWithInteger:subRow];
    objc_setAssociatedObject(self, SubRowObjectKey, subRowObj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSIndexPath *)indexPathForSubRow:(NSInteger)subrow inRow:(NSInteger)row inSection:(NSInteger)section {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    indexPath.subRow = subrow;
    
    return indexPath;
}

@end

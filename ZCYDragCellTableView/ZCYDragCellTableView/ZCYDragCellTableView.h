//
//  ZCYDragCellTableView.h
//  ZCYDragCellTableView
//
//  Created by 钟淳亚 on 16/4/28.
//  Copyright © 2016年 钟淳亚. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ZCYDragCellTableView;

@protocol ZCYDragCellTableViewDataSource <UITableViewDataSource>

@required
// 将外部数据源数组传入，以便在移动cell数据发生改变时进行修改重排
- (NSArray *)originalArrayDataForTableView:(ZCYDragCellTableView *)tableView;

@end

@protocol ZCYDragCellTableViewDelegate <UITableViewDelegate>

@required
//将修改重排后的数组传入，以便外部更新数据源
- (void)tableView:(ZCYDragCellTableView *)tableView newArrayDataForDataSource:(NSArray *)newArray;

@optional
//选中的cell准备好可以移动的时候
- (void)tableView:(ZCYDragCellTableView *)tableView cellReadyToMoveAtIndexPath:(NSIndexPath *)indexPath;
//选中的cell正在移动，变换位置，手势尚未松开
- (void)cellIsMovingInTableView:(ZCYDragCellTableView *)tableView;
//选中的cell完成移动，手势已松开
- (void)cellDidEndMovingInTableView:(ZCYDragCellTableView *)tableView;

@end

@interface ZCYDragCellTableView : UITableView

@property (nonatomic, assign) id<ZCYDragCellTableViewDataSource> dataSource;
@property (nonatomic, assign) id<ZCYDragCellTableViewDelegate> delegate;

@end

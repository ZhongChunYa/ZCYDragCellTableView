//
//  ZCYDragCellTableView.m
//  ZCYDragCellTableView
//
//  Created by 钟淳亚 on 16/4/28.
//  Copyright © 2016年 钟淳亚. All rights reserved.
//

#import "ZCYDragCellTableView.h"

typedef NS_ENUM(NSUInteger, ZCYSnapshotMeetsEdge) {
    RTSnapshotMeetsEdgeTop,
    RTSnapshotMeetsEdgeBottom,
};

@interface ZCYDragCellTableView ()

// 对被选中的cell截图
@property (nonatomic, weak) UIView *snapshot;
// 被选中cell的原始位置
@property (nonatomic, strong) NSIndexPath *originalIndexpath;
// 被选中cell的新位置
@property (nonatomic, strong) NSIndexPath *relocatedIndexpath;
// cell被拖动到边缘开启，tableview自动向上或向下滚动
@property (nonatomic, strong) CADisplayLink *autoScrollTimer;
// 记录手指所在的位置
@property (nonatomic, assign) CGPoint fingerLocation;
// 自动滚动的方向
@property (nonatomic, assign) ZCYSnapshotMeetsEdge autoScrollDirection;

@end

@implementation ZCYDragCellTableView

@dynamic delegate;
@dynamic dataSource;

#pragma mark - initialization methods

- (instancetype)init {
    self = [super init];
    if (self) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognized:)];
        [self addGestureRecognizer:longPress];
    }
    return self;
}

#pragma mark - Gesture methods

- (void)longPressGestureRecognized:(id)sender {
    UILongPressGestureRecognizer *longPress = (UILongPressGestureRecognizer *)sender;
    UIGestureRecognizerState longPressState = longPress.state;
    // 手指在tableview中的位置
    _fingerLocation = [longPress locationInView:self];
    // 手指按住位置对应的indexpath，可能为nil
    _relocatedIndexpath = [self indexPathForRowAtPoint:_fingerLocation];
    switch (longPressState) {
        case UIGestureRecognizerStateBegan: {   // 手势开始，对被选中cell截图，隐藏原cell
            _originalIndexpath = [self indexPathForRowAtPoint:_fingerLocation];
            if (_originalIndexpath) {
                [self cellSelectedAtIndexPath:_originalIndexpath];
            }
            break;
        }
        case UIGestureRecognizerStateChanged: { //点击位置移动，判断手指按住位置是否进入其它indexPath范围，若进入则更新数据源并移动cell
            //截图跟随手指移动
            CGPoint center = _snapshot.center;
            center.y = _fingerLocation.y;
            _snapshot.center = center;
            if ([self checkIfSnapshotMeetsEdge]) {
                [self startAutoScrollTimer];
            } else {
                [self stopAutoScrollTimer];
            }
            // 手指按住位置对应的indexpath，可能为nil
            _relocatedIndexpath = [self indexPathForRowAtPoint:_fingerLocation];
            if (_relocatedIndexpath && ![_relocatedIndexpath isEqual:_originalIndexpath]) {
                [self cellRelocatedToNewIndexPath:_relocatedIndexpath];
            }
            break;
        }
        default: {  // 长按手势结束，移除截图，显示cell
            [self stopAutoScrollTimer];
            [self didEndDraging];
            break;
        }
    }
}

#pragma mark - timer methods

// 创建定时器并运行
- (void)startAutoScrollTimer {
    if (!_autoScrollTimer) {
        _autoScrollTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(startAutoScroll)];
        [_autoScrollTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

// 停止定时器并销毁
- (void)stopAutoScrollTimer {
    if (_autoScrollTimer) {
        [_autoScrollTimer invalidate];
        _autoScrollTimer = nil;
    }
}

#pragma mark - Private methods

// 修改数据源，通知外部修改数据源
- (void)updateDataSource {
    // 通过DataSource代理获得原始数据源数组
    NSMutableArray *tempArray = [NSMutableArray array];
    if ([self.dataSource respondsToSelector:@selector(originalArrayDataForTableView:)]) {
        [tempArray addObjectsFromArray:[self.dataSource originalArrayDataForTableView:self]];
    }
    // 判断原始数据源是否为嵌套数组
    if ([self nestedArrayCheck:tempArray]) {    // 是嵌套数组
        if (_originalIndexpath.section == _relocatedIndexpath.section) {    // 同一个section内
            [self moveObjectInMutableArray:tempArray[_originalIndexpath.section] fromIndex:_originalIndexpath.row toIndex:_relocatedIndexpath.row];
        } else {    // 不同section
            id originalObj = tempArray[_originalIndexpath.section][_originalIndexpath.item];
            [tempArray[_relocatedIndexpath.section] insertObject:originalObj atIndex:_relocatedIndexpath.item];
            [tempArray[_originalIndexpath.section] removeObjectAtIndex:_originalIndexpath.item];
        }
    } else {    // 不是嵌套数组
        [self moveObjectInMutableArray:tempArray fromIndex:_originalIndexpath.row toIndex:_relocatedIndexpath.row];
    }
    // 将新数组传出外部以更新数据源
    if ([self .delegate respondsToSelector:@selector(tableView:newArrayDataForDataSource:)]) {
        [self.delegate tableView:self newArrayDataForDataSource:tempArray];
    }
}

// 检查数组是否为嵌套数组
- (BOOL)nestedArrayCheck:(NSArray *)array {
    for (id obj in array) {
        if ([obj isKindOfClass:[NSArray class]]) {
            return YES;
        }
    }
    return NO;
}

// cell被长按手指选中时，对其进行截图，原cell隐藏
- (void)cellSelectedAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
    UIView *snapshot = [self customSnapshotFromView:cell];
    [self addSubview:snapshot];
    _snapshot = snapshot;
    cell.hidden = YES;
    CGPoint center = _snapshot.center;
    center.y = _fingerLocation.y;
    [UIView animateWithDuration:0.2 animations:^{
        _snapshot.transform = CGAffineTransformMakeScale(1.03, 1.03);
        _snapshot.alpha = 0.98;
        _snapshot.center = center;
    }];
}

// 截图被移动到新的indexPath范围，先更新数据源，重排数组，再将cell移至新位置
- (void)cellRelocatedToNewIndexPath:(NSIndexPath *)indexPath {
    // 更新数据源并返回给外部
    [self updateDataSource];
    // 交换移动cell的位置
    [self moveRowAtIndexPath:_originalIndexpath toIndexPath:indexPath];
    // 更新cell的原始indexpath为当前的indexpath
    _originalIndexpath = indexPath;
}

// 拖拽结束，显示cell并移除截图
- (void)didEndDraging {
    UITableViewCell *cell = [self cellForRowAtIndexPath:_originalIndexpath];
    cell.hidden = NO;
    cell.alpha = 0;
    [UIView animateWithDuration:0.2 animations:^{
        _snapshot.center = cell.center;
        _snapshot.alpha = 0;
        _snapshot.transform = CGAffineTransformIdentity;
        cell.alpha = 1;
    } completion:^(BOOL finished) {
        cell.hidden = NO;
        [_snapshot removeFromSuperview];
        _snapshot = nil;
        _originalIndexpath = nil;
        _relocatedIndexpath = nil;
    }];
}

// 返回一个给定View的截图
- (UIView *)customSnapshotFromView:(UIView *)inputView {
    // Make an image from the input view.
    UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, NO, 0);
    [inputView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Create an image view.
    UIView *snapshot = [[UIImageView alloc] initWithImage:image];
    snapshot.center = inputView.center;
    snapshot.layer.masksToBounds = NO;
    snapshot.layer.cornerRadius = 0.0;
    snapshot.layer.shadowOffset = CGSizeMake(-5.0, 0.0);
    snapshot.layer.shadowRadius = 5.0;
    snapshot.layer.shadowOpacity = 0.4;
    
    return snapshot;
}

// 将可变数组中的一个对象移动到该数组的另一个位置
- (void)moveObjectInMutableArray:(NSMutableArray *)array fromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    if (fromIndex < toIndex) {
        for (NSInteger i = fromIndex; i < toIndex; i ++) {
            [array exchangeObjectAtIndex:i withObjectAtIndex:i + 1];
        }
    } else {
        for (NSInteger i = fromIndex; i > toIndex; i --) {
            [array exchangeObjectAtIndex:i withObjectAtIndex:i - 1];
        }
    }
}

// 检查截图是否到达边缘，并进行响应
- (BOOL)checkIfSnapshotMeetsEdge {
    CGFloat minY = CGRectGetMinY(_snapshot.frame);
    CGFloat maxY = CGRectGetMaxY(_snapshot.frame);
    if (minY < self.contentOffset.y) {
        _autoScrollDirection = RTSnapshotMeetsEdgeTop;
        return YES;
    }
    if (maxY > self.bounds.size.height + self.contentOffset.y) {
        _autoScrollDirection = RTSnapshotMeetsEdgeBottom;
        return YES;
    }
    return NO;
}

// 开始自动滚动
- (void)startAutoScroll {
    CGFloat pixelSpeed = 4;
    if (_autoScrollDirection == RTSnapshotMeetsEdgeTop) {//向下滚动
        if (self.contentOffset.y > 0) {//向下滚动最大范围限制
            [self setContentOffset:CGPointMake(0, self.contentOffset.y - pixelSpeed)];
            _snapshot.center = CGPointMake(_snapshot.center.x, _snapshot.center.y - pixelSpeed);
        }
    }else{                                               //向上滚动
        if (self.contentOffset.y + self.bounds.size.height < self.contentSize.height) {//向下滚动最大范围限制
            [self setContentOffset:CGPointMake(0, self.contentOffset.y + pixelSpeed)];
            _snapshot.center = CGPointMake(_snapshot.center.x, _snapshot.center.y + pixelSpeed);
        }
    }
    
    /*  当把截图拖动到边缘，开始自动滚动，如果这时手指完全不动，则不会触发‘UIGestureRecognizerStateChanged’，对应的代码就不会执行，导致虽然截图在tableView中的位置变了，但并没有移动那个隐藏的cell，用下面代码可解决此问题，cell会随着截图的移动而移动
     */
    _relocatedIndexpath = [self indexPathForRowAtPoint:_snapshot.center];
    if (_relocatedIndexpath && ![_relocatedIndexpath isEqual:_originalIndexpath]) {
        [self cellRelocatedToNewIndexPath:_relocatedIndexpath];
    }
}

@end

//
//  ViewController.m
//  ZCYDragCellTableView
//
//  Created by 钟淳亚 on 16/4/28.
//  Copyright © 2016年 钟淳亚. All rights reserved.
//

#import "ViewController.h"
#import "ZCYDragCellTableView.h"
#import "CellModel.h"

#define ZCYColor(r, g, b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1.0]
#define ZCYRandomColor ZCYColor(arc4random_uniform(256), arc4random_uniform(256), arc4random_uniform(256))

@interface ViewController ()<ZCYDragCellTableViewDelegate, ZCYDragCellTableViewDataSource>
@property (nonatomic, strong) NSArray *data;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ZCYDragCellTableView *tableView = [[ZCYDragCellTableView alloc]init];
    tableView.allowsSelection = YES;
    [self.view addSubview:tableView];
    tableView.frame = self.view.bounds;
    tableView.dataSource = self;
    tableView.delegate = self;
}

- (NSArray *)data{
    if (!_data) {
        NSMutableArray *arr = [NSMutableArray array];
        int numberOfScections = 4;
        for (int i = 0; i < numberOfScections; i ++) {
            NSMutableArray *arr2 = [NSMutableArray array];
            UIColor *color = ZCYRandomColor;
            for (int j = 0; j < 4 ; j ++) {
                CellModel *model = [[CellModel alloc]init];
                model.title = [NSString stringWithFormat:@"%d - %d",i,j];
                model.backgroundColor = color;
                [arr2 addObject:model];
            }
            [arr addObject:arr2];
        }
        _data = arr;
    }
    return _data;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSArray *sec = _data[section];
    return sec.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    CellModel *model = _data[indexPath.section][indexPath.item];
    cell.backgroundColor = model.backgroundColor;
    cell.textLabel.text = model.title;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (NSArray *)originalArrayDataForTableView:(ZCYDragCellTableView *)tableView{
    return _data;
}

- (void)tableView:(ZCYDragCellTableView *)tableView newArrayDataForDataSource:(NSArray *)newArray{
    _data = newArray;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    CellModel *model = _data[indexPath.section][indexPath.row];
    NSLog(@"%@",model.title);
}

@end

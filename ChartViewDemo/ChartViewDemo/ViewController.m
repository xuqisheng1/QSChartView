//
//  ViewController.m
//  ChartViewDemo
//
//  Created by ztcj_develop_mini on 2020/7/30.
//  Copyright © 2020 ztcj_develop_mini. All rights reserved.
//

#import "ViewController.h"
#import "PieChartView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    PieChartView *pieView = [[PieChartView alloc]initWithFrame:self.view.bounds];
    pieView.drawItems = [self generateDrawDatas];
    pieView.indexBlock = ^(NSInteger index) {
        NSLog(@"%zd", index);
    };
    [self.view addSubview:pieView];
}

- (NSArray *)generateDrawDatas {
    NSMutableArray *arrM = [NSMutableArray array];
    NSArray *colorArr = @[@"#FFC963", @"#6E51FF", @"#F53232", @"#53BAFF", @"#5139F2", @"#9EC6FD", @"#69A8FF", @"#008BE8", @"#9E8BFE", @"#F6AB20"];
    PieChartModel *chartModel = [[PieChartModel alloc]initWithName:@"饼图00"
                                                              rate:0.1
                                                             color:colorArr[0]];
    [arrM addObject:chartModel];
    
    PieChartModel *chartModel1 = [[PieChartModel alloc]initWithName:@"饼图01"
                                                              rate:0.2
                                                             color:colorArr[1]];
    [arrM addObject:chartModel1];
    
    PieChartModel *chartModel2 = [[PieChartModel alloc]initWithName:@"饼图02"
                                                              rate:0.3
                                                             color:colorArr[2]];
    [arrM addObject:chartModel2];
    
    PieChartModel *chartModel3 = [[PieChartModel alloc]initWithName:@"饼图03"
                                                              rate:0.4
                                                             color:colorArr[3]];
    [arrM addObject:chartModel3];
    return [arrM copy];
}

@end

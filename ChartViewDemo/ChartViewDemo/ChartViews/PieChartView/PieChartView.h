//
//  PieChartView.h
//  ChartViewDemo
//
//  Created by ztcj_develop_mini on 2020/7/30.
//  Copyright © 2020 ztcj_develop_mini. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^IndexBlock)(NSInteger index);

@interface PieChartModel : NSObject
- (instancetype)initWithName:(NSString *)name
                        rate:(CGFloat)rate
                       color:(NSString *)color;
@end

@interface PieChartView : UIView
@property (nonatomic, copy) NSArray *drawItems;
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, copy) IndexBlock indexBlock;
@end

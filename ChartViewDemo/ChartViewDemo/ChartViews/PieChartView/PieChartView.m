//
//  PieChartView.m
//  ChartViewDemo
//
//  Created by ztcj_develop_mini on 2020/7/30.
//  Copyright © 2020 ztcj_develop_mini. All rights reserved.
//

#import "PieChartView.h"

#define kDefalutColor \
[UIColor colorWithRed:((float)((0xDDDDDD & 0xFF0000) >> 16))/255.0 \
green:((float)((0xDDDDDD & 0xFF00) >> 8))/255.0 \
blue:((float)(0xDDDDDD & 0xFF))/255.0 \
alpha:1.0]

#define kPieRadius 70.0
#define kSelectedBgViewWH 80.0
#define kSelectedLineWidth 40.0
#define kNormalLineWidth 30.0

#define kWidth self.frame.size.width
#define kHeight self.frame.size.height
#define kCenterX (kWidth / 2.0)
#define kCenterY (kHeight / 2.0)
#define IsNotEmptyNSString(x) ((x)!=nil && [(x) length]>0)

@interface PieChartModel ()
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) CGFloat rate;
@property (nonatomic, copy) NSString *color;
@end
@implementation PieChartModel
- (instancetype)initWithName:(NSString *)name
                        rate:(CGFloat)rate
                       color:(NSString *)color {
    if (self = [super init]) {
        self.name = name;
        self.rate = rate;
        self.color = color;
    }
    return self;
}
@end




@interface PieChartView ()<UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *interactView;  //限定交互的范围

@property (nonatomic, strong) UIView *selectedBgView;
@property (nonatomic, strong) UILabel *selectedNameLbl;
@property (nonatomic, strong) UILabel *selectedRateLbl;

@property (nonatomic, strong) NSMutableArray *pieLayers;
@property (nonatomic, strong) NSMutableArray *lineLayers;
@property (nonatomic, strong) NSMutableArray *rateLbls;

@property (nonatomic, assign) CGPoint originPoint;
@property (nonatomic, assign) CGFloat roratedAngle; //记录旋转的角度
@end

@implementation PieChartView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        [self __setupView];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panAction:)];
        UITapGestureRecognizer  *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction:)];
        [self.interactView addGestureRecognizer:panGesture];
        [self.interactView addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self __makeConstraints];
}

- (void)__setupView {
    [self addSubview:self.selectedBgView];
    [self addSubview:self.interactView];
}

- (void)__makeConstraints {
    CGFloat originX, originY, width, height;
    //
    width = kPieRadius * 2 + kSelectedLineWidth;
    height = width;
    originX = (kWidth - width) / 2.0;
    originY = (kHeight - height) / 2.0;
    self.interactView.frame = CGRectMake(originX, originY, width, height);
    //
    originX = (kWidth - kSelectedBgViewWH) / 2.0;
    originY = (kHeight - kSelectedBgViewWH) / 2.0;
    width = kSelectedBgViewWH;
    height = kSelectedBgViewWH;
    self.selectedBgView.frame = CGRectMake(originX, originY, width, height);
    CGFloat nameHeight = ceil(self.selectedNameLbl.attributedText.size.height);
    CGFloat rateHeight = ceil(self.selectedRateLbl.attributedText.size.height);
    CGFloat nameAndRateSpace = 3.0;
    originX = 5.0;
    originY = (kSelectedBgViewWH - (nameHeight + rateHeight + nameAndRateSpace)) / 2.0;
    width = kSelectedBgViewWH - originX * 2;
    height = nameHeight;
    self.selectedNameLbl.frame = CGRectMake(originX, originY, width, height);
    originY = CGRectGetMaxY(self.selectedNameLbl.frame) + nameAndRateSpace;
    height = rateHeight;
    self.selectedRateLbl.frame = CGRectMake(originX, originY, width, height);
    
    //
    CGFloat startAngle = self.roratedAngle - M_PI_2;
    CGFloat endAngle = startAngle;
    for (int i = 0; i < self.drawItems.count; i ++) {
        PieChartModel *chartModel = self.drawItems[i];
        endAngle = startAngle + chartModel.rate * M_PI * 2;
        //
        CAShapeLayer *pieLayer = i < self.pieLayers.count?self.pieLayers[i] : nil;
        UIBezierPath *piePath = [UIBezierPath bezierPath];
        [piePath addArcWithCenter:CGPointMake(kCenterX, kCenterY) radius:kPieRadius startAngle:startAngle endAngle:endAngle clockwise:1];
        pieLayer.path = piePath.CGPath;
        //
        CAShapeLayer *lineLayer = i < self.lineLayers.count?self.lineLayers[i] : nil;
        UIBezierPath *linePath = [self createLineLayerPathWithStartAngle:startAngle endAngle:endAngle radius:kPieRadius];
        lineLayer.path = linePath.CGPath;
        //
        UILabel *rateLbl = i < self.rateLbls.count?self.rateLbls[i] : nil;
        CGFloat lblWidth = ceil(rateLbl.attributedText.size.width);
        CGFloat lblHeight = ceil(rateLbl.attributedText.size.height);
        if (linePath.currentPoint.x <= kCenterX) { //位于左半边
            rateLbl.frame = CGRectMake(linePath.currentPoint.x - lblWidth - 5.0, linePath.currentPoint.y - lblHeight / 2.0, lblWidth, lblHeight);
        }else {
            rateLbl.frame = CGRectMake(linePath.currentPoint.x + 5.0, linePath.currentPoint.y - lblHeight / 2.0, lblWidth, lblHeight);
        }
        startAngle = endAngle;
    }
    
}

- (UIBezierPath *)createLineLayerPathWithStartAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle radius:(CGFloat)radius {
    UIBezierPath *linePath = [UIBezierPath bezierPath];
    CGFloat centerAngle = (startAngle + endAngle) / 2.0;
    CGFloat originX, originY, finishX, finishY;
    originX = kCenterX + radius * cos(centerAngle);
    originY = kCenterY + radius * sin(centerAngle);
    finishX = kCenterX + (radius + kNormalLineWidth * 3.0 / 4.0) * cos(centerAngle);
    finishY = kCenterY + (radius + kNormalLineWidth * 3.0 / 4.0) * sin(centerAngle);
    
    [linePath moveToPoint:CGPointMake(originX, originY)];
    [linePath addLineToPoint:CGPointMake(finishX, finishY)];
    
    CGFloat lineLength = fabs(finishY - kCenterY)  / 2.0;//横向延长线的长度
    CGPoint endPoint = CGPointZero;
    if (finishX < kCenterX) {  //在中心点左半边
        endPoint = CGPointMake(finishX - lineLength, finishY);
    }else if (finishX >= kCenterX){
        endPoint = CGPointMake(finishX + lineLength, finishY);
    }
    [linePath addLineToPoint:endPoint];
    return linePath;
}

- (void)__resetConfig {
    _selectedIndex = 0; //默认选中第一个
    _roratedAngle = 0;
}

- (void)setDrawItems:(NSArray *)drawItems {
    _drawItems = drawItems;
    
    [self __resetConfig];
    self.selectedBgView.hidden = (drawItems.count == 0);
    
    for (int i = 0; i < drawItems.count; i ++) {
        if (i >= self.pieLayers.count) {
            CAShapeLayer *pieLayer = [[CAShapeLayer alloc]init];
            pieLayer.fillColor = nil;
            [self.layer addSublayer:pieLayer];
            [self.pieLayers addObject:pieLayer];
        }
        if (i >= self.lineLayers.count) {
            CAShapeLayer *lineLayer = [[CAShapeLayer alloc]init];
            lineLayer.fillColor = nil;
            lineLayer.lineWidth = 0.5;
            [self.layer addSublayer:lineLayer];
            [self.lineLayers addObject:lineLayer];
        }
        if (i >= self.rateLbls.count) {
            UILabel *rateLbl = [[UILabel alloc]init];
            rateLbl.font = [UIFont systemFontOfSize:12];
            rateLbl.textColor = [UIColor blackColor];
            [self addSubview:rateLbl];
            [self.rateLbls addObject:rateLbl];
        }
        
        PieChartModel *chartModel = drawItems[i];
        //
        CAShapeLayer *pieLayer = self.pieLayers[i];
        pieLayer.hidden = NO;
        UIColor *color = IsNotEmptyNSString(chartModel.color)?[self colorWithHexString:chartModel.color] : kDefalutColor;
        pieLayer.strokeColor = color.CGColor;
        pieLayer.lineWidth = i == self.selectedIndex?kSelectedLineWidth : kNormalLineWidth;
        //
        CAShapeLayer *lineLayer = self.lineLayers[i];
        lineLayer.hidden = NO;
        lineLayer.strokeColor = color.CGColor;
        //
        UILabel *rateLbl = self.rateLbls[i];
        rateLbl.hidden = NO;
        rateLbl.text = [NSString stringWithFormat:@"%.2f%%", chartModel.rate * 100.0];
        
        //
        if (i == self.selectedIndex) {
            self.selectedBgView.backgroundColor = color;
            self.selectedNameLbl.text = IsNotEmptyNSString(chartModel.name)?chartModel.name : @"";
            self.selectedRateLbl.text = [NSString stringWithFormat:@"%.2f%%", chartModel.rate * 100.0];
        }
    }
    
    for (int i = (int)drawItems.count; i < self.pieLayers.count; i ++) {
        CAShapeLayer *pieLayer = self.pieLayers[i];
        pieLayer.hidden = YES;
    }
    for (int i = (int)drawItems.count; i < self.lineLayers.count; i ++) {
        CAShapeLayer *lineLayer = self.lineLayers[i];
        lineLayer.hidden = YES;
    }
    for (int i = (int)drawItems.count; i < self.rateLbls.count; i ++) {
        UILabel *rateLbl = self.rateLbls[i];
        rateLbl.hidden = YES;
    }
    
    [self setNeedsLayout];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    for (int i = 0; i < self.drawItems.count; i ++) {
        PieChartModel *chartModel = self.drawItems[i];
        
        CAShapeLayer *pieLayer = i < self.pieLayers.count?self.pieLayers[i] : nil;
        pieLayer.lineWidth = (i == selectedIndex)?kSelectedLineWidth : kNormalLineWidth;
        if (i == selectedIndex) {
            UIColor *color = IsNotEmptyNSString(chartModel.color)?[self colorWithHexString:chartModel.color] : kDefalutColor;
            self.selectedBgView.backgroundColor = color;
            self.selectedNameLbl.text = IsNotEmptyNSString(chartModel.name)?chartModel.name : @"";
            self.selectedRateLbl.text = [NSString stringWithFormat:@"%.2f%%", chartModel.rate * 100.0];
        }
    }
}

#pragma mark - Events
/**
 拖拉旋转
 */
- (void)panAction:(UIPanGestureRecognizer *)pan {
    if (!self.drawItems.count) return;
    CGPoint currentPoint = [pan locationInView:self];
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            self.originPoint = currentPoint;
            break;
        case UIGestureRecognizerStateChanged: {
            CGFloat originAngle = atan2(self.originPoint.y - kCenterY, self.originPoint.x - kCenterX);   //0 ~ 2π
            CGFloat currentAngle = atan2(currentPoint.y - kCenterY, currentPoint.x - kCenterX);   //0 ~ 2π
            self.roratedAngle += (currentAngle - originAngle);
            self.originPoint = currentPoint;
            [self __makeConstraints];
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            break;
        default:
            break;
    }
}

/**
 点击选中
 */
- (void)tapAction:(UITapGestureRecognizer *)tap {
    if (!self.drawItems.count) return;
    CGPoint tapPoint = [tap locationInView:self]; //点击的位置
    CGFloat space = fabs(sqrt(pow(tapPoint.x - kCenterX, 2) + pow(tapPoint.y - kCenterY, 2)) - kPieRadius);
    CGFloat startAngle = self.roratedAngle - M_PI_2;
    for (int i = 0; i < self.drawItems.count; i ++) {
        PieChartModel *chartModel = self.drawItems[i];
        CAShapeLayer *pieLayer = i < self.pieLayers.count?self.pieLayers[i] : nil;
        if (space < pieLayer.lineWidth / 2.0) { //处在扇形环形区域
            //计算弧度
            CGFloat pointAngle = atan2(tapPoint.y - kCenterY, tapPoint.x - kCenterX);   //-π ~ π
            //要满足点击的区域落在 pieLayer 上，则 pieLayer 绘制的起始弧度必须位于 tapPoint 的逆时针侧，终止弧度位于 pieLayer 的顺时针侧
            CGFloat spaceAngle = pointAngle - startAngle;
            NSInteger cycles = (NSInteger)(spaceAngle / (M_PI * 2));
            //计算从 pieLayer 绘制开始的弧度按照顺时针方向到点击处的弧度差值
            CGFloat clockwise_spaceAngle = spaceAngle - cycles * (M_PI * 2);
            if (clockwise_spaceAngle < 0) {
                clockwise_spaceAngle += (M_PI * 2);
            }
            if (clockwise_spaceAngle <= (chartModel.rate * M_PI * 2)) {
                self.selectedIndex = i;
                if (self.indexBlock) {
                    self.indexBlock(i);
                }
                break;
            }
        }
        startAngle = startAngle + chartModel.rate * M_PI * 2;
    }
}

#pragma mark - LazyLoad
- (UIView *)interactView {
    if (!_interactView) {
        _interactView = [[UIView alloc]init];
    }
    return _interactView;
}

- (UIView *)selectedBgView {
    if (!_selectedBgView) {
        _selectedBgView = [[UIView alloc]init];
        _selectedBgView.backgroundColor = kDefalutColor;
        _selectedBgView.layer.cornerRadius = kSelectedBgViewWH / 2.0;
        _selectedBgView.clipsToBounds = YES;
        _selectedBgView.hidden = YES;
        
        [_selectedBgView addSubview:self.selectedNameLbl];
        [_selectedBgView addSubview:self.selectedRateLbl];
    }
    return _selectedBgView;
}

- (UILabel *)selectedNameLbl {
    if (!_selectedNameLbl) {
        _selectedNameLbl = [[UILabel alloc]init];
        _selectedNameLbl.font = [UIFont systemFontOfSize:12];
        _selectedNameLbl.textColor = [UIColor whiteColor];
        _selectedNameLbl.textAlignment = NSTextAlignmentCenter;
        _selectedNameLbl.text = @"--";
    }
    return _selectedNameLbl;
}

- (UILabel *)selectedRateLbl {
    if (!_selectedRateLbl) {
        _selectedRateLbl = [[UILabel alloc]init];
        _selectedRateLbl.font = [UIFont systemFontOfSize:12];
        _selectedRateLbl.textColor = [UIColor whiteColor];
        _selectedRateLbl.textAlignment = NSTextAlignmentCenter;
        _selectedRateLbl.text = @"--%";
    }
    return _selectedRateLbl;
}

- (NSMutableArray *)pieLayers {
    if (!_pieLayers) {
        _pieLayers = [[NSMutableArray alloc]init];
    }
    return _pieLayers;
}

- (NSMutableArray *)lineLayers {
    if (!_lineLayers) {
        _lineLayers = [[NSMutableArray alloc]init];
    }
    return _lineLayers;
}

- (NSMutableArray *)rateLbls {
    if (!_rateLbls) {
        _rateLbls = [[NSMutableArray alloc]init];
    }
    return _rateLbls;
}


#pragma mark -- 十六进制字符串转换成颜色
// 颜色转换：iOS中十六进制的颜色（以#开头）转换为UIColor
- (UIColor *)colorWithHexString:(NSString *)color {
    NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) {
        return [UIColor clearColor];
    }
    
    // 判断前缀并剪切掉
    if ([cString hasPrefix:@"0X"])
        cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"])
        cString = [cString substringFromIndex:1];
    if ([cString length] != 6)
        return [UIColor clearColor];
    
    // 从六位数值中找到RGB对应的位数并转换
    NSRange range;
    range.location = 0;
    range.length = 2;
    
    //R、G、B
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f) green:((float) g / 255.0f) blue:((float) b / 255.0f) alpha:1.0f];
}


@end

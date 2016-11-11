//
//  WaveView.m
//  01-基本线条绘制
//
//  Created by 1 on 15/10/19.
//  Copyright © 2015年 xiaomage. All rights reserved.
//

#import "WaveView.h"

@interface WaveView ()
@property (nonatomic, strong) UIBezierPath *path;
@property (nonatomic, strong) CAShapeLayer *pathLayer;
@end

@implementation WaveView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        [self.layer addSublayer:self.pathLayer];
    }
    return self;
}

- (void)drawWaveWithWavePoints:(NSArray <NSNumber *>*)wavePoints {
    CGFloat gap = self.bounds.size.width / (wavePoints.count - 1);
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    [path moveToPoint:CGPointMake(0, 300 - wavePoints.firstObject.floatValue * 2000)];
    [wavePoints enumerateObjectsUsingBlock:^(NSNumber * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [path addLineToPoint:CGPointMake((idx + 1) * gap, 300 - obj.floatValue * 2000)];
    }];
    
    self.pathLayer.path = path.CGPath;
    [self pathAnimationWithPath:path];
    self.path = path;
}

- (void)pathAnimationWithPath:(UIBezierPath *)path {
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    pathAnimation.removedOnCompletion = NO;
    pathAnimation.duration = 0.01;
    pathAnimation.fromValue = self.path;
    pathAnimation.toValue = path;
    [self.pathLayer addAnimation:pathAnimation forKey:@"animationCirclePath"];
}

- (CAShapeLayer *)pathLayer {
    if (!_pathLayer) {
        _pathLayer = [CAShapeLayer layer];
        _pathLayer.frame = self.bounds;
        _pathLayer.fillColor = [UIColor clearColor].CGColor;
        _pathLayer.strokeColor = [UIColor blueColor].CGColor;
        _pathLayer.lineWidth = 0.5f;
        _pathLayer.lineJoin = kCALineJoinBevel;
    }
    return _pathLayer;
}



@end

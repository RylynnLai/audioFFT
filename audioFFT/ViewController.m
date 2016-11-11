//
//  ViewController.m
//  audioFFT
//
//  Created by LLZ on 2016/10/19.
//  Copyright © 2016年 LLZ. All rights reserved.
//

#import "ViewController.h"
#import "WaveView.h"
#import "AudioEngineManager.h"

@interface ViewController ()
@property (nonatomic, strong) AudioEngineManager *engine;
@property (nonatomic, strong) WaveView *waveV;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];
    
    _engine = [AudioEngineManager new];
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.008 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (_engine.isPlaying) {
            [self update];
        }
    }];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    [_timer setFireDate:[NSDate distantPast]];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [_timer invalidate];
    _timer = nil;
}

- (void)initUI {
    self.view.backgroundColor = [UIColor lightGrayColor];
    [self reset];
    UIButton *btn1 = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButton *btn2 = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButton *stopBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    
    btn1.bounds = CGRectMake(0, 0, 100, 50);
    btn2.bounds = CGRectMake(0, 0, 100, 50);
    stopBtn.bounds = CGRectMake(0, 0, 100, 50);
    btn1.center = CGPointMake(self.view.bounds.size.width / 2, 100);
    btn2.center = CGPointMake(self.view.bounds.size.width / 2, 150);
    stopBtn.center = CGPointMake(self.view.bounds.size.width / 2, 200);
    btn1.tag = 001;
    btn2.tag = 002;
    stopBtn.tag = 000;
    
    [stopBtn setTitle:@"stop" forState:UIControlStateNormal];
    [btn1 setTitle:@"泡沫.mp3" forState:UIControlStateNormal];
    [btn2 setTitle:@"简单爱.mp3" forState:UIControlStateNormal];
    [self.view addSubview:btn1];
    [self.view addSubview:btn2];
    [self.view addSubview:stopBtn];
    
    [btn1 addTarget:self action:@selector(play:) forControlEvents:UIControlEventTouchUpInside];
    [btn2 addTarget:self action:@selector(play:) forControlEvents:UIControlEventTouchUpInside];
    [stopBtn addTarget:self action:@selector(play:) forControlEvents:UIControlEventTouchUpInside];
    
    _waveV = [[WaveView alloc] initWithFrame:CGRectMake(0, 300, self.view.bounds.size.width, 300)];
    [self.view addSubview:_waveV];
}

- (void)update {
    NSMutableArray *dataArr = [_engine leftFrequencyValue];
    [self.waveV drawWaveWithWavePoints:dataArr];
}

- (void)reset {
    [self.waveV drawWaveWithWavePoints:@[]];
}

- (void)play:(UIButton *)btn {
    [_engine stopPlaying];
    if (btn.tag == 001) {//泡沫
        [_engine loadAudioWith:@"paomo.mp3"];
        [_engine startPlaying];
    } else if (btn.tag == 002) {//简单爱
        [_engine loadAudioWith:@"简单爱.mp3"];
        [_engine startPlaying];
    } else if (btn.tag == 000) {
        [_engine stopPlaying];
        [self reset];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

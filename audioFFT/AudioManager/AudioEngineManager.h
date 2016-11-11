//
//  AudioEngineManager.h
//  CoreAudioMixer
//
//  Created by William Welbes on 2/25/16.
//  Copyright © 2016 William Welbes. All rights reserved.
//
//  Implement CoreAudio functionality using the AVAudioEngine introduced in iOS8


#import <Foundation/Foundation.h>
#import "AudioManager.h"

@interface AudioEngineManager : NSObject <AudioManager>
@property (nonatomic, assign) BOOL isPlaying;
//音频的采样频率，默认为44100Hz，事实上大部分音频都是44100Hz（CD音质）
@property (nonatomic, assign) NSInteger samplingFrequency;

//设置只采集前frequencyChannelCount个通道的频谱数据
@property (nonatomic, assign) NSInteger frequencyChannelCount;
//20kHz以下采集到的频谱通道数，目前是1160个通道(2560 * (20000 / 44100))
@property (nonatomic, assign, readonly) NSInteger frequencyDataCountBelow20kHz;
//频谱数据（以指针的形式返回）
@property (nonatomic, assign) Float32 *leftFrequencyData;//左声道输出每一个数据包的FFT数据
@property (nonatomic, assign) Float32 *rightFrequencyData;//左声道输出每一个数据包的FFT数据
//频谱数据，已数组形式返回。如果没有设置frequencyChannelCount，通道数（数组元素个数）默认为frequencyDataCountBelow20kHz，
@property (nonatomic, strong) NSMutableArray <NSNumber *>*leftFrequencyValue;
@property (nonatomic, strong) NSMutableArray <NSNumber *>*rightFrequencyValue;

@end

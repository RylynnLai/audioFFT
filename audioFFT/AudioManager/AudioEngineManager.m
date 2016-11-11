//
//  AudioEngineManager.m
//  CoreAudioMixer
//
//  Created by William Welbes on 2/25/16.
//  Copyright © 2016 William Welbes. All rights reserved.
//

#import "AudioEngineManager.h"
#import <AVFoundation/AVFoundation.h>
#include <Accelerate/Accelerate.h>  //Include the Accelerate framework to perform FFT

const Float64 sampleRate = 44100.0;
const UInt32 frequency = 2205;//傅里叶变换的点数（相当于每次有frequency个frame去参与傅里叶变换）
@interface AudioEngineManager ()
@property (nonatomic, strong) AVAudioEngine *audioEngine;
@property (nonatomic, strong) AVAudioPlayerNode *inputPlayerNode;
@property (nonatomic, strong) AVAudioFile *audioFile;
@end


@implementation AudioEngineManager

- (void)loadAudioWith:(NSString *)fileName {
    _isPlaying = NO;
    _samplingFrequency = sampleRate;
    _frequencyDataCountBelow20kHz = (NSInteger)(frequency * (20000.0 / _samplingFrequency));
    if (_frequencyChannelCount <= 0) {
        _frequencyChannelCount = _frequencyDataCountBelow20kHz;
    }
    //Allocate the audio engine
    _audioEngine = [[AVAudioEngine alloc] init];
    
    //Create a player node for the guitar
    _inputPlayerNode = [[AVAudioPlayerNode alloc] init];
    [_audioEngine attachNode:_inputPlayerNode];
    
    //Load the audio file
    NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:fileName withExtension:nil];
    NSError *error = nil;
    
    //audioFile
    _audioFile = [[AVAudioFile alloc] initForReading:fileUrl error:&error];
    if (error != nil) {
        NSLog(@"Error loading file: %@", error.localizedDescription);
        return; //Short circuit - TODO: more error handling
    }
    AVAudioPCMBuffer *PCMBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:_audioFile.processingFormat frameCapacity:(UInt32)_audioFile.length];
    [_audioFile readIntoBuffer:PCMBuffer error:&error];
    if (error != nil) {
        NSLog(@"Error loading guitar file into buffer: %@", error.localizedDescription);
        return; //Short circuit - TODO: more error handling
    }
    
    AVAudioMixerNode *mixer = [_audioEngine mainMixerNode];
    
    //connect
    [_audioEngine connect:_inputPlayerNode to:mixer format:PCMBuffer.format];
    [_audioEngine connect:mixer to:_audioEngine.outputNode format:PCMBuffer.format];
    
    _leftFrequencyData = (Float32 *)calloc(frequency, sizeof(Float32));    //TODO: Dynamic size
    _rightFrequencyData = (Float32 *)calloc(frequency, sizeof(Float32));    //TODO: Dynamic size
    //bufferSize就是每个数据包（buffer）的大小，只支持100ms~400ms，按照44100Hz采样率来换算，bufferSize范围就是4410~17640，当然越小越实时，太大的话傅里叶出来的频谱会不及时
    [mixer installTapOnBus:0 bufferSize:frequency * 2 format:PCMBuffer.format block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        //FFT
        if (&buffer.floatChannelData[0][0] != nil) performFFT(&buffer.floatChannelData[0][0], frequency * 2, _leftFrequencyData);
        if (&buffer.floatChannelData[1][0] != nil) performFFT(&buffer.floatChannelData[1][0], frequency * 2, _rightFrequencyData);
       
    }];
    
    //start engine
    [_audioEngine startAndReturnError:&error];
    if (error != nil) {
        NSLog(@"Error start Engine : %@", error.localizedDescription);
        return; //Short circuit - TODO: more error handling
    }
}

- (void)startPlaying {
    [_inputPlayerNode scheduleFile:_audioFile atTime:nil completionHandler:^{
        _isPlaying = NO;
    }];
    [_inputPlayerNode play];
    _isPlaying = YES;
}

- (void)pausePlaying {
    [_inputPlayerNode pause];
    _isPlaying = NO;
}

- (void)stopPlaying {
    [_inputPlayerNode stop];
    _isPlaying = NO;
}

- (void)setInputVolume:(Float32)value {
    _inputPlayerNode.volume = value;
}

- (NSMutableArray<NSNumber *> *)leftFrequencyValue {
    if (!_leftFrequencyValue) {
        _leftFrequencyValue = [NSMutableArray arrayWithCapacity:frequency];
    }
    //只取20kHz以下的数据
    for (int i = 0; i < _frequencyChannelCount; i ++) {
        [_leftFrequencyValue setObject:[NSNumber numberWithFloat:_leftFrequencyData[i]] atIndexedSubscript:i];
    }
    return _leftFrequencyValue;
}
- (NSMutableArray<NSNumber *> *)rightFrequencyValue {
    if (!_rightFrequencyValue) {
        _rightFrequencyValue = [NSMutableArray arrayWithCapacity:frequency];
    }
    //只取20kHz以下的数据
    for (int i = 0; i < _frequencyChannelCount; i ++) {
        [_rightFrequencyValue setObject:[NSNumber numberWithFloat:_rightFrequencyData[i]] atIndexedSubscript:i];
    }
    return _rightFrequencyValue;
}

//计算声音频率
- (Float32)caculatesFrequencyHerzValueWithIndex:(NSInteger)frequencyIndex {
    Float32 frequencyOver2 = frequency / 2;
    Float32 sampleRateOver2 = _samplingFrequency / 2;
    return frequencyIndex / frequencyOver2 * sampleRateOver2;
}
//FFT
static void performFFT(float* data, UInt32 numberOfFrames, Float32 *frequencyData) {
    
    int bufferLog2 = round(log2(numberOfFrames));
    float fftNormFactor = 1.0/( 2 * numberOfFrames);
    
    FFTSetup fftSetup = vDSP_create_fftsetup(bufferLog2, kFFTRadix2);
    
    int numberOfFramesOver2 = numberOfFrames / 2;
    float outReal[numberOfFramesOver2];
    float outImaginary[numberOfFramesOver2];
    
    COMPLEX_SPLIT output = { .realp = outReal, .imagp = outImaginary };
    
    //Put all of the even numbered elements into outReal and odd numbered into outImaginary
    vDSP_ctoz((COMPLEX *)data, 2, &output, 1, numberOfFramesOver2);
    
    //Perform the FFT via Accelerate
    //Use FFT forward for standard PCM audio
    vDSP_fft_zrip(fftSetup, &output, 1, bufferLog2, FFT_FORWARD);
    
    //Scale the FFT data
    vDSP_vsmul(output.realp, 1, &fftNormFactor, output.realp, 1, numberOfFramesOver2);
    vDSP_vsmul(output.imagp, 1, &fftNormFactor, output.imagp, 1, numberOfFramesOver2);
    
    //vDSP_zvmags(&output, 1, soundBuffer[inBusNumber].frequencyData, 1, numberOfFramesOver2);
    
    //Take the absolute value of the output to get in range of 0 to 1
    //vDSP_zvabs(&output, 1, frequencyData, 1, numberOfFramesOver2);
    vDSP_zvabs(&output, 1, frequencyData, 1, numberOfFramesOver2);
    
    vDSP_destroy_fftsetup(fftSetup);
}

/// caculates HZ value for specified index from a FFT bins vector
Float32 frequencyHerzValue(long frequencyIndex, long fftVectorSize, Float32 nyquistFrequency ) {
    return ((Float32)frequencyIndex/(Float32)fftVectorSize) * nyquistFrequency;
}
@end

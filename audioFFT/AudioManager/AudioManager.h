//
//  AudioManager.h
//  CoreAudioMixer
//
//  Created by William Welbes on 2/25/16.
//  Copyright © 2016 William Welbes. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AudioManager <NSObject>

-(void)loadAudioWith:(NSString *)fileName;

-(void)startPlaying;
-(void)pausePlaying;
-(void)stopPlaying;

-(void)setInputVolume:(Float32)value;

-(NSMutableArray <NSNumber *>*)leftFrequencyValue;
-(NSMutableArray <NSNumber *>*)rightFrequencyValue;
@end

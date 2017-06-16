//
//  Settings.m
//  AlexaTest_OC
//
//  Created by lanmi on 2017/6/13.
//  Copyright © 2017年 lanmi. All rights reserved.
//

#import "Settings.h"
#import <AVFoundation/AVFoundation.h>
@implementation Settings

+ (NSString *) APPLICATION_TYPE_ID{
    return @"alexatest";
}
+ (NSString *) DNS{
    return @"12345";
}
+ (NSArray *) SCOPES{
    return @[@"alexa:all"];
}
+ (NSString *) SCOPE_DATA{
    return [NSString stringWithFormat:@"{\"alexa:all\":{\"productID\":\"%@\",\"productInstanceAttributes\":{\"deviceSerialNumber\":\"%@\"}}}", [self APPLICATION_TYPE_ID], [self DNS]];
}

+ (NSString *) TEMP_FILE_NAME{
    return @"alexa.wav";
}

+ (NSDictionary *) RECORDING_SETTING{
    return @{AVEncoderAudioQualityKey: [NSNumber numberWithInt:AVAudioQualityHigh],
             AVEncoderBitRateKey: @16,
             AVNumberOfChannelsKey: @1,
             AVSampleRateKey: @16000.0};
}

+ (float) SILENCE_THRESHOLD{
    return -30.0f;
}
@end

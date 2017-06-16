//
//  AlexaVoiceClient.h
//  AlexaTest_OC
//
//  Created by lanmi on 2017/6/13.
//  Copyright © 2017年 lanmi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AlexaVoiceClient : NSObject <NSURLSessionDelegate, NSURLSessionDataDelegate>
@property (strong, nonatomic) void(^pingHandler)(BOOL);
@property (strong, nonatomic) void(^syncHandler)(BOOL);
@property (strong, nonatomic) void(^directiveHandler)(NSArray*);
@property (strong, nonatomic) void(^downchannelHandler)(NSString*);

- (void) ping;
- (void) startDownchannel;
- (void) postRecordingWithAudioData: (NSData *)audioData;
- (void) syncWithJSON: (NSString *)jsonData;
- (void) sendAudioWithJsonData: (NSString *)jsonData AudioData: (NSData *) audioData;
- (void) sendEventNamespace: (NSString *)namespace Name: (NSString *)name Token: (NSString *)token;
- (void) urlSession:(NSURLSession *)session DataTask: (NSURLSessionTask *)dataTask didReceive:(NSData *)data;
@end

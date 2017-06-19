//
//  AlexaVoiceClient.m
//  AlexaTest_OC
//
//  Created by lanmi on 2017/6/13.
//  Copyright © 2017年 lanmi. All rights reserved.
//

#import "AlexaVoiceClient.h"
#import "AmazonToken.h"
#import "NSData+FirstRange.h"
#define PING_ENDPOINT @"https://avs-alexa-na.amazon.com/ping"
#define DIRECTIVES_ENDPOINT @"https://avs-alexa-na.amazon.com/v20160207/directives"
#define EVENTS_ENDPOINT @"https://avs-alexa-na.amazon.com/v20160207/events"
#define TIMEOUT 3600
#define BOUNDARY_TERM @"CUSTOM_BOUNDARY_TERM"
#define SYNC_EVENT_DATA @"{ \"event\" : { \"header\" : { \"namespace\" : \"System\", \"name\" : \"SynchronizeState\", \"messageId\" : \"1\" }, \"payload\" : { } }, \"context\" : [ { \"header\" : { \"namespace\" : \"AudioPlayer\", \"name\" : \"PlaybackState\" }, \"payload\" : { \"token\" : \"\", \"offsetInMilliseconds\" : 0, \"playerActivity\" : \"IDLE\" } }, { \"header\" : { \"namespace\" : \"SpeechSynthesizer\", \"name\" : \"SpeechState\" }, \"payload\" : { \"token\" : \"\", \"offsetInMilliseconds\" : 0, \"playerActivity\" : \"FINISHED\" } }, { \"header\" : { \"namespace\" : \"Alerts\", \"name\" : \"AlertsState\" }, \"payload\" : { \"allAlerts\" : [ ], \"activeAlerts\" : [ ] } }, { \"header\" : { \"namespace\" : \"Speaker\", \"name\" : \"VolumeState\" }, \"payload\" : { \"volume\" : 50, \"muted\" : false } } ] }"
#define AUDIO_EVENT_DATA @"{\"event\": {\"header\": {\"namespace\": \"SpeechRecognizer\",\"name\": \"Recognize\",\"messageId\": \"$messageId\",\"dialogRequestId\": \"$dialogRequestId\"},\"payload\": {\"profile\": \"NEAR_FIELD\", \"format\": \"AUDIO_L16_RATE_16000_CHANNELS_1\"}},\"context\": [{\"header\": {\"namespace\": \"AudioPlayer\",\"name\": \"PlaybackState\"},\"payload\": {\"token\": \"\",\"offsetInMilliseconds\": 0,\"playerActivity\": \"FINISHED\"}}, {\"header\": {\"namespace\": \"SpeechSynthesizer\",\"name\": \"SpeechState\"},\"payload\": {\"token\": \"\",\"offsetInMilliseconds\": 0,\"playerActivity\": \"FINISHED\"}}, { \"header\" : { \"namespace\" : \"Alerts\", \"name\" : \"AlertsState\" }, \"payload\" : { \"allAlerts\" : [ ], \"activeAlerts\" : [ ] } }, {\"header\": {\"namespace\": \"Speaker\",\"name\": \"VolumeState\"},\"payload\": {\"volume\": 25,\"muted\": false}}]}"
#define EVENT_DATA_TEMPLATE @"{\"event\": {\"header\": {\"namespace\": \"$namespace\",\"name\": \"$name\",\"messageId\": \"$messageId\"},\"payload\": {\"token\": \"$token\"}}}"

@implementation AlexaVoiceClient
{
    NSURLSession *session;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        NSURLSessionConfiguration *sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration;
        sessionConfig.HTTPMaximumConnectionsPerHost = 1;
        sessionConfig.timeoutIntervalForRequest = 30.0f;
        session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
        
    }
    return self;
}

- (void) ping{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:PING_ENDPOINT]];
    request.HTTPMethod = @"GET";
    [self addAuthHeader:request];
    [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error){
            NSLog(@"%@", @"ping failure");
            self.pingHandler(NO);
        }else{
            NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
            NSLog(@"ping status code:%ld", res.statusCode);
            if (res.statusCode == 204){
                self.pingHandler(YES);
            }else{
                self.pingHandler(NO);
            }
        }
    }] resume];
    
}

- (void) startDownchannel{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:DIRECTIVES_ENDPOINT]];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = TIMEOUT;
    [self addAuthHeader:request];
    [[session dataTaskWithRequest:request] resume];
    [self syncWithJSON:SYNC_EVENT_DATA];
    [NSTimer scheduledTimerWithTimeInterval:300 target:self selector:@selector(ping) userInfo:nil repeats:YES];
}

- (void) postRecordingWithAudioData: (NSData *)audioData{
    NSString *eventData = AUDIO_EVENT_DATA;
    eventData = [eventData stringByReplacingOccurrencesOfString:@"$messageId" withString: [NSUUID.UUID UUIDString]];
    eventData = [eventData stringByReplacingOccurrencesOfString:@"$dialogRequestId" withString: [NSUUID.UUID UUIDString]];
//    NSLog(@"eventData = %@", eventData);
    [self sendAudioWithJsonData:eventData AudioData:audioData];
}

- (void) addAuthHeader:(NSMutableURLRequest *)request{
    [request addValue:[NSString stringWithFormat:@"Bearer %@", [AmazonToken sharedInstance].loginWithAmazonToken] forHTTPHeaderField:@"Authorization"];
}

- (void) syncWithJSON: (NSString *)jsonData{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:EVENTS_ENDPOINT]];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = TIMEOUT;
    [self addAuthHeader:request];
    [self addContentTypeHeaderWithRequest:request];
    
    NSMutableData *bodyData = [[NSMutableData alloc] init];
    [bodyData appendData:[self getBoundaryTermBegin]];
    [bodyData appendData:[self addEventDataWithJSON:jsonData]];
    [bodyData appendData:[self getBoundaryTermEnd]];
    [[session uploadTaskWithRequest:request fromData:bodyData completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error){
            NSLog(@"Send data error: %@", [error localizedDescription]);
            self.syncHandler(NO);
        }else{
            NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
            NSLog(@"Sync status code: %ld", res.statusCode);
            if (res.statusCode != 204){
                NSJSONSerialization *resJsonData = [NSJSONSerialization JSONObjectWithData:data options:@[] error:nil];
                NSLog(@"Sync response: %@", resJsonData);
                self.syncHandler(NO);
            }else{
                self.syncHandler(YES);
            }
        }
    }] resume];
}

- (void) addContentTypeHeaderWithRequest: (NSMutableURLRequest *)request{
    [request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", BOUNDARY_TERM] forHTTPHeaderField:@"Content-Type"];
}

- (NSData *) getBoundaryTermBegin{
    return [[NSString stringWithFormat:@"--%@\r\n", BOUNDARY_TERM] dataUsingEncoding:kCFStringEncodingUTF8];
}
- (NSData *) getBoundaryTermEnd{
    return [[NSString stringWithFormat:@"--%@--\r\n", BOUNDARY_TERM] dataUsingEncoding:kCFStringEncodingUTF8];
}
- (NSData *) addEventDataWithJSON: (NSString *)jsonData{
    NSMutableData *bodyData = [[NSMutableData alloc] init];
    [bodyData appendData:[@"Content-Disposition: form-data; name=\"metadata\"\r\n" dataUsingEncoding:kCFStringEncodingUTF8]];
    [bodyData appendData:[@"Content-Type: application/json; charset=UTF-8\r\n\r\n" dataUsingEncoding:kCFStringEncodingUTF8]];
    [bodyData appendData:[jsonData dataUsingEncoding:kCFStringEncodingUTF8]];
    [bodyData appendData:[@"\r\n" dataUsingEncoding:kCFStringEncodingUTF8]];
    return bodyData;
}

- (NSData *) addAudioDataWithData: (NSData *)audioData{
    NSMutableData *bodyData = [[NSMutableData alloc] init];
    [bodyData appendData:[@"Content-Disposition: form-data; name=\"audio\"\r\n" dataUsingEncoding:kCFStringEncodingUTF8]];
    [bodyData appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:kCFStringEncodingUTF8]];
    [bodyData appendData:audioData];
    [bodyData appendData:[@"\r\n" dataUsingEncoding:kCFStringEncodingUTF8]];
    return bodyData;
}

- (void) sendAudioWithJsonData: (NSString *)jsonData AudioData: (NSData *) audioData{
    NSMutableURLRequest *request = [NSMutableURLRequest  requestWithURL:[NSURL URLWithString:EVENTS_ENDPOINT]];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = TIMEOUT;
    [self addAuthHeader:request];
    [self addContentTypeHeaderWithRequest:request];
    NSMutableData *bodyData = [[NSMutableData alloc] init];
    [bodyData appendData:[self getBoundaryTermBegin]];
    [bodyData appendData:[self addEventDataWithJSON:jsonData]];
    [bodyData appendData:[self getBoundaryTermBegin]];
    [bodyData appendData:[self addAudioDataWithData:audioData]];
    [bodyData appendData:[self getBoundaryTermEnd]];
    
//    NSLog(@"bodyData = %@", bodyData);
    [[session uploadTaskWithRequest:request fromData:bodyData completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error){
            self.directiveHandler(nil);
            NSLog(@"Send audio error: %@", error.localizedDescription);
        }else{
            NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
            NSLog(@"Send audio status code: %ld", res.statusCode);
            if (res.statusCode >= 200 && res.statusCode <= 299){
                NSString *contentTypeHeader = (NSString *)res.allHeaderFields[@"Content-Type"];
                if (contentTypeHeader) {
                    NSString *boundary = [self extractBoundaryWithContentTypeHeader:contentTypeHeader];
                    NSArray *directives = [self extractDirectivesWithData:data Boundary:boundary];
                    self.directiveHandler(directives);
                }else{
                    self.directiveHandler(nil);
                    NSLog(@"Content type in response is empty");
                }
            }
        }
    }] resume];
}

- (void) sendEventNamespace: (NSString *)namespace Name: (NSString *)name Token: (NSString *)token{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:EVENTS_ENDPOINT]];
    request.HTTPMethod = @"POST";
    [self addAuthHeader:request];
    [self addContentTypeHeaderWithRequest:request];
    NSString *eventData = EVENT_DATA_TEMPLATE;
    eventData = [eventData stringByReplacingOccurrencesOfString:@"$messageId" withString:[NSUUID.UUID UUIDString]];
    eventData = [eventData stringByReplacingOccurrencesOfString:@"$namespace" withString:namespace];
    eventData = [eventData stringByReplacingOccurrencesOfString:@"$name" withString:name];
    eventData = [eventData stringByReplacingOccurrencesOfString:@"$token" withString:token];
    NSMutableData *bodyData = [[NSMutableData alloc] init];
    [bodyData appendData:[self getBoundaryTermBegin]];
    [bodyData appendData:[self addEventDataWithJSON:eventData]];
    [bodyData appendData:[self getBoundaryTermEnd]];
    [[session uploadTaskWithRequest:request fromData:bodyData completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error){
            NSLog(@"Send event %@.%@ error:%@", namespace, name, error.localizedDescription);
        }else{
            NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
            NSLog(@"Send event Success");
        }
    }] resume];
}

- (NSString *) extractBoundaryWithContentTypeHeader: (NSString *)contentTypeHeader{
    NSString *boundary;
    NSRange ctbRand = [contentTypeHeader rangeOfString:@"boundary=.*?;" options:NSRegularExpressionSearch];
    if (ctbRand.location != NSNotFound){
        NSString *boundryNSS = [contentTypeHeader substringWithRange:ctbRand];
        boundary = [boundryNSS substringWithRange:NSMakeRange(9, boundryNSS.length - 10)];
    }
    return boundary;
}

- (NSArray *) extractDirectivesWithData:(NSData *)data Boundary: (NSString *)boundary{
    NSMutableArray *directives = [[NSMutableArray alloc] initWithCapacity:10];
    NSData *innerBoundry = [[NSString stringWithFormat:@"--%@", boundary] dataUsingEncoding:kCFStringEncodingUTF8];
    NSData *endBoundry = [[NSString stringWithFormat:@"--%@--", boundary] dataUsingEncoding:kCFStringEncodingUTF8];
    NSData *contentTypeApplicationJson = [@"Content-Type: application/json; charset=UTF-8" dataUsingEncoding:kCFStringEncodingUTF8];
    NSData *contentTypeAudio = [@"Content-Type: application/octet-stream" dataUsingEncoding:kCFStringEncodingUTF8];
    NSData *headerEnd = [@"\r\n\r\n" dataUsingEncoding:kCFStringEncodingUTF8];
    long startIndex = 0;
//    long rangeLength = [data length];
//    NSURL *directory = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
//    NSURL *fileURL = [directory URLByAppendingPathComponent:@"dataTmp.tmp"];
//    
//    [data writeToURL:fileURL atomically:YES];
//    NSLog(@"MyData = %@=====%@", innerBoundry, fileURL.absoluteString);
    while (YES) {
        
        NSRange firstAppearance = [data rangeOfData:innerBoundry Range:NSMakeRange(startIndex, [data length]-startIndex)];
        NSLog(@"firstAppearance low = %ld, max = %ld", firstAppearance.location, firstAppearance.length+firstAppearance.location);
        if (firstAppearance.length == 0){
            break;
        }
        NSRange secondAppearance = [data rangeOfData:innerBoundry Range:NSMakeRange((firstAppearance.location+firstAppearance.length), data.length - (firstAppearance.location+firstAppearance.length))];
        
        if (secondAppearance.length == 0){
            secondAppearance = [data rangeOfData:endBoundry Range:NSMakeRange((firstAppearance.location+firstAppearance.length), data.length - (firstAppearance.location+firstAppearance.length))];
            
            if (secondAppearance.length == 0){
                break;
            }
            NSLog(@"secondAppearance1 low = %ld, max = %ld", secondAppearance.location, secondAppearance.length+secondAppearance.location);
        }else{
            NSLog(@"secondAppearance2 low = %ld, max = %ld", secondAppearance.location, secondAppearance.length+secondAppearance.location);
            startIndex = secondAppearance.location;
        }
        NSData *subdata = [data subdataWithRange:NSMakeRange(firstAppearance.location+firstAppearance.length, secondAppearance.location - (firstAppearance.location + firstAppearance.length))];
        NSRange contentType = [subdata rangeOfData:contentTypeApplicationJson Range:NSMakeRange(0, subdata.length)];
        if (contentType.length > 0){
            
            NSRange headerRange = [subdata rangeOfData:headerEnd Range:NSMakeRange(0, subdata.length)];
            
            NSString *directiveData = [[NSString alloc] initWithData:[subdata subdataWithRange:NSMakeRange((headerRange.location+headerRange.length), subdata.length - (headerRange.location+headerRange.length))] encoding:kCFStringEncodingUTF8];
            directiveData = [directiveData stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
            [directives addObject:@{@"contentType": @"application/json", @"data": [directiveData dataUsingEncoding:kCFStringEncodingUTF8] }];
        }
        contentType = [subdata rangeOfData:contentTypeAudio Range:NSMakeRange(0, subdata.length)];
        if (contentType.length > 0){
            NSRange headerRane = [subdata rangeOfData:headerEnd Range:NSMakeRange(0, subdata.length)];
            NSData *audioData = [subdata subdataWithRange:NSMakeRange((headerRane.location + headerRane.length), subdata.length - (headerRane.location + headerRane.length))];
            [directives addObject:@{@"contentType": @"application/octet-stream", @"data": audioData }];
        }
    }
    return directives;
}

- (void) urlSession:(NSURLSession *)session DataTask: (NSURLSessionTask *)dataTask didReceive:(NSData *)data {
    NSString *dataString = [[NSString alloc] initWithData:data encoding:kCFStringEncodingUTF8];
    NSRange firstBracket = [dataString rangeOfString:@"{"];
    NSRange lastBracket = [dataString rangeOfString:@"}" options:NSBackwardsSearch];
    NSString *jsonString = [dataString substringWithRange:NSMakeRange(firstBracket.location, lastBracket.location+lastBracket.length - firstBracket.location)];
    self.downchannelHandler(jsonString);
}

@end

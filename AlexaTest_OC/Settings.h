//
//  Settings.h
//  AlexaTest_OC
//
//  Created by lanmi on 2017/6/13.
//  Copyright © 2017年 lanmi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Settings : NSObject
+ (NSString *) APPLICATION_TYPE_ID;
+ (NSString *) DNS;
+ (NSArray *) SCOPES;
+ (NSString *) SCOPE_DATA;
+ (NSString *) TEMP_FILE_NAME;
+ (NSDictionary *) RECORDING_SETTING;
+ (float) SILENCE_THRESHOLD;
@end

//
//  BleTool.h
//  QCY_SPORT
//
//  Created by lanmi on 16/6/13.
//  Copyright © 2016年 lanmi. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "BleTool.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define NOTIFICATION_START  @"start"
#define NOTIFICATION_STOP @"stop"
#define NOTIFICATION_CONNECTSUCCESS @"connectSuccess"
#define NOTIFICATION_DISCONNECT @"disconnect"
#define NOTIFICATION_SEARCHBLE @"searchBLE"

@interface BleTool : NSObject<CBCentralManagerDelegate,CBPeripheralDelegate>
@property(nonatomic,assign)BOOL isConected;
@property(nonatomic,assign)BOOL Scan; // 是否扫描
@property(readonly, nonatomic, assign) NSString * _Nullable UUIDString;
@property(readonly, nonatomic, assign) NSString * _Nullable name;
+(instancetype _Nonnull )sharebleManager;
-(void)connectPeripheral:(NSString *_Nonnull)uuid Type:(int)dtype;
- (void) cancelConnection;
@end

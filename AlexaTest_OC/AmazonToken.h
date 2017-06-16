//
//  AmazonToken.h
//  AlexaTest_OC
//
//  Created by lanmi on 2017/6/13.
//  Copyright © 2017年 lanmi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AmazonToken : NSObject
@property (strong, nonatomic) NSString *loginWithAmazonToken;
+ (instancetype) sharedInstance;
@end

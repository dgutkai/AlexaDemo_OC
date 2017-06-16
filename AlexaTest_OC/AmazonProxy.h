//
//  AmaazonProxy.h
//  AlexaTest_OC
//
//  Created by lanmi on 2017/6/13.
//  Copyright © 2017年 lanmi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LoginWithAmazon/LoginWithAmazon.h>
@interface AmazonProxy : NSObject
+ (instancetype) sharedInstance;
- (void) loginWithDelegate:(id<AIAuthenticationDelegate>) delegate;
- (void) logoutWithDelegate: (id<AIAuthenticationDelegate>) delegate;
- (void) getAccessTokenWithDelegate: (id<AIAuthenticationDelegate>) delegate;
@end

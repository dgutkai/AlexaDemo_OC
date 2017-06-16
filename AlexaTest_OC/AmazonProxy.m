//
//  AmaazonProxy.m
//  AlexaTest_OC
//
//  Created by lanmi on 2017/6/13.
//  Copyright © 2017年 lanmi. All rights reserved.
//

#import "AmazonProxy.h"

#import "Settings.h"
@implementation AmazonProxy

+ (instancetype) sharedInstance{
    static AmazonProxy *instance = nil;
    @synchronized (self) {
        if (!instance){
            instance = [AmazonProxy new];
        }
    }
    return instance;
}

- (void) loginWithDelegate:(id<AIAuthenticationDelegate>) delegate{
    NSString *scopeData = [Settings SCOPE_DATA];
    [AIMobileLib authorizeUserForScopes:[Settings SCOPES] delegate:delegate options:@{kAIOptionScopeData: scopeData}];
}

- (void) logoutWithDelegate: (id<AIAuthenticationDelegate>) delegate {
    [AIMobileLib clearAuthorizationState:delegate];
}

- (void) getAccessTokenWithDelegate: (id<AIAuthenticationDelegate>) delegate{
    [AIMobileLib getAccessTokenForScopes:[Settings SCOPES] withOverrideParams:nil delegate:delegate];
}
@end

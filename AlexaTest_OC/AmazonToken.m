//
//  AmazonToken.m
//  AlexaTest_OC
//
//  Created by lanmi on 2017/6/13.
//  Copyright © 2017年 lanmi. All rights reserved.
//

#import "AmazonToken.h"

@implementation AmazonToken

+ (instancetype) sharedInstance{
    static AmazonToken *instance = nil;
    @synchronized (self) {
        if (!instance){
            instance = [AmazonToken new];
        }
    }
    return instance;
}

@end

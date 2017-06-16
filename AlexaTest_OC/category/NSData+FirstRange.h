//
//  NSData+FirstRange.h
//  AlexaTest_OC
//
//  Created by lanmi on 2017/6/16.
//  Copyright © 2017年 lanmi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (FirstRange)
// 查找data的位置，从前往后查找。
- (NSRange) rangeOfData:(NSData *)data Range: (NSRange) range;
@end

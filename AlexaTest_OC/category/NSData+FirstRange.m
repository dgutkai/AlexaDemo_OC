//
//  NSData+FirstRange.m
//  AlexaTest_OC
//
//  Created by lanmi on 2017/6/16.
//  Copyright © 2017年 lanmi. All rights reserved.
//

#import "NSData+FirstRange.h"

@implementation NSData (FirstRange)

- (NSRange) rangeOfData:(NSData *)data Range: (NSRange) range{
    NSRange resultRange;
    NSRange rangeTemp;
    rangeTemp = [self rangeOfData:data options:NSDataSearchBackwards range:range];
    resultRange = rangeTemp;
    while (rangeTemp.length > 0) {
        rangeTemp = [self rangeOfData:data options:NSDataSearchBackwards range:NSMakeRange(range.location, rangeTemp.location-range.location)];
        if (rangeTemp.length > 0){
            resultRange = rangeTemp;
        }
    }
    return resultRange;
}
@end

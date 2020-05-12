//
//  __RefCodeEx.h
//  IOSGame-mobile
//
//  Created by work on 2018/11/22.
//

#import <Foundation/Foundation.h>

@interface __RefCodeEx : NSObject{
    NSString * _name;
    NSInteger * _value;
}

- (void)readTxt:(NSString *)fileName;
- (void)writeTxt:(NSDictionary *)dict;

+ (__RefCodeEx *)newRefCodeEx;

@end

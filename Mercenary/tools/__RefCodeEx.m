//
//  __RefCodeEx.m
//  IOSGame-mobile
//
//  Created by work on 2018/11/22.
//

#import "__RefCodeEx.h"

int G_Value = 0;

@implementation __RefCodeEx

- (id)init
{
    srandom((unsigned int)time(NULL));
    int random = (int)(arc4random() % 100) + 1;
    
    if (random % 2 == 0){
        [self readTxt:@"AAA"];
    }
    else{
        NSDictionary * dic = [[NSDictionary alloc] init];
        [dic setValue:@"BBB" forKey:@"content"];
        [dic setValue:@"CCC" forKey:@"path"];
        [self writeTxt: dic];
    }
    return self;
}

- (void)readTxt:(NSString *)fileName
{
    NSLog(@"(void)readTxt:(NSString *)fileName");
    G_Value = G_Value + 10;
}

- (void)writeTxt:(NSDictionary *)dict
{
    NSLog(@"(void)readTxt:(NSString *)fileName");
    G_Value = G_Value - 5;
}

+ (__RefCodeEx *)newRefCodeEx
{
    return [[__RefCodeEx alloc] init];
}

@end

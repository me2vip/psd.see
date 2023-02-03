//
//  SQUserDataView.m
//  CbrexHouse
//
//  Created by Larry on 15/7/10.
//  Copyright (c) 2015年 Cbrex. All rights reserved.
//

#import "SQUserDataView.h"

@interface SQUserDataView ()

@property (nonatomic, retain)NSMutableDictionary* sqUserData;

@end

@implementation SQUserDataView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(void)setUserData:(id)value forKey:(NSString *)key
{
    if (nil == self.sqUserData)
    {
        self.sqUserData = [NSMutableDictionary dictionary];
    }
    
    [self.sqUserData setValue:value forKey:key];
}

-(id)userDataForKey:(NSString *)key
{
    return [self.sqUserData valueForKey:key];
}

-(void)dealloc
{
    [_sqUserData release];
    
    [super dealloc];
    NSLog(@"%s-%d", __func__, __LINE__);
}

@end

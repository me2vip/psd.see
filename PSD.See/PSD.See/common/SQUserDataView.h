//
//  SQUserDataView.h
//  CbrexHouse
//
//  Created by Larry on 15/7/10.
//  Copyright (c) 2015年 Cbrex. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SQUserDataView : UIView

-(void)setUserData:(id)value forKey:(NSString*)key;
-(id)userDataForKey:(NSString*)key;

@end

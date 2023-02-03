//
//  ViewCtrlAddServer.h
//  PSD.See
//
//  Created by Larry on 16/10/16.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "SQViewController.h"

@protocol AddServerDelegate <NSObject>

-(void)serverAddByIp:(NSString*)serverIp andPassword:(NSString*)password;

@end

@interface ViewCtrlAddServer : SQViewController

@property(nonatomic, assign)id<AddServerDelegate> psAddServerDelegate;

@end

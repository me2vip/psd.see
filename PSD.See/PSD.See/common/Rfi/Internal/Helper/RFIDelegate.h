//
//  RFIDelegate.h
//  RfiFormat
//
//  Created by Mgen on 14-7-3.
//  Copyright (c) 2014年 Mgen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RFIDelegate : NSObject
@property (nonatomic, assign) SEL sel;
@property (nonatomic, retain) id rfiObj;

- (id)invokeFunc;
- (id)invokeFunc:(id)pa1;
- (void)invokeAction;
- (void)invokeAction:(id)pa1;

@end

//
//  KDViewPager.h
//  KDViewPager
//
//  Created by kyle on 16/4/19.
//  Copyright © 2016年 kyleduo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KDViewPager;

@protocol KDViewPagerDelegate <NSObject>

-(void)kdViewpager:(KDViewPager *)viewPager didSelectPage:(NSUInteger)index direction:(UIPageViewControllerNavigationDirection)direction selectedViewController:(UIViewController*)viewController;
-(void)kdViewpager:(KDViewPager *)viewPager willSelectPage:(NSUInteger)index direction:(UIPageViewControllerNavigationDirection)direction selectedViewController:(UIViewController*)viewController;

@end

@protocol KDViewPagerDatasource <NSObject>

-(NSUInteger)numberOfPages:(KDViewPager *)viewPager;
-(UIViewController *)kdViewPager:(KDViewPager *)viewPager controllerAtIndex:(NSUInteger)index cachedController:(UIViewController *)cachedController;

@end


@interface KDViewPager : NSObject

@property (nonatomic, assign) id<KDViewPagerDelegate> delegate;
@property (nonatomic, assign) id<KDViewPagerDatasource> datasource;
@property (nonatomic, readonly) UIView *pagerView;
@property (nonatomic, assign) NSUInteger currentPage;
/// whether has bounces effect, YES by default;
@property (nonatomic, assign) BOOL bounces;

-(instancetype)initWithController:(UIViewController *)controller;
-(instancetype)initWithController:(UIViewController *)controller inView:(UIView *)hostView;
-(instancetype)initWithController:(UIViewController *)controller configView:(void(^)(UIView *hostView, UIView *pagerView))configBlock;

-(void)reload;
-(void)setCurrentPage:(NSUInteger)currentPage animated:(BOOL)animated;

@end
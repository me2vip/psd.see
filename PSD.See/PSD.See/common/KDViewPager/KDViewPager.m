//
//  KDViewPager.m
//  KDViewPager
//
//  Created by kyle on 16/4/19.
//  Copyright © 2016年 kyleduo. All rights reserved.
//

#import "KDViewPager.h"

@interface KDViewPager() <UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIScrollViewDelegate>
@property (nonatomic, assign) UIViewController *hostController;
@property (nonatomic, retain) UIView *hostView;
@property (nonatomic, retain) UIPageViewController *pager;
@property (nonatomic, retain) NSMutableDictionary *viewControllers;
@end

@implementation KDViewPager

-(instancetype)initWithController:(UIViewController *)controller {
	return [self initWithController:controller inView:nil];
}

-(instancetype)initWithController:(UIViewController *)controller configView:(void(^)(UIView *hostView, UIView *pagerView))configBlock {
	return [self initWithController:controller inView:nil configView:configBlock];
}

-(instancetype)initWithController:(UIViewController *)controller inView:(UIView *)hostView {
	return [self initWithController:controller inView:hostView configView:^(UIView *hostView, UIView *pagerView) {
		NSDictionary *dict = @{@"view":pagerView};
		[pagerView setTranslatesAutoresizingMaskIntoConstraints:NO];
		[hostView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:dict]];
		[hostView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:dict]];
	}];
}


-(instancetype)initWithController:(UIViewController *)controller inView:(UIView *)hostView configView:(void(^)(UIView *hostView, UIView *pagerView))configBlock {
	self = [super init];
	if (self) {
		self.hostController = controller;
		self.hostView = hostView ? hostView : self.hostController.view;
		[self commonInit:configBlock];
	}
	return self;
}


/**
 * Common method to initial view pager.
 */
-(void)commonInit:(void(^)(UIView *, UIView *))configViewBlock {
	NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:UIPageViewControllerSpineLocationMin]
														forKey:UIPageViewControllerOptionSpineLocationKey];
	self.pager = [[[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:options] autorelease];
	_pagerView = [self.pager.view retain];
	self.pager.edgesForExtendedLayout = UIRectEdgeNone;
	self.pager.delegate = self;
	self.pager.dataSource = self;
	// support no-bounce effect
	for (UIView *view in self.pager.view.subviews) {
		if ([view isKindOfClass:[UIScrollView class]]) {
			((UIScrollView *)view).delegate = self;
			break;
		}
	}
	[self.hostController addChildViewController:self.pager];
	[self.pager didMoveToParentViewController:self.hostController];
	if (self.hostView) {
		[self.hostView addSubview:self.pager.view];
		if (configViewBlock) {
			configViewBlock(self.hostView, self.pager.view);
		}
	}
	
	// bounces is ON by default.
	self.bounces = YES;
}


#pragma mark - getter & setter
-(NSMutableDictionary *)viewControllers {
	if (!_viewControllers)
    {
		NSUInteger capacity = 10;
		if (self.datasource) {
			NSUInteger count = [self.datasource numberOfPages:self];;
			capacity = count > 0 ? count : 1;
		}
        _viewControllers = [[NSMutableDictionary alloc] initWithCapacity:capacity]; //[NSMutableDictionary dictionaryWithCapacity:capacity];
	}
	return _viewControllers;
}

-(void)setDelegate:(id<KDViewPagerDelegate>)delegate {
	_delegate = delegate;
	
}

-(void)setDatasource:(id<KDViewPagerDatasource>)datasource {
	_datasource = datasource;
	
	if (_datasource) {
		[self reload];
	}
}

-(void)setCurrentPage:(NSUInteger)currentPage {
	[self setCurrentPage:currentPage animated:YES];
}

-(void)setCurrentPage:(NSUInteger)currentPage animated:(BOOL)animated {
	NSUInteger count = [self.datasource numberOfPages:self];
	if (count == 0) {
		self.currentPage = 0;
		return;
	}
	if (currentPage == self.currentPage) {
		return;
	}
	if (currentPage >= count - 1) {
		currentPage = count - 1;
	}
	
	UIViewController *vc = [self controllerAtIndex:currentPage];
	if (vc != nil) {
		BOOL forward = currentPage > self.currentPage;
		NSArray *viewControllers = @[vc];
		[self.pager setViewControllers:viewControllers
						 direction:forward ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse
						  animated:animated
						completion:^(BOOL finished) {
							if (finished) {
								self.currentPage = currentPage;
								if (self.delegate) {
									[self.delegate kdViewpager:self didSelectPage:currentPage direction:forward selectedViewController:vc];
								}
							}
						}];
	}
}

-(void)reload {
	UIViewController *vc0 = [self controllerAtIndex:0];
	if (vc0 != nil) {
		NSArray *viewControllers = @[vc0];
		[self.pager setViewControllers:viewControllers
						 direction:UIPageViewControllerNavigationDirectionForward
						  animated:NO
						completion:nil];
	}
}

#pragma mark - private
-(NSUInteger)indexOfViewController:(UIViewController *)viewController {
	NSArray *keys = [self.viewControllers allKeysForObject:viewController];
	if (keys == nil || keys.count == 0) {
		return NSNotFound;
	} else if (keys.count == 1) {
		return ((NSNumber *)keys.firstObject).unsignedIntegerValue;
	} else {
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"View controller should be unique" userInfo:nil];
	}
}

-(UIViewController *)getViewControllerAfter:(BOOL)after viewController:(UIViewController *)viewController {
	NSUInteger index = viewController == nil ? NSNotFound : [self indexOfViewController:viewController];
	if (NSNotFound == index) {
		index = after ? 0 : -1;
	} else {
		index += after ? 1 : -1;
	}
	NSUInteger count = [self.datasource numberOfPages:self];
	if (index >= count) {
		return nil;
	}
	
	return [self controllerAtIndex:index];
}

-(UIViewController *)controllerAtIndex:(NSUInteger)index {
	NSUInteger count = [self.datasource numberOfPages:self];
	UIViewController *cached = [self.viewControllers objectForKey:@(index)];
	UIViewController *controller = nil;
	
	if (count > 0) {
		controller = [self.datasource kdViewPager:self controllerAtIndex:index cachedController:cached];
		
		if (controller != nil) {
			[self.viewControllers setObject:controller forKey:@(index)];
		}
	}
	
	return controller;
}

#pragma mark - scrollview delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (self.bounces) {
		return;
	}
	NSUInteger count = [self.datasource numberOfPages:self];
	if (self.currentPage == 0 && scrollView.contentOffset.x < scrollView.bounds.size.width) {
		scrollView.contentOffset = CGPointMake(scrollView.bounds.size.width, 0);
	}
	if ((count == 0 || self.currentPage >= count - 1) && scrollView.contentOffset.x > scrollView.bounds.size.width) {
		scrollView.contentOffset = CGPointMake(scrollView.bounds.size.width, 0);
	}
}
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
	if (self.bounces) {
		return;
	}
	NSUInteger count = [self.datasource numberOfPages:self];
	if (self.currentPage == 0 && scrollView.contentOffset.x <= scrollView.bounds.size.width) {
		*targetContentOffset = CGPointMake(scrollView.bounds.size.width, 0);
	}
	if ((count == 0 || self.currentPage >= count - 1) && scrollView.contentOffset.x >= scrollView.bounds.size.width) {
		*targetContentOffset = CGPointMake(scrollView.bounds.size.width, 0);
	}
}

#pragma mark - delegate

-(void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
	if(completed) {
		NSUInteger index = [self indexOfViewController:[pageViewController.viewControllers objectAtIndex:0]];
		if (index != NSNotFound) {
			if (self.delegate) {
				[self.delegate kdViewpager:self didSelectPage:index direction:self.currentPage < index ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse selectedViewController:[self controllerAtIndex:index]];
			}
			self.currentPage = index;
		}
	}
}

-(void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers {
	if (self.delegate) {
		NSUInteger index = [self indexOfViewController:[pendingViewControllers objectAtIndex:0]];
		if (index != NSNotFound) {
			[self.delegate kdViewpager:self willSelectPage:index direction:self.currentPage < index ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse selectedViewController:[pendingViewControllers objectAtIndex:0]];
		}
	}
}

#pragma mark - datasource

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
	return [self getViewControllerAfter:YES viewController:viewController];
}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
	return [self getViewControllerAfter:NO viewController:viewController];
}

-(void)dealloc
{
    [_pagerView release];
    [_hostView release];
    [_pager release];
    [_viewControllers release];
    
    [super dealloc];
}

@end

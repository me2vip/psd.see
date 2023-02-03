//
//  ViewController.m
//  PSD.See
//
//  Created by Larry on 16/9/5.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "ViewCtrlMain.h"
#import "psdata.h"
#import "SQManager.h"
#import "datamodel.h"
#import "ViewCtrlDrawing.h"
#import "../common/UIView+SQLayerAndKeyValue.h"
#import "../Datas/SQListItem.h"
#import "SQListItem.h"
#import "MBProgressHUD.h"
#import "MBProgressHUD+Toast.h"
#import "ASIHTTPRequest.h"
#import "JSONKit.h"
#import "ViewCtrlFileServer.h"
#import "ViewCtrlScan.h"
#import "SQConstant.h"
#import <CoreLocation/CoreLocation.h>

enum
{
    PS_MENU_DELETE = 1000 //删除
    , PS_MENU_ABOUT //关于
    , PS_MENU_REMOTE_CONNECT //远程连接帮助
    , PS_MENU_CHECK_UPDATE //更新检查
    , PS_MENU_REVIEW //评论
    , PS_MENU_OPEN_PHOTOS //打开相册
    , PS_MENU_HELP //使用帮助
    , PS_MENU_REFRESH //刷新文件列表
    
    , ALERT_VERSION_UPDATE
    , ALERT_COMMENT
};

@interface ViewCtrlMain ()<UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, UIAlertViewDelegate, PSFileAddedByScanDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

- (IBAction)onClickMenu:(id)sender;
- (IBAction)onClickDeleteButton;
- (IBAction)onClickFileServer:(id)sender;

@property (retain, nonatomic) IBOutlet UIView *psViewTitle;
@property (retain, nonatomic) IBOutlet UITableView *psTableView;
@property (nonatomic, retain) NSMutableArray* psListFiles;
@property (nonatomic, retain) NSMutableArray* psListMenu;
@property (retain, nonatomic) IBOutlet UIView *psViewFunction;
@property (retain, nonatomic) IBOutlet UITableView *psTableViewFunction;
@property (nonatomic, retain) ASIHTTPRequest* psRequest;
@property (nonatomic, assign) BOOL psCommentShow; //评论是否已显示
@property (nonatomic, copy) NSString* psServerVersion; //服务器端版本
@property (retain, nonatomic) NSMutableArray* psLayoutConstraints; //布局属性列表
@property (retain, nonatomic) CLLocationManager* locationManager; //定位服务

@end

@implementation ViewCtrlMain

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [SQManager setExtraCellLineHidden:self.psTableView];
    [SQManager setExtraCellLineHidden:self.psTableViewFunction];
    self.psListFiles = [NSMutableArray array];
    self.psListMenu = [NSMutableArray array];
    
    self.psViewFunction.hidden = YES;
    
    [self.psListMenu addObject:[SQListItem listItemWithType:PS_MENU_OPEN_PHOTOS]];
    [self.psListMenu addObject:[SQListItem listItemWithType:PS_MENU_REFRESH]];
    [self.psListMenu addObject:[SQListItem listItemWithType:PS_MENU_HELP]];
    [self.psListMenu addObject:[SQListItem listItemWithType:PS_MENU_REMOTE_CONNECT]];
    [self.psListMenu addObject:[SQListItem listItemWithType:PS_MENU_CHECK_UPDATE]];
    [self.psListMenu addObject:[SQListItem listItemWithType:PS_MENU_REVIEW]];
    [self.psListMenu addObject:[SQListItem listItemWithType:PS_MENU_ABOUT]];
    [self setNeedsStatusBarAppearanceUpdate];
    
    UITapGestureRecognizer* singleTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)] autorelease];
    [singleTap setDelegate:self];
    [self.psViewFunction addGestureRecognizer:singleTap];
    
#if SHOW_ADS
    // Replace this ad unit ID with your own ad unit ID.
    //self.psBannerView.adUnitID = @"ca-app-pub-3940256099942544/2934735716"; //测试id
    self.psBannerView.adUnitID = @"ca-app-pub-2925148926153054/8778318320";
    self.psBannerView.rootViewController = self;
    //self.psBannerView.adSize = kGADAdSizeSmartBannerLandscape;
    
    GADRequest *request = [GADRequest request];
    // Requests test ads on devices you specify. Your test device ID is printed to the console when
    // an ad request is made. GADBannerView automatically returns test ads when running on a
    // simulator.
    request.testDevices = @[
                            @"bd9a4a5a08499bf693087e78520a5b9a", @"94af4af21f1c3cf20c296729d25cbf58"  // Eric's iPod Touch
                            ];
    [self.psBannerView loadRequest:request];
#endif
    
    [self addFile2List];
    
    [self performSelector:@selector(versionCheckOnBack) withObject:nil afterDelay:1]; //后台进行版本检查
    self.psLayoutConstraints = [NSMutableArray array];
}

/**
 设置iphone x布局
 */
-(void)setDeviceLayout{
    UIView* titleView = self.psViewTitle;
    UIView* tableView = self.psTableView;
    
    NSDictionary *views = @{@"titleView":titleView, @"tableView":tableView};
    NSArray* constraints = nil;
    //先删除上次的布局,为新的布局做准备
    [self.view removeConstraints:self.psLayoutConstraints];
    [self.psLayoutConstraints removeAllObjects];
    
    if (UIDeviceOrientationPortrait == self.interfaceOrientation || UIDeviceOrientationPortraitUpsideDown == self.interfaceOrientation) {
        //竖屏
        if ([SQManager isIphoneX]) { //浏海屏
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[titleView(84)]-0-[tableView]-0-|" options:0 metrics:nil views:views];
        } else { //非浏海屏
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[titleView(64)]-0-[tableView]-0-|" options:0 metrics:nil views:views];
        }
    } else {
        //横屏
        if ([SQManager isIphoneX]) { //浏海屏
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[titleView(54)]-0-[tableView]-0-|" options:0 metrics:nil views:views];
        } else { //非浏海屏
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[titleView(44)]-0-[tableView]-0-|" options:0 metrics:nil views:views];
        }
    }
    [self.psLayoutConstraints addObjectsFromArray:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[titleView]-0-|" options:0 metrics:nil views:views];
    [self.psLayoutConstraints addObjectsFromArray:constraints];
    
    [self.view addConstraints:self.psLayoutConstraints];
}

/**
 屏幕旋转
 */
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    NSLog(@"%s-%d now orientation:%ld", __func__, __LINE__, self.interfaceOrientation);
    //屏幕已旋转, 设置相关控件的布局
    [self setDeviceLayout];
}

//请求定位权限
-(void)requestLocationAuthorization {
     NSString* phoneVersion = [[UIDevice currentDevice] systemVersion];
        CGFloat version = [phoneVersion floatValue]; //当前系统版本
    //     如果是iOS13 未开启地理位置权限 需要提示一下
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined && version >= 13) {
            self.locationManager = [[[CLLocationManager alloc] init] autorelease];
            [self.locationManager requestWhenInUseAuthorization];
        }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setDeviceLayout]; //处理刘海屏布局
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    
    [self.psTableView reloadData];
    
    if (NO == self.psCommentShow)
    {
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
        NSNumber* lastCommentTime = [userDefault objectForKey:SQ_LAST_COMMENT_TIME];
        NSLog(@"%s-%d now:%ld, last:%ld, interval_time:%ld", __func__, __LINE__, time(NULL), lastCommentTime.longValue, (lastCommentTime.longValue - time(NULL))/60/60/24);
        
        if (time(NULL) >= lastCommentTime.longValue)
        {
            //提示用户评论
            UIAlertView* alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PSD.See", @"PSD.See") message:NSLocalizedString(@"comment_info", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"comment_cancel", @"") otherButtonTitles:NSLocalizedString(@"comment_ok", @""), nil, nil] autorelease];
            alertView.tag = ALERT_COMMENT;
            [alertView show];
            self.psCommentShow = YES;
        }
    }
    
    [self requestLocationAuthorization]; //请求定位权限
    
#if 0
    GADInterstitial* ads = [SQManager sharedSQManager].sqInterstitial;
    if (FALSE == ads.hasBeenUsed && ads.isReady)
    {
        //插页广告还没显示,显示插页广告
        //[self performSegueWithIdentifier:@"main2ads" sender:nil];
        
        //获取storyboard: 通过bundle根据storyboard的名字来获取我们的storyboard,
        UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        //由storyboard根据myView的storyBoardID来获取我们要切换的视图
        self.psAdsViewCtrl = [story instantiateViewControllerWithIdentifier:@"ViewCtrlInterAds"];
        self.definesPresentationContext = YES;
        self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        self.psAdsViewCtrl.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [self presentViewController:self.psAdsViewCtrl animated:YES completion:nil];
        [self performSelector:@selector(dismissAdsViewCtrl) withObject:nil afterDelay:3];
    }
#endif
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (ALERT_VERSION_UPDATE == alertView.tag)
    {
        //版本更新
        //用户开始版本更新
        if (0 == buttonIndex) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/us/app/id1257770958?mt=8"]];
        } else {
            //忽略该版本
            NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
            [userDefault setObject:self.psServerVersion forKey:SQ_IGNORE_VERSION];
        }
    }
    else if(ALERT_COMMENT == alertView.tag)
    {
        //评论或跳过评论
        if (0 == buttonIndex)
        {
            //取消了评论
            NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
            [userDefault setObject:@(time(NULL) + SQ_MIN_COMMENT_TIME) forKey:SQ_LAST_COMMENT_TIME];
        }
        else
        {
            //评论
            NSString* reviewUrl = @"itms-apps://itunes.apple.com/app/id1257770958";
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewUrl]];
            
            NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
            [userDefault setObject:@(time(NULL) + SQ_MAX_COMMENT_TIME) forKey:SQ_LAST_COMMENT_TIME];
        }
    }
}

-(void)onFileScanSuccessWithPath:(NSString*)filePath
{
    if (FALSE == self.sqAppeared)
    {
        [self performSelector:@selector(onFileScanSuccessWithPath:) withObject:filePath afterDelay:0.3];
        return;
    }
    
    FileItem* fileItem = [FileItem getFileItemByPath:filePath];
    if (fileItem)
    {
        [self.psListFiles insertObject:fileItem atIndex:2];
        [self performSegueWithIdentifier:@"main2view" sender:fileItem];
    }
    else
    {
        [MBProgressHUD Toast:NSLocalizedString(@"file_invalid", @"file_invalid") toView:self.view andTime:1];
    }
}

/**
 根据文件的路径获取相应的文件节点
 */
-(FileItem*)getFileItemByPath:(NSString*)filePath
{
    FileItem* fileItem = nil;
    
    for (id item in self.psListFiles)
    {
        if ([item isKindOfClass:[FileItem class]])
        {
            fileItem = item;
            if ([fileItem.psFilePath isEqualToString:filePath])
            {
                return fileItem;
            }
        }
    }
    return nil;
}

-(BOOL)isFilePathHasInList:(NSString*)filePath
{
    if ([self getFileItemByPath:filePath])
    {
        return YES;
    }
    
    return NO;
}

/**
将文件添加到列表里
 */
-(void)addFile2List
{
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docPath = [path objectAtIndex:0];
    NSLog(@"docPath:%@", docPath);
    
    //[self.psListFiles removeAllObjects]; //先清空文件列表
    
    //先添加样例图
    FileItem* fileItem = [[[FileItem alloc] init] autorelease];
    fileItem.psPsdImage = [[NSBundle mainBundle]pathForResource:@"simple_psd" ofType:@"jpg"];
    fileItem.psOpenTime = 0;
    fileItem.psFilePath = [[NSBundle mainBundle]pathForResource:@"simple" ofType:@"psd"];;
    fileItem.psExtInfo = @"RGB 1024*800";
    fileItem.psFileLength = 8007742;
    fileItem.psIndex = -100;
    [self.psListFiles addObject:fileItem];
    
    fileItem = [[[FileItem alloc] init] autorelease];
    fileItem.psPsdImage = @"";
    fileItem.psOpenTime = 0;
    fileItem.psFilePath = [[NSBundle mainBundle]pathForResource:@"simple" ofType:@"png"];;
    fileItem.psExtInfo = @"640*1136";
    fileItem.psFileLength = 85118;
    fileItem.psIndex = -101;
    [self.psListFiles addObject:fileItem];

    [FileItem putFileInList:self.psListFiles];
    
    if (self.psListFiles.count > 2)
    {
        //文件信息已保存到数据库中,无需重复扫描
        [self.psListFiles addObject:[SQListItem listItemWithType:1000]];
        return;
    }
    
    //添加外部目录进来的文件
    NSString* fileName;
    NSString* fullPath = nil;
    BOOL isDir;
    NSString* inBoxDir = [docPath stringByAppendingPathComponent:@"Inbox"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:inBoxDir];
    
    /**
    NSError* error = nil;
    NSArray* docFileList = [fileManager contentsOfDirectoryAtPath:docPath error:&error];
    NSArray* inboxFileList = [fileManager contentsOfDirectoryAtPath:inBoxDir error:&error];
    **/
    
    while (fileName = [dirEnum nextObject])
    {
        fullPath = [inBoxDir stringByAppendingPathComponent:fileName];
        [fileManager fileExistsAtPath:fullPath isDirectory:&isDir];
        if(isDir)
        {
            [dirEnum skipDescendants]; //禁止深度遍历
        }
        else if (NO == [self isFilePathHasInList:fullPath])
        {
            fileItem = [FileItem getFileItemByPath:fullPath];
            if (fileItem)
            {
                [self.psListFiles addObject:fileItem];
            }
        }
    }
    
    //添加doc目录下文件
    dirEnum = [fileManager enumeratorAtPath:docPath];
    while (fileName = [dirEnum nextObject])
    {
        fullPath = [docPath stringByAppendingPathComponent:fileName];
        [fileManager fileExistsAtPath:fullPath isDirectory:&isDir];
        if (isDir)
        {
            [dirEnum skipDescendants]; //禁止深度遍历
        }
        else if (NO == [self isFilePathHasInList:fullPath])
        {
            fileItem = [FileItem getFileItemByPath:fullPath];
            if (fileItem)
            {
                [self.psListFiles addObject:fileItem];
            }
        }
    }

    [self.psListFiles addObject:[SQListItem listItemWithType:1000]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [_psTableView release];
    [_psListFiles release];
    [_psListMenu release];
    [_psViewFunction release];
    [_psTableViewFunction release];
    [_psRequest release];
    [_psLayoutConstraints release];
    [_psViewTitle release];
    [_locationManager release];
    [super dealloc];
}

- (UITableViewCell *)setImageTableViewAtIndex:(NSIndexPath *)indexPath
{
    UITableViewCell* viewCell = nil;
    id tbItem = self.psListFiles[indexPath.row];
    
    if([tbItem isKindOfClass:[FileItem class]])
    {
        viewCell = [self.psTableView dequeueReusableCellWithIdentifier:@"CELL_ITEM"];
        FileItem* item = tbItem;
        UIImage* fileImage = nil;
        NSString* relativePath = [FileItem getRelativePathInDoc:item.psFilePath];
        NSString* smallImagePath = [SQManager sharedSQManager].sqPsdImagePath;
        smallImagePath = [smallImagePath stringByAppendingPathComponent:[SQManager getStringCRC32:relativePath]];
        smallImagePath = [smallImagePath stringByAppendingString:@"_small"];
        NSFileManager* fileManager = [NSFileManager defaultManager];
        UIImage* bigImage = nil;
        CGSize smallImgSize;
        NSData* psdImageData = nil;
        
        UIImageView* imageView = (UIImageView*)[viewCell viewWithTag:100];
        [SQManager addBorderToView:imageView width:0.5 color:[UIColor grayColor] cornerRadius:0];
        
        if (-100 == item.psIndex) {
            fileImage = [UIImage imageNamed:@"simple_psd_small.jpg"];
        } else if (-101 == item.psIndex) {
            fileImage = [UIImage imageNamed:@"simple_small.png"];
        } else if ([fileManager fileExistsAtPath:smallImagePath]) {
            //小图已存在
            fileImage = [UIImage imageWithContentsOfFile:smallImagePath];
        } else {
            //小图不存在, 生成小图
            if (item.psPsdImage.length > 0)
            {
                bigImage = [UIImage imageWithContentsOfFile:item.psPsdImage];
            }
            else
            {
                bigImage = [UIImage imageWithContentsOfFile:item.psFilePath];
            }
            
            if (bigImage && bigImage.size.width * bigImage.size.height > SQ_SMALL_IMG_WIDTH * SQ_SMALL_IMG_WIDTH) {
                smallImgSize = CGSizeMake(SQ_SMALL_IMG_WIDTH, SQ_SMALL_IMG_WIDTH * bigImage.size.height / bigImage.size.width);
                fileImage = [SQManager imageToSize:bigImage size:smallImgSize];
                
                if (fileImage) {
                    NSLog(@"%s-%d smallImage:%@ w:%f h:%f", __func__, __LINE__, smallImagePath, fileImage.size.width, fileImage.size.height);
                    psdImageData = UIImageJPEGRepresentation(fileImage, 0.4);
                    [psdImageData writeToFile:smallImagePath atomically:YES];
                }
            } else {
                fileImage = bigImage;
            }
        }
        
        if (nil == fileImage)
        {
            fileImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"default_img" ofType:@"jpg"]];
        }
        
        [imageView setImage:fileImage];
        
        UILabel* label = (UILabel*)[viewCell viewWithTag:101];
        label.text = [item.psFilePath lastPathComponent];
        
        label = (UILabel*)[viewCell viewWithTag:102];
        label.text = item.psExtInfo;
        
        label = (UILabel*)[viewCell viewWithTag:103];
        label.text = [SQManager getFileSize:item.psFileLength];
        
        if (indexPath.row > 0)
        {
            [viewCell.contentView setTopLayerAtX:15 color:[UIColor lightGrayColor] width:4096 height:0.5];
        }
        else
        {
            [viewCell.contentView setTopLayerAtX:0 color:[UIColor clearColor] width:0 height:0];
        }
    }
    else
    {
        //最后一个节点
        viewCell = [self.psTableView dequeueReusableCellWithIdentifier:@"CELL_LAST"];
    }
    
    return viewCell;
}

- (UITableViewCell*)setMenuTableViewAtIndex:(NSIndexPath *)indexPath
{
    SQListItem* item = [self.psListMenu objectAtIndex:indexPath.row];
    UITableViewCell* viewCell = [self.psTableViewFunction dequeueReusableCellWithIdentifier:@"CELL_ITEM"];
    UIImageView* imageView = (UIImageView*)[viewCell viewWithTag:100];
    UILabel* label = (UILabel*)[viewCell viewWithTag:101];
    
    if (PS_MENU_ABOUT == item.sqType)
    {
        [imageView setImage:[UIImage imageNamed:@"about"]];
        label.text = NSLocalizedString(@"about", @"about");
    }
    else if(PS_MENU_DELETE == item.sqType)
    {
        [imageView setImage:[UIImage imageNamed:@"remove_icon"]];
        label.text = NSLocalizedString(@"delete", @"delete");
    }
    else if(PS_MENU_REMOTE_CONNECT == item.sqType)
    {
        [imageView setImage:[UIImage imageNamed:@"sync_icon"]];
        label.text = NSLocalizedString(@"helpRemoteConnect", @"helpRemoteConnect");
    }
    else if(PS_MENU_CHECK_UPDATE == item.sqType)
    {
        [imageView setImage:[UIImage imageNamed:@"check_update"]];
        label.text = NSLocalizedString(@"check_update", @"check_update");
    }
    else if(PS_MENU_REVIEW == item.sqType)
    {
        [imageView setImage:[UIImage imageNamed:@"review"]];
        label.text = NSLocalizedString(@"review_me", @"review_me");
    }
    else if (PS_MENU_OPEN_PHOTOS == item.sqType)
    {
        [imageView setImage:[UIImage imageNamed:@"photos"]];
        label.text = NSLocalizedString(@"open_photos", @"open_photos");
    }
    else if(PS_MENU_HELP == item.sqType)
    {
        [imageView setImage:[UIImage imageNamed:@"help"]];
        label.text = NSLocalizedString(@"help", @"help");
    }
    else if(PS_MENU_REFRESH == item.sqType)
    {
        [imageView setImage:[UIImage imageNamed:@"refresh"]];
        label.text = NSLocalizedString(@"reload_images", @"reload_images");
    }
    
    return viewCell;
}

-(void)selectImageRow:(NSIndexPath*)indexPath
{
    id tbItem = self.psListFiles[indexPath.row];
    
    if([tbItem isKindOfClass:[FileItem class]])
    {
        FileItem* fileItem = tbItem;
        [self performSegueWithIdentifier:@"main2view" sender:fileItem];
    }
}

-(void)openPhotos
{
    UIImagePickerController* pickerImage = [[[UIImagePickerController alloc] init] autorelease];
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        pickerImage.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        //pickerImage.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        pickerImage.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:pickerImage.sourceType];
        
    }
    pickerImage.delegate = self;
    pickerImage.allowsEditing = NO;
    [self presentViewController:pickerImage animated:YES completion:nil];
}

-(void)selectMenuRow:(NSIndexPath*)indexPath
{
    SQListItem* item = [self.psListMenu objectAtIndex:indexPath.row];
    if (PS_MENU_DELETE == item.sqType)
    {
        //删除
        BOOL editing = !([self.psTableView isEditing]);
        [self.psTableView setEditing:editing animated:YES];
    }
    else if(PS_MENU_ABOUT == item.sqType)
    {
        [self performSegueWithIdentifier:@"main2about" sender:nil];
    }
    else if(PS_MENU_REMOTE_CONNECT == item.sqType)
    {
        [self performSegueWithIdentifier:@"home2help" sender:nil];
    }
    else if(PS_MENU_CHECK_UPDATE == item.sqType)
    {
        //更新检查
        [self versoinCheck];
    }
    else if(PS_MENU_REVIEW == item.sqType)
    {
        //给我评分
        NSString* reviewUrl = @"itms-apps://itunes.apple.com/app/id1257770958";
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewUrl]];
        
        NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
        [userDefault setObject:@(time(NULL) + SQ_MAX_COMMENT_TIME) forKey:SQ_LAST_COMMENT_TIME];
    }
    else if(PS_MENU_OPEN_PHOTOS == item.sqType)
    {
        //打开相册
        [self openPhotos];
    }
    else if(PS_MENU_HELP == item.sqType)
    {
        //使用帮助
        [self performSegueWithIdentifier:@"main2help" sender:nil];
    }
    else if(PS_MENU_REFRESH == item.sqType)
    {
        //刷新文件列表
        [self refreshImageList];
    }
    
    [self.psViewFunction setHidden:YES];
}

/**
 后台进行版本检查
 */
-(void)versionCheckOnBack
{
    self.psRequest = [ASIHTTPRequest requestWithURL:@"http://itunes.apple.com/cn/lookup?id=1257770958" onTarget:self andFinishSelector:@selector(resultVersionCheckOnBack:) andFailSelector:@selector(errorVersionCheckOnBack:)];
    [self.psRequest startAsynchronous];
}

-(void)resultVersionCheckOnBack:(ASIHTTPRequest*)request
{
    const int STATU_CODE = [request responseStatusCode];
    NSDictionary* jsonData = nil;
    NSLog(@"%s-%d http statu:%d", __FUNCTION__, __LINE__, STATU_CODE);
    
    if (200 != STATU_CODE && 206 != STATU_CODE)
    {
        return;
    }
    
    jsonData = [[request responseData] objectFromJSONDataNullCase];
    NSLog(@"%s-%d json:%@", __func__, __LINE__, jsonData);
    if (nil == jsonData)
    {
        return;
    }
    
    NSArray *infoArray = [jsonData objectForKey:@"results"];
    if (0 == infoArray.count) {
        return;
    }
    NSDictionary *releaseInfo = [infoArray objectAtIndex:0];
    self.psServerVersion = [releaseInfo objectForKey:@"version"];
    NSUserDefaults* userDefault = [NSUserDefaults standardUserDefaults];
    NSString* ignoreVersion = [userDefault objectForKey:SQ_IGNORE_VERSION];
    NSLog(@"%s-%d serverVersion:%@, ignoreVersion:%@, appVersion:%@", __func__, __LINE__, self.psServerVersion, ignoreVersion, [SQManager sharedSQManager].sqAppVersion);
    
    if ((FALSE == [self.psServerVersion isEqualToString:ignoreVersion]) && ([self.psServerVersion compare:[SQManager sharedSQManager].sqAppVersion] == NSOrderedDescending))
    {
        //有新的版本并且该版本没有被忽略,提示用户更新
        UIAlertView* alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PSD.See", @"PSD.See") message:NSLocalizedString(@"need_update", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"update_now", @"") otherButtonTitles:NSLocalizedString(@"next_time", @""), nil, nil] autorelease];
        alertView.tag = ALERT_VERSION_UPDATE;
        [alertView show];
    }

}

-(void)errorVersionCheckOnBack:(ASIHTTPRequest*)request
{
    NSLog(@"%s-%d error:%@", __func__, __LINE__, request.error);
}

-(void)versoinCheck
{
    MBProgressHUD* viewProgress = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    viewProgress.labelText = NSLocalizedString(@"loading", @"loading");
    viewProgress.dimBackground = YES;
    
    //1118295778
    self.psRequest = [ASIHTTPRequest requestWithURL:@"http://itunes.apple.com/cn/lookup?id=1257770958" onTarget:self andFinishSelector:@selector(versionOnRequest:) andFailSelector:@selector(httpErrorOnRequest:)];
    [self.psRequest startAsynchronous];
}

/**
 * 解析是否有新版本
 * @param json
 * @throws KernelException
 * @throws JSONException
 */
-(BOOL) parseHasNewVersion:(ASIHTTPRequest*)request
{
    BOOL result = NO;
    @autoreleasepool
    {
        const int STATU_CODE = [request responseStatusCode];
        NSDictionary* jsonData = nil;
        NSLog(@"%s-%d http statu:%d", __FUNCTION__, __LINE__, STATU_CODE);
        
        if (200 != STATU_CODE && 206 != STATU_CODE)
        {
            @throw [NSException exceptionWithName:@"1000" reason:NSLocalizedString(@"server_error", @"server_error") userInfo:nil];
        }
        
        jsonData = [[request responseData] objectFromJSONDataNullCase];
        NSLog(@"%s-%d json:%@", __func__, __LINE__, jsonData);
        if (nil == jsonData)
        {
            @throw [NSException exceptionWithName:@"1001" reason:NSLocalizedString(@"server_error", @"server_error") userInfo:nil];
        }
        
        NSArray *infoArray = [jsonData objectForKey:@"results"];
        if (0 == infoArray.count) {
            @throw [NSException exceptionWithName:@"1001" reason:NSLocalizedString(@"server_error", @"server_error") userInfo:nil];
        }
        NSDictionary *releaseInfo = [infoArray objectAtIndex:0];
        self.psServerVersion = [releaseInfo objectForKey:@"version"];
        
        if ([self.psServerVersion compare:[SQManager sharedSQManager].sqAppVersion] == NSOrderedDescending)
        {
            //有新的版本
            result = YES;
        }
        else
        {
            result = NO;
        }
    }
    
    return result;
}

-(void)versionOnRequest:(ASIHTTPRequest*)request
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    @try
    {
        BOOL needUpdate = [self parseHasNewVersion:request];
        if (needUpdate)
        {
            //有新的版本可以更新
            UIAlertView* alertView = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PSD.See", @"PSD.See") message:NSLocalizedString(@"need_update", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"update_now", @"") otherButtonTitles:NSLocalizedString(@"next_time", @""), nil, nil] autorelease];
            alertView.tag = ALERT_VERSION_UPDATE;
            [alertView show];
        }
        else
        {
            //没有可以更新的版本
            [MBProgressHUD Toast:NSLocalizedString(@"no_need_update", @"no_need_update") toView:self.view andTime:1];
        }
    }
    @catch (NSException *exception)
    {
        [MBProgressHUD Toast:NSLocalizedString(@"server_error", @"server_error") toView:self.view andTime:1];
    }
    
}

-(void)httpErrorOnRequest:(ASIHTTPRequest*) request
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [MBProgressHUD Toast:NSLocalizedString(@"http_error", @"http_error") toView:self.view andTime:1];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* viewCell = nil;
    if (tableView == self.psTableView)
    {
        viewCell = [self setImageTableViewAtIndex:indexPath];
    }
    else if(tableView == self.psTableViewFunction)
    {
        viewCell = [self setMenuTableViewAtIndex:indexPath];
    }
    
    viewCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return viewCell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.psTableViewFunction)
    {
        return [self.psListMenu count];
    }
    return [self.psListFiles count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.psTableView)
    {
        [self selectImageRow:indexPath];
    }
    else if(tableView == self.psTableViewFunction)
    {
        [self selectMenuRow:indexPath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.psTableView)
    {
        id tbItem = self.psListFiles[indexPath.row];
        
        if([tbItem isKindOfClass:[FileItem class]])
        {
            return 100;
        }
        
        return 50;
    }
    return 44;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.psTableView)
    {
        return YES;
    }
    return NO;
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.psTableViewFunction)
    {
        return UITableViewCellEditingStyleNone;
    }
    
    id tbItem = self.psListFiles[indexPath.row];
    
    if([tbItem isKindOfClass:[FileItem class]])
    {
        FileItem* fileItem = tbItem;
        if (FALSE == [fileItem.psFilePath containsString:@"/Bundle/Application/"])
        {
            return UITableViewCellEditingStyleDelete;
        }
    }
    return UITableViewCellEditingStyleNone;
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NSLocalizedString(@"deleting", @"deleting");
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.psTableViewFunction)
    {
        return;
    }
    
    id tbItem = self.psListFiles[indexPath.row];
    
    if([tbItem isKindOfClass:[FileItem class]])
    {
        FileItem* fileItem = tbItem;
        if (UITableViewCellEditingStyleDelete == editingStyle)
        {
            //删除文件
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtPath:fileItem.psFilePath error:nil];
            if (fileItem.psPsdImage.length > 0)
            {
                [fileManager removeItemAtPath:fileItem.psPsdImage error:nil];
            }
            
            //删除该文件对应的图层文件
            [self deleteLayerImagesWithId:fileItem.psIndex];
            
            [fileItem removeFromDatabase]; //从数据库中删除
            [self.psListFiles removeObject:fileItem];
            [self.psTableView reloadData];
        }
    }
}

/**
 删除相关的图层文件
 */
-(void)deleteLayerImagesWithId:(int) layerId
{
    NSString* fileCode = [NSString stringWithFormat:@"%@%d", SQ_LAYERIAMGE_PREIX, layerId];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString* imgCache = [SQManager sharedSQManager].sqPsdImagePath;
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:imgCache];
    NSString* fileName;
    NSString* fullPath;
    
    while (fileName = [dirEnum nextObject])
    {
        if ([fileName hasPrefix:fileCode]) {
            fullPath = [imgCache stringByAppendingPathComponent:fileName];
            [fileManager removeItemAtPath:fullPath error:nil];
        }
    }
}

/*
 用户选择了相册中的某张照片
 */
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    NSData* imageData = UIImageJPEGRepresentation(image, 1);
    if(nil == imageData)
    {
        return;
    }
    
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"yyyyMMdd_HHmmss"];
    //用[NSDate date]可以获取系统当前时间
    NSString *currentDateStr = [dateFormatter stringFromDate:[NSDate date]];
    
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docPath = [path objectAtIndex:0];
    
    NSString* fileName = [NSString stringWithFormat:@"%@.jpg", currentDateStr];
    NSString* jpegPath = [docPath stringByAppendingPathComponent:fileName];
    
    [imageData writeToFile:jpegPath atomically:YES];
    
    [self onFileScanSuccessWithPath:jpegPath];
}

/*
 用户取消选择照片
 */
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint currentPoint = [gestureRecognizer locationInView:self.psViewFunction];
    NSLog(@"%s-%d: x:%f, width:%f", __func__, __LINE__, currentPoint.x, self.psTableViewFunction.frame.size.width);
    if (currentPoint.x > self.psTableViewFunction.frame.size.width)
    {
        return TRUE; //tableview外点击则隐藏
    }
    
    return FALSE;
}

-(void)openExternalFile:(NSString*)filePath
{
    FileItem* fileItem = [FileItem getFileItemByPath:filePath];
    if(fileItem)
    {
        [self.psListFiles insertObject:fileItem atIndex:2];
        [self.psTableView reloadData];
        
        [self performSegueWithIdentifier:@"main2view" sender:fileItem];
    }
}

-(void)addFilePathInList:(NSString*)filePath
{
    FileItem* fileItem = [FileItem getFileItemByPath:filePath];
    if(fileItem)
    {
        [self.psListFiles insertObject:fileItem atIndex:2];
    }
}

-(void)handleSingleTap:(UITapGestureRecognizer *)sender
{
    self.psViewFunction.hidden = YES;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.destinationViewController isKindOfClass:[ViewCtrlDrawing class]])
    {
        ViewCtrlDrawing* viewCtrl = segue.destinationViewController;
        viewCtrl.psFileItem = sender;
    }
    else if([segue.destinationViewController isKindOfClass:[ViewCtrlFileServer class]])
    {
        ViewCtrlFileServer* viewCtrl = segue.destinationViewController;
        viewCtrl.psFileInfo = sender;
    }
    else if([segue.destinationViewController isKindOfClass:[ViewCtrlScan class]])
    {
        ViewCtrlScan* viewCtrl = segue.destinationViewController;
        viewCtrl.psDelegate = self;
    }
}

- (IBAction)onClickMenu:(id)sender
{
    BOOL isHiden = !self.psViewFunction.hidden;
    self.psViewFunction.hidden = isHiden;
}

- (void)onClickDeleteButton
{
    BOOL editing = !([self.psTableView isEditing]);
    [self.psTableView setEditing:editing animated:YES];
}

- (IBAction)onClickFileServer:(id)sender
{
    NSInteger itemIndex = [SQManager getViewIndex:sender inTableView:self.psTableView];
    if(itemIndex < 0)
    {
        return;
    }
    
    FileItem* item = [self.psListFiles objectAtIndex:itemIndex];
    [self performSegueWithIdentifier:@"main2fileserver" sender:item];
}

- (void)refreshImageList
{
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docPath = [path objectAtIndex:0];
    NSLog(@"docPath:%@", docPath);
    
    //添加外部目录进来的文件
    FileItem* fileItem = nil;
    NSString* fileName;
    NSString* fullPath = nil;;
    BOOL isDir;
    NSString* inBoxDir = [docPath stringByAppendingPathComponent:@"Inbox"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:inBoxDir];
    
    /**
     NSError* error = nil;
     NSArray* docFileList = [fileManager contentsOfDirectoryAtPath:docPath error:&error];
     NSArray* inboxFileList = [fileManager contentsOfDirectoryAtPath:inBoxDir error:&error];
     **/
    
    while (fileName = [dirEnum nextObject])
    {
        fullPath = [inBoxDir stringByAppendingPathComponent:fileName];
        [fileManager fileExistsAtPath:fullPath isDirectory:&isDir];
        if(isDir)
        {
            [dirEnum skipDescendants]; //禁止深度遍历
        }
        else if (NO == [self isFilePathHasInList:fullPath])
        {
            fileItem = [FileItem getFileItemByPath:fullPath];
            if (fileItem)
            {
                [self.psListFiles insertObject:fileItem atIndex:2];
            }
        }
    }
    
    //添加doc目录下文件
    dirEnum = [fileManager enumeratorAtPath:docPath];
    while (fileName = [dirEnum nextObject])
    {
        fullPath = [docPath stringByAppendingPathComponent:fileName];
        [fileManager fileExistsAtPath:fullPath isDirectory:&isDir];
        if (isDir)
        {
            [dirEnum skipDescendants]; //禁止深度遍历
        }
        else if (NO == [self isFilePathHasInList:fullPath])
        {
            fileItem = [FileItem getFileItemByPath:fullPath];
            if (fileItem)
            {
                [self.psListFiles insertObject:fileItem atIndex:2];
            }
        }
    }
    
    [MBProgressHUD Toast:NSLocalizedString(@"refresh_finish", @"refresh_finish") toView:self.view andTime:1];
    
    [self.psTableView reloadData];
}

@end

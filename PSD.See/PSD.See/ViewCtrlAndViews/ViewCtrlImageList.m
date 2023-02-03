//
//  ViewController.m
//  PSD.See
//
//  Created by Larry on 16/9/5.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "ViewCtrlImageList.h"
#import "psdata.h"
#import "SQManager.h"
#import "datamodel.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "../common/UIView+SQLayerAndKeyValue.h"
#import "../Datas/SQListItem.h"
#import "../common/ASIHTTPRequest/External/Reachability/Reachability.h"
#import "ViewCtrlAddServer.h"
#import "ViewCtrlPSDrawing.h"
#import "mbprogresshud+toast.h"
#import "SQUserDataView.h"
#import "SQConstant.h"

#define KEY_FILE_ITEM (@"key_file_item")

enum
{
    PS_IMG_LIST_ALBUM //相册
    , PS_IMG_LIST_IMAGE //图片
    , PS_IMG_LAST //最后一个节点
};

@interface ViewCtrlImageList ()<UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (retain, nonatomic) IBOutlet UITableView *psTableView;
@property (retain, nonatomic) IBOutlet UILabel *psTitle;
@property (retain, nonatomic) IBOutlet UIView *psViewTitle;

@property (nonatomic, retain) NSMutableArray* psListFiles;
@property (retain, nonatomic) NSMutableArray* psLayoutConstraints; //布局属性列表

- (IBAction)onClickBack:(id)sender;

@end

@implementation ViewCtrlImageList

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.psListFiles = [NSMutableArray array];
    self.psTitle.text = NSLocalizedString(@"file_list", @"");
    
    //[SQManager setExtraCellLineHidden:self.psTableView];
    
#if SHOW_ADS
    // Replace this ad unit ID with your own ad unit ID.
    //self.psBannerView.adUnitID = @"ca-app-pub-3940256099942544/2934735716"; //测试id
    self.psBannerView.adUnitID = @"ca-app-pub-2925148926153054/6441483925";
    self.psBannerView.rootViewController = self;
    self.psBannerView.delegate = self;
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
    
    [self addFileList];
    self.psLayoutConstraints = [NSMutableArray array];
}

/**
 设置iphone x布局
 */
-(void)setDeviceLayout{
    UIView* titleView = self.psViewTitle;
    NSDictionary *views = @{@"titleView":titleView};
    NSArray* constraints = nil;
    //先删除上次的布局,为新的布局做准备
    [self.view removeConstraints:self.psLayoutConstraints];
    [self.psLayoutConstraints removeAllObjects];
    
    if (UIDeviceOrientationPortrait == self.interfaceOrientation || UIDeviceOrientationPortraitUpsideDown == self.interfaceOrientation) {
        //竖屏
        if ([SQManager isIphoneX]) { //浏海屏
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[titleView(84)]" options:0 metrics:nil views:views];
        } else { //非浏海屏
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[titleView(64)]" options:0 metrics:nil views:views];
        }
    } else {
        //横屏
        if ([SQManager isIphoneX]) { //浏海屏
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[titleView(54)]" options:0 metrics:nil views:views];
        } else { //非浏海屏
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[titleView(44)]" options:0 metrics:nil views:views];
        }
    }
    [self.psLayoutConstraints addObjectsFromArray:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[titleView]-0-|" options:0 metrics:nil views:views];
    [self.psLayoutConstraints addObjectsFromArray:constraints];
    
    [self.view addConstraints:self.psLayoutConstraints];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self setDeviceLayout];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setDeviceLayout]; //设置刘海屏布局
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
#if 0
    GADInterstitial* ads = [SQManager sharedSQManager].sqInterstitial;
    if (FALSE == ads.hasBeenUsed && ads.isReady)
    {
        //插页广告还没显示,显示插页广告
        [self performSegueWithIdentifier:@"sync2ads" sender:nil];
    }
#endif
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

-(void)addFileList
{
    NSMutableArray* list = [NSMutableArray array];
    int index = 0;
    [FileItem putFileInList:list];
    SQListItem* listItem = nil;
    
    [self.psListFiles addObject:[SQListItem listItemWithType:PS_IMG_LIST_ALBUM]];
    
    for (FileItem* fileItem in list)
    {
        if (index % 3 == 0)
        {
            listItem = [SQListItem listItemWithType:PS_IMG_LIST_IMAGE];
            listItem.sqContent = [NSMutableArray array];
            
            [self.psListFiles addObject:listItem];
        }
        [listItem.sqContent addObject:fileItem];
        index++;
    }
    
    [self.psListFiles addObject:[SQListItem listItemWithType:PS_IMG_LAST]];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [_psListFiles release];
    [_psTableView release];
    [_psTitle release];
    [_psLayoutConstraints release];
    [_psViewTitle release];
    [super dealloc];
}

- (void)setImageCell:(UITableViewCell*)cell dataList:(NSArray*)list
{
    SQUserDataView* view = [cell.contentView viewWithTag:100];
    [view setHidden:YES];
    [SQManager addBorderToView:view width:0.5 color:[UIColor grayColor] cornerRadius:0];
    
    view = [cell.contentView viewWithTag:101];
    [view setHidden:YES];
    [SQManager addBorderToView:view width:0.5 color:[UIColor grayColor] cornerRadius:0];
    
    view = [cell.contentView viewWithTag:102];
    [view setHidden:YES];
    [SQManager addBorderToView:view width:0.5 color:[UIColor grayColor] cornerRadius:0];
    
    FileItem* fileItem = nil;
    UIImage* fileImage = nil;
    UILabel* labelName = nil;
    NSString* relativePath;
    NSString* smallImagePath;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    UIImage* bigImage = nil;
    CGSize smallImgSize;
    NSData* psdImageData = nil;
    
    for (int index = 0; index < [list count]; index++) {
        fileItem = [list objectAtIndex:index];
        view = [cell.contentView viewWithTag:100 + index];
        [view setHidden:NO];
        [view setUserData:fileItem forKey:KEY_FILE_ITEM];
        
        UIImageView* imageView = (UIImageView*)[view viewWithTag:200];
        
        UITapGestureRecognizer* singleTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClickImage:)] autorelease];
        [view addGestureRecognizer:singleTap];
        
        relativePath = [FileItem getRelativePathInDoc:fileItem.psFilePath];
        smallImagePath = [SQManager sharedSQManager].sqPsdImagePath;
        smallImagePath = [smallImagePath stringByAppendingPathComponent:[SQManager getStringCRC32:relativePath]];
        smallImagePath = [smallImagePath stringByAppendingString:@"_small"];
        
        if ([fileManager fileExistsAtPath:smallImagePath]) {
            //小图已存在
            fileImage = [UIImage imageWithContentsOfFile:smallImagePath];
        } else {
            //小图不存在, 生成小图
            if (fileItem.psPsdImage.length > 0)
            {
                bigImage = [UIImage imageWithContentsOfFile:fileItem.psPsdImage];
            }
            else
            {
                bigImage = [UIImage imageWithContentsOfFile:fileItem.psFilePath];
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

        [imageView setImage:fileImage];

        labelName = [view viewWithTag:201];
        labelName.text = [fileItem.psFilePath lastPathComponent];
    }
}

-(void)onClickImage:(UITapGestureRecognizer *)sender
{
    SQUserDataView* view = (SQUserDataView*)sender.view;
    FileItem* fileInfo = [view userDataForKey:KEY_FILE_ITEM];
    UIImage* fileImage = nil;
    
    if (fileInfo.psPsdImage.length > 0)
    {
        fileImage = [UIImage imageWithContentsOfFile:fileInfo.psPsdImage];
    }
    else
    {
        fileImage = [UIImage imageWithContentsOfFile:fileInfo.psFilePath];
    }

    [self.psImageSelectedDelegate imageSelected:fileImage];
    [self.navigationController popViewControllerAnimated:YES];
}

/*
 用户选择了相册中的某张照片
 */
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        [self.psImageSelectedDelegate imageSelected:image];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

/*
 用户取消选择照片
 */
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cellItem = nil;
    SQListItem* dataItem = [self.psListFiles objectAtIndex:indexPath.row];
    
    if (PS_IMG_LIST_ALBUM == dataItem.sqType)
    {
        cellItem = [tableView dequeueReusableCellWithIdentifier:@"CELL_ALBUM"];
        UILabel* label = cellItem.textLabel;
        label.text = NSLocalizedString(@"open_photos", @"open_photos");
    }
    else if(PS_IMG_LIST_IMAGE == dataItem.sqType)
    {
        cellItem = [tableView dequeueReusableCellWithIdentifier:@"CELL_IMAGE"];
        [self setImageCell:cellItem dataList:dataItem.sqContent];
    }
    else
    {
        cellItem = [tableView dequeueReusableCellWithIdentifier:@"CELL_LAST"];
        //[cellItem.contentView setTopLayerAtX:0 color:[UIColor lightGrayColor] width:4096 height:0.5];
    }
    
    if (1 == indexPath.row)
    {
        [cellItem.contentView setTopLayerAtX:0 color:[UIColor lightGrayColor] width:4096 height:0.5];
    }
    
    cellItem.selectionStyle = UITableViewCellSelectionStyleNone;
    return cellItem;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.psListFiles count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SQListItem* tabItem = [self.psListFiles objectAtIndex:indexPath.row];
    
    if (PS_IMG_LIST_ALBUM == tabItem.sqType)
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
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    float height = 60;
    
    id dataItem = [self.psListFiles objectAtIndex:indexPath.row];
    if ([dataItem isKindOfClass:[SQListItem class]])
    {
        SQListItem* listItem = dataItem;
        if (PS_IMG_LIST_ALBUM == listItem.sqType)
        {
            height = 44;
        }
        else if(PS_IMG_LAST == listItem.sqType)
        {
            height = 51;
        }
        else
        {
            height = 120;
        }
    }
    
    return height;
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


- (IBAction)onClickBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end

//
//  ViewCtrlDrawing.m
//  PSD.See
//
//  Created by Larry on 16/9/29.
//  Copyright © 2016年 MaiMiao. All rights reserved.
//

#import "ViewCtrlDrawing.h"
#import "DrawImageView.h"
#import "SQConstant.h"
#import "EVCircularProgressView.h"
#import "SQManager.h"
#import "MBProgressHUD+Toast.h"
#import "DataModel.h"
#import "SQListItem.h"
#import "PSData.h"

enum {
    PS_LAYER_PARENT = 1000 //图层分组
};

@interface ViewCtrlDrawing ()<UITableViewDelegate, UITableViewDataSource>

@property (retain, nonatomic) IBOutlet DrawImageView *psDrawView;
@property (retain, nonatomic) IBOutlet UIView *psLayoutTitle;
@property (retain, nonatomic) IBOutlet UILabel *psLabelTitle;
@property (retain, nonatomic) IBOutlet UIView *psViewBottom;
@property (nonatomic, retain) NSMutableArray* psListLayer;
@property (retain, nonatomic) IBOutlet UIButton *psBtnShowLayers;
@property (retain, nonatomic) IBOutlet EVCircularProgressView *psProgressView;
@property (retain, nonatomic) IBOutlet UITableView *psTableView;

@property (retain, nonatomic) PSHeader* psHeader; //ps文件的头部信息
@property (nonatomic, assign) BOOL psIsLoadingLayer; //是否正在加载图层
@property (nonatomic, assign) BOOL psTitleHidden;
@property (nonatomic, retain) NSMutableArray* psListTableItem; //tableview 的item
@property (retain, nonatomic) NSMutableArray* psLayoutConstraints; //布局属性列表

- (IBAction)onClickBack:(id)sender;
- (IBAction)onClickFullScreen:(id)sender;
- (IBAction)onClickRestoreView:(id)sender;
- (IBAction)onClickRotate:(id)sender;
- (IBAction)onClickShowLayers:(id)sender;

@end

@implementation ViewCtrlDrawing

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.psTitleHidden = YES;
    self.psLabelTitle.text = [self.psFileItem.psFilePath lastPathComponent];
    self.psLayoutTitle.hidden = self.psTitleHidden;
    self.psViewBottom.hidden = self.psTitleHidden;
    self.psTableView.hidden = YES;
    self.psListTableItem = [NSMutableArray array];
    self.psHeader = [[[PSHeader alloc] init] autorelease];
    
    [self.psDrawView initWithFileItem:self.psFileItem];
    [SQManager setExtraCellLineHidden:self.psTableView];
    
    if (self.psFileItem.psIndex >= 0)
    {
        [self.psFileItem save];
    }
    
    UITapGestureRecognizer* singleTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)] autorelease];
    [self.psDrawView addGestureRecognizer:singleTap];
    
    [self.psProgressView setProgressColor:[UIColor colorWithRed:0x11/255.f green:0x8c/255.f blue:0xe3/255.f alpha:1] andBoxColor:[UIColor blueColor]];
    [self.psProgressView setHidden:YES];
    
    if ([self.psFileItem.psExtInfo containsString:@"RGB"]) {
        //RGB 模式的PSD文件
        [self.psBtnShowLayers setEnabled:YES];
    } else {
        //其他模式不能处理图层显示
        [self.psBtnShowLayers setEnabled:NO];
    }
    
    self.psLayoutConstraints = [NSMutableArray array];
    //[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setDeviceLayout];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 设置iphone x布局
 */
-(void)setDeviceLayout{
    UIView* titleView = self.psLayoutTitle;
    UIView* drawView = self.psDrawView;
    UIView* bottomView = self.psViewBottom;
    UIView* tableView = self.psTableView;
    
    NSDictionary *views = @{@"titleView":titleView, @"drawView":drawView, @"bottomView":bottomView, @"tableView":tableView};
    NSArray* constraints = nil;
    //先删除上次的布局,为新的布局做准备
    [self.view removeConstraints:self.psLayoutConstraints];
    [self.psLayoutConstraints removeAllObjects];
    
    if (UIDeviceOrientationPortrait == self.interfaceOrientation || UIDeviceOrientationPortraitUpsideDown == self.interfaceOrientation) {
        //竖屏
        if ([SQManager isIphoneX]) { //浏海屏
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[titleView(84)]-0-[tableView]-0-[bottomView]-15-|" options:0 metrics:nil views:views];
        } else { //非浏海屏
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[titleView(64)]-0-[tableView]-0-[bottomView]-0-|" options:0 metrics:nil views:views];
        }
    } else {
        //横屏
        if ([SQManager isIphoneX]) { //浏海屏
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[titleView(54)]-0-[tableView]-0-[bottomView]-15-|" options:0 metrics:nil views:views];
        } else { //非浏海屏
            constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[titleView(44)]-0-[tableView]-0-[bottomView]-0-|" options:0 metrics:nil views:views];
        }
    }
    [self.psLayoutConstraints addObjectsFromArray:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[titleView]-0-|" options:0 metrics:nil views:views];
    [self.psLayoutConstraints addObjectsFromArray:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[drawView]-0-|" options:0 metrics:nil views:views];
    [self.psLayoutConstraints addObjectsFromArray:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[drawView]-0-|" options:0 metrics:nil views:views];
    [self.psLayoutConstraints addObjectsFromArray:constraints];
    
    [self.view addConstraints:self.psLayoutConstraints];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self prefersStatusBarHidden];
    [self setNeedsStatusBarAppearanceUpdate];
    //[[UIApplication sharedApplication] setStatusBarHidden:self.psTitleHidden withAnimation:UIStatusBarAnimationSlide];
}

- (BOOL)prefersStatusBarHidden
{
    //NSLog(@"++++++++++++++++++++ %d", self.psTitleHidden);
    return self.psTitleHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(void)dealloc
{
    [_psFileItem release];
    [_psDrawView release];
    [_psLayoutTitle release];
    [_psLabelTitle release];
    [_psListLayer release];
    [_psViewBottom release];
    [_psBtnShowLayers release];
    [_psProgressView release];
    [_psListTableItem release];
    [_psTableView release];
    [_psHeader release];
    [_psLayoutConstraints release];
    
    [super dealloc];
}

-(void)handleSingleTap:(UITapGestureRecognizer *)sender
{
    self.psTitleHidden = !(self.psTitleHidden);
    
    [self.psLayoutTitle setHidden:self.psTitleHidden];
    [self.psViewBottom setHidden:self.psTitleHidden];
    if (self.psTitleHidden) {
        [self.psTableView setHidden:self.psTitleHidden];
    }
    [self prefersStatusBarHidden];
    [self setNeedsStatusBarAppearanceUpdate];
    //[[UIApplication sharedApplication] setStatusBarHidden:self.psTitleHidden withAnimation:UIStatusBarAnimationSlide];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self setDeviceLayout];
    [self.psDrawView setNeedsDisplay];
}

/**
 在后台线程中加载layer数据
 */
-(void)loadLayerDataOnBackThead:(NSArray*)arrayParam
{
    @autoreleasepool {
        
    NSLog(@"%s - %d filePath:%@, fileCode:%@", __func__, __LINE__, arrayParam[0], arrayParam[2]);
    NSError* error = nil;
    NSData* fileData = [NSData dataWithContentsOfFile:arrayParam[0] options:NSDataReadingMappedIfSafe error:&error];
    if (error) {
        NSLog(@"%s-%d error:%@", __func__, __LINE__, error);
        //通知主线程打开文件失败
        [self performSelectorOnMainThread:@selector(onLoadLayerResult:) withObject:@(PS_ERR_OPEN_FILE) waitUntilDone:NO];
    } else {
        int errCode = [PSLayer readLayersInList:arrayParam[1] withData:fileData withFileCode:arrayParam[2] outHeader:self.psHeader];
        NSLog(@"%s-%d errCode:%d, fileCode:%@", __func__, __LINE__, errCode, arrayParam[2]);
        //通知主线程图层处理结束
        [self performSelectorOnMainThread:@selector(onLoadLayerResult:) withObject:@(errCode) waitUntilDone:NO];
    }
        
    }
}

-(NSString*)getErrorInfoWithCode:(int)errorCode
{
    NSString* errKey = @"";
    if (errorCode) {
        errKey = [NSString stringWithFormat:@"error_%d", errorCode];
    }
    
    if (errKey.length > 0) {
        return NSLocalizedString(errKey, errKey);
    }
    return @"";
}

/**
 图层加载完成
 */
-(void)onLoadLayerResult:(NSNumber*)errorCode
{
    self.psIsLoadingLayer = NO;
    [self.psProgressView setHidden:YES];
    [self.psTableView setHidden:NO];
    if (0 != errorCode.intValue) {
        [MBProgressHUD Toast:[self getErrorInfoWithCode:errorCode.intValue] toView:self.view andTime:1];
        return;
    }
    
    [self.psListTableItem addObjectsFromArray:self.psListLayer];
    [self.psTableView reloadData];
}

/**
 返回上层目录
 */
-(void)returnParentFolder:(PSLayer*)layer
{
    [self.psListTableItem removeAllObjects];
    if (layer.psParentLayer) {
        PSLayer* parentLayer = layer.psParentLayer;
        SQListItem* item = [SQListItem listItem];
        item.sqType = PS_LAYER_PARENT;
        item.sqContent = layer.psParentLayer;
        
        [self.psListTableItem addObject:item];
        [self.psListTableItem addObjectsFromArray:parentLayer.psSubLayers];
    } else {
        //顶层目录
        [self.psListTableItem addObjectsFromArray:self.psListLayer];
    }
    
    [self.psTableView reloadData];
}

/**
 打开子图层列表
 */
-(void)openSubLayers:(PSLayer*)layer
{
    [self.psListTableItem removeAllObjects];
    SQListItem* item = [SQListItem listItem];
    item.sqType = PS_LAYER_PARENT;
    item.sqContent = layer;
    [self.psListTableItem addObject:item];
    
    [self.psListTableItem addObjectsFromArray:layer.psSubLayers];
    [self.psTableView reloadData];
}

/**
 设置layer的可见性
 */
-(void)setLayerVisible:(PSLayer*)layer withViewCell:(UITableViewCell*)viewCell
{
    layer.psVisible = !(layer.psVisible);
    UIButton* btnVisible = [viewCell viewWithTag:102];
    if (layer.psVisible) {
        //图层可见
        [btnVisible setImage:[UIImage imageNamed:@"visible.png"] forState:UIControlStateNormal];
        [btnVisible setImage:[UIImage imageNamed:@"invisible.png"] forState:UIControlStateHighlighted];
    } else {
        //图层不可见
        [btnVisible setImage:[UIImage imageNamed:@"visible.png"] forState:UIControlStateHighlighted];
        [btnVisible setImage:[UIImage imageNamed:@"invisible.png"] forState:UIControlStateNormal];
    }
    
    //如果上级分组不可见，则不处理
    BOOL needBuidImage = TRUE;
    PSLayer* parentLayer = layer.psParentLayer;
    while (parentLayer) {
        if (NO == parentLayer.psVisible) {
            needBuidImage = NO;
            break;
        }
        parentLayer = parentLayer.psParentLayer;
    }
    if (needBuidImage) {
        [self buildLayerImages]; //重新生成图层的图片
    }
}


-(void)buildLayerImages
{
    NSLog(@"%s - %d psd_w:%d, psd_h:%d", __func__, __LINE__, self.psHeader.psWidth, self.psHeader.psHeight);
    UIImage *resultImage = nil;
    
    NSMutableArray* tempLayers = [NSMutableArray arrayWithArray:self.psListLayer];
    UIGraphicsBeginImageContext(CGSizeMake(self.psHeader.psWidth, self.psHeader.psHeight));
    
    while (tempLayers.count > 0) {
        @autoreleasepool {
        PSLayer* layer = tempLayers[tempLayers.count -1];
        [tempLayers removeLastObject];
        if (FALSE == layer.psVisible) {
            ///图层不可见,不处理
        } else if (PS_LAYER_FOLDER == layer.psLayerType) {
            //目录图层,将子图层加入到队列中
            if (layer.psSubLayers.count > 0) {
                [tempLayers addObjectsFromArray:layer.psSubLayers];
            }
        } else if (layer.psWidth * layer.psHeight > 0) {
            //普通图层,并且有图片数据;开始绘制图片
            NSString* fileCode = [NSString stringWithFormat:@"layerimg_%d", self.psFileItem.psIndex];
            NSString* saveImagePath = [SQManager sharedSQManager].sqPsdImagePath;
            NSString* layerFileName = [NSString stringWithFormat:@"%@_%d", fileCode, layer.psLayerId];
            NSString* layerImagePath = [saveImagePath stringByAppendingPathComponent:layerFileName];
            
            UIImage* image = [UIImage imageWithContentsOfFile:layerImagePath];
            [image drawInRect:CGRectMake(layer.psLeft, layer.psTop, layer.psWidth, layer.psHeight)];
        } else {
            //图层没有图片信息
        }
        }
    }
    resultImage = UIGraphicsGetImageFromCurrentImageContext();
    //释放上下文
    UIGraphicsEndImageContext();
    
    [self.psDrawView updateImage:resultImage];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* viewCell = nil;
    id item = [self.psListTableItem objectAtIndex:indexPath.row];
    if ([item isKindOfClass:[SQListItem class]]) {
        SQListItem* listItem = item;
        if (PS_LAYER_PARENT == listItem.sqType) {
            viewCell = [self.psTableView dequeueReusableCellWithIdentifier:@"CELL_PARENT"];
            UILabel* label = [viewCell viewWithTag:101];
            if (listItem.sqContent) {
                PSLayer* parent = listItem.sqContent;
                [label setText:parent.psName];
            } else {
                [label setText:@""];
            }
        }
    } else if ([item isKindOfClass:[PSLayer class]]) {
        PSLayer* layer = item;
        viewCell = [self.psTableView dequeueReusableCellWithIdentifier:@"CELL_LAYER"];
        UIImageView* imageType = [viewCell viewWithTag:100];
        UIButton* btnVisible = [viewCell viewWithTag:102];
        UILabel* labelName = [viewCell viewWithTag:101];
        UIImageView* arrowImage = [viewCell viewWithTag:103];
        
#if 0
        UITapGestureRecognizer* singleTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectLayer:)] autorelease];
        [imageType addGestureRecognizer:singleTap];
#endif
        
        [btnVisible addTarget:self action:@selector(onClickLayerVisible:) forControlEvents:UIControlEventTouchUpInside];
        
        if (PS_LAYER_FOLDER == layer.psLayerType) {
            //图层是一个目录
            imageType.image = [UIImage imageNamed:@"group.png"];
            //viewCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            arrowImage.hidden = NO;
        } else {
            //普通图层
            imageType.image = [UIImage imageNamed:@"layer.png"];
            arrowImage.hidden = YES;
            //viewCell.accessoryType = UITableViewCellAccessoryNone;
        }
        labelName.text = layer.psName;
        if (layer.psVisible) {
            //图层可见
            [btnVisible setImage:[UIImage imageNamed:@"visible.png"] forState:UIControlStateNormal];
            [btnVisible setImage:[UIImage imageNamed:@"invisible.png"] forState:UIControlStateHighlighted];
        } else {
            //图层不可见
            [btnVisible setImage:[UIImage imageNamed:@"visible.png"] forState:UIControlStateHighlighted];
            [btnVisible setImage:[UIImage imageNamed:@"invisible.png"] forState:UIControlStateNormal];
        }
    }
    
    viewCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return viewCell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.psListTableItem count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = [self.psListTableItem objectAtIndex:indexPath.row];
    if ([item isKindOfClass:[SQListItem class]]) {
        SQListItem* listItem = item;
        if (PS_LAYER_PARENT == listItem.sqType) {
            //返回上层目录
            [self returnParentFolder:listItem.sqContent];
        }
    } else if ([item isKindOfClass:[PSLayer class]]) {
        PSLayer* layer = item;
        if (PS_LAYER_FOLDER == layer.psLayerType) {
            //打开子目录
            [self openSubLayers:layer];
        } else {
            //显示或隐藏图层
            [self setLayerVisible:layer withViewCell:[self.psTableView cellForRowAtIndexPath:indexPath]];
        }
    }

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

/**
 处理图层的可见性
 */
-(void)onClickLayerVisible:(id)sender
{
    int index = (int)[SQManager getViewIndex:sender inTableView:self.psTableView];
    UITableViewCell* viewCell = [SQManager tableViewCellWithView:sender inTableView:self.psTableView];
    PSLayer* layer = [self.psListTableItem objectAtIndex:index];
    
    [self setLayerVisible:layer withViewCell:viewCell];
}

- (IBAction)onClickBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onClickFullScreen:(id)sender
{
    self.psTableView.hidden = YES;
    [self.psDrawView fullScreen];
    
    [self handleSingleTap:nil];
}

- (IBAction)onClickRestoreView:(id)sender
{
    self.psTableView.hidden = YES;
    [self.psDrawView restoreView];
    
    [self handleSingleTap:nil];
}

- (IBAction)onClickRotate:(id)sender {
    self.psTableView.hidden = YES;
    //旋转图片
    [self.psDrawView rotateWithAngle:-90];
}

- (IBAction)onClickShowLayers:(id)sender {
    if (self.psIsLoadingLayer) {
        return; //图层正在加载中，不能重复操作
    }
    
    if (self.psListLayer) {
        //图层数据已存在，无需再次处理
        self.psTableView.hidden = !(self.psTableView.hidden);
    } else {
        //加载图层数据
        self.psIsLoadingLayer = YES;
        [self.psProgressView setHidden:NO];
        self.psProgressView.progress = 0;
        self.psListLayer = [NSMutableArray array];
        NSString* fileCode = [NSString stringWithFormat:@"layerimg_%d", self.psFileItem.psIndex];
        
        [self performSelectorInBackground:@selector(loadLayerDataOnBackThead:) withObject:@[self.psFileItem.psFilePath, self.psListLayer, fileCode]];
    }
}

@end

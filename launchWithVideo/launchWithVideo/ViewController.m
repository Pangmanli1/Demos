//
//  ViewController.m
//  launchWithVideo
//
//  Created by Maria_Pang on 17/3/28.
//  Copyright © 2017年 Maria_Pang. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <HealthKit/HealthKit.h>
#import <CoreTelephony/CTCellularData.h>
#import <CoreMotion/CoreMotion.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <UserNotifications/UserNotifications.h>


// 通用
#define careCommonMarginTop 64
#define careCommonWidth self.view.frame.size.width
#define careCommonHeight self.view.frame.size.height-careCommonMarginTop

#define IOS_VERSION ([[[UIDevice currentDevice] systemVersion] floatValue])
#define IOS_7 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0 ? YES : NO)
#define CHNaviHight ((IOS_7) ? 64 : 44)
#define CHSScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define CHSScreenHeight  ([UIScreen mainScreen].bounds.size.height)
#define kMSGUIDESCREENHEIGHT CGRectGetHeight([UIScreen mainScreen].bounds)
#define CH_DEVICE_IS_IPHONE5 ([[UIScreen mainScreen] bounds].size.height == 568)
#define CH_IPHONE6_OR_LATER ([[UIScreen mainScreen] bounds].size.height > 568)
#define CHBarHight ((IOS_7) ? 20 : 0)


#define LOGIC_DEVICE_WIDTH   (750)
#define LOGIC_DEVICE_HEIGHT  (1334)

#define GetLogicPixelX(value) ((CHSScreenWidth/LOGIC_DEVICE_WIDTH)*(value))
#define GetLogicPixelY(value) ((CHSScreenHeight/LOGIC_DEVICE_HEIGHT)*(value))
#define GetLogicFont(value) ((CHSScreenWidth*2/LOGIC_DEVICE_WIDTH)*(value))


#define  NavBarOrginY  GetLogicPixelY(40)


@interface ViewController ()<CLLocationManagerDelegate>

@property (nonatomic, strong)CMPedometer *Pedometer ;
@property (nonatomic, strong)CLLocationManager *manager ;
@property (nonatomic, strong)AVPlayerItem * playerItem;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initView];
    
    [self addFinishPlayNotification];
}


- (void)initView {
    
    NSString * path = [[NSBundle mainBundle]pathForResource:@"ledongliGuide.mp4" ofType:nil];
    NSURL *sourceMovieUrl = [NSURL fileURLWithPath:path];
    AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:sourceMovieUrl options:nil];
    self.playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
    player = [AVPlayer playerWithPlayerItem:self.playerItem];
    AVPlayerLayer * layer = [AVPlayerLayer playerLayerWithPlayer:player];
    layer.frame = self.view.frame;
    layer.videoGravity =AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:layer];
    [player play];
    
    
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, careCommonWidth, self.view.frame.size.height)];
    [_scrollView setBackgroundColor:[UIColor clearColor]];
    [_scrollView setContentSize:CGSizeMake(careCommonWidth*3, self.view.frame.size.height)];
    
    _scrollView.bounces=NO;
    _scrollView.showsHorizontalScrollIndicator=NO;
    _scrollView.showsVerticalScrollIndicator=NO;
    _scrollView.pagingEnabled=YES;
    _scrollView.delegate=self;
    
    [self.view addSubview:_scrollView];
    [self.view bringSubviewToFront:_scrollView];
    
    UIView * locationView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, careCommonWidth, self.view.frame.size.height)];
    locationView.backgroundColor = [UIColor clearColor];
    [_scrollView addSubview: locationView];
    
    
    UIView * healthView = [[UIView alloc]initWithFrame:CGRectMake(careCommonWidth, 0, careCommonWidth, self.view.frame.size.height)];
    healthView.backgroundColor = [UIColor clearColor];
    [_scrollView addSubview:healthView];
    
    
    UIView * pushView = [[UIView alloc]initWithFrame:CGRectMake(careCommonWidth*2, 0, careCommonWidth, self.view.frame.size.height)];
    pushView.backgroundColor = [UIColor clearColor];
    [_scrollView addSubview:pushView];
    
    
    //button1
    UIButton *Button1 = [[UIButton alloc] initWithFrame:CGRectMake( (careCommonWidth - GetLogicPixelX(320))/2  ,self.view.frame.size.height - GetLogicPixelY(200), GetLogicPixelX(320), GetLogicPixelY(94))];
    [Button1 setTitle:@"开启定位权限" forState:UIControlStateNormal];
    [Button1 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [Button1 setBackgroundColor:[UIColor clearColor]];
    [Button1 addTarget:self action:@selector(locationAuthorize:) forControlEvents:UIControlEventTouchUpInside];
    Button1.tag = 1;
    [locationView addSubview:Button1];
    
    
    //button2
    UIButton *Button2 = [[UIButton alloc] initWithFrame:CGRectMake( (careCommonWidth - GetLogicPixelX(320))/2  ,self.view.frame.size.height - GetLogicPixelY(200), GetLogicPixelX(320), GetLogicPixelY(94))];
    [Button2 setTitle:@"获取健康数据权限" forState:UIControlStateNormal];
    [Button2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [Button2 setBackgroundColor:[UIColor clearColor]];
    [Button2 addTarget:self action:@selector(healthKitAuthorize:) forControlEvents:UIControlEventTouchUpInside];
    Button2.tag = 2;
    [healthView addSubview:Button2];
    
    //button3
    UIButton *Button = [[UIButton alloc] initWithFrame:CGRectMake( (careCommonWidth - GetLogicPixelX(320))/2  ,self.view.frame.size.height - GetLogicPixelY(200), GetLogicPixelX(320), GetLogicPixelY(94))];
    [Button setTitle:@"获取推送通知权限" forState:UIControlStateNormal];
    [Button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    //    [Button setBackgroundImage:[UIImage imageNamed:@"wel_button"] forState:UIControlStateNormal];
    [Button setBackgroundColor:[UIColor clearColor]];
    [Button addTarget:self action:@selector(allowPush:) forControlEvents:UIControlEventTouchUpInside];
    Button.tag = 3;
    [pushView addSubview:Button];
    
    
    pageControl = [[UIPageControl alloc]init];
    [pageControl setCurrentPage:0];
    [pageControl setFrame:CGRectMake( (careCommonWidth - GetLogicPixelX(320))/2  ,self.view.frame.size.height - GetLogicPixelY(20), GetLogicPixelX(320), GetLogicPixelY(20))];
    pageControl.center = CGPointMake((self.view.frame.size.width - pageControl.frame.size.width)/2+ pageControl.frame.size.width/2, self.view.frame.size.height - GetLogicPixelY(30) );
    pageControl.numberOfPages = 3;
    
    if([pageControl respondsToSelector:@selector(pageIndicatorTintColor)]){
        pageControl.pageIndicatorTintColor = [UIColor whiteColor];//[UIColor colorWithRed:255 green:255 blue:255.0 alpha:0.5];//[UIColor greenColor];
    }
    if([pageControl respondsToSelector:@selector(currentPageIndicatorTintColor)]){
        pageControl.currentPageIndicatorTintColor = [UIColor blackColor];//[UIColor redColor];
    }
    
    [self.view addSubview:pageControl];
}

#pragma mark - 获取定位权限
-(void)locationAuthorize:(UIButton*)sender{
    
    pageControl.userInteractionEnabled = NO;
    
    //定位服务是否可用
    BOOL enable=[CLLocationManager locationServicesEnabled];
    //是否具有定位权限
    int status=[CLLocationManager authorizationStatus];
    self.manager = [[CLLocationManager alloc] init];
    self.manager.delegate = self;
    
    
    [self.manager requestWhenInUseAuthorization];
    [self.manager requestAlwaysAuthorization];
    
    if (enable) {
        if (status == 0) {
            
            NSLog(@"status%d", status);
            
        }else {
            
            NSLog(@"status%d", status);
        }
        
        //        [pageControl setCurrentPage:1];
        
        
    } else {
        
        NSLog(@"去设置打开定位服务");
    }
    
    
    
}

#pragma mark - 获取计步器健康数据权限
-(void)healthKitAuthorize:(UIButton*)sender{
    
    sender.selected = !sender.selected;
    _scrollView.scrollEnabled = NO;
    pageControl.userInteractionEnabled = YES;
    
    if ([CMPedometer isStepCountingAvailable]) {
        [self.Pedometer queryPedometerDataFromDate:[NSDate dateWithTimeIntervalSinceNow:-60*60*24*2] toDate:[NSDate dateWithTimeIntervalSinceNow:60] withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error) {
            if (error) {
                NSLog(@"error====%@",error);
            }else {
                NSLog(@"步数====%@",pedometerData.numberOfSteps);
                NSLog(@"距离====%@",pedometerData.distance);
            }
            
            [_scrollView setContentOffset:CGPointMake(careCommonWidth*2, 0) animated:YES];
            
        }];
    }else{
        NSLog(@"计步功能不可用");
    }
    
}


#pragma mark- 获取推送通知权限
-(void)allowPush:(UIButton*)sender{
    
    pageControl.userInteractionEnabled = YES;
    
    UIApplication * app = [UIApplication sharedApplication];
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
        
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted) {
                
                pageControl.userInteractionEnabled = NO;
                NSLog(@"进入主页面");
                [player pause];
                
            } else {
                pageControl.userInteractionEnabled = NO;
                NSLog(@"注册失败,进入主页面");
                [player pause];
                
            }
        }];
    }else if ([[UIDevice currentDevice].systemVersion floatValue] >8.0){
        
        [app registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge categories:nil]];
        pageControl.userInteractionEnabled = NO;
        NSLog(@"进入主页面");
        [player pause];
    }else if ([[UIDevice currentDevice].systemVersion floatValue] < 8.0) {
        //iOS8系统以下
        [app registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
        pageControl.userInteractionEnabled = NO;
        NSLog(@"进入主页面");
        [player pause];
    }
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    
    
}

#pragma mark- 滚动停止pageControl跳转
-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    double page = scrollView.contentOffset.x / careCommonWidth;
    pageControl.currentPage = (int)(page + 0.5);
    
}

#pragma mark- 懒加载计步器
-(CMPedometer *)Pedometer {
    
    if (_Pedometer == nil) {
        
        _Pedometer = [[CMPedometer alloc]init];
        
    }
    
    return _Pedometer;
}

#pragma mark- 添加播放器完成通知
-(void)addFinishPlayNotification{
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(playback:) name:AVPlayerItemDidPlayToEndTimeNotification object:player.currentItem];
    
}

#pragma mark- 播放完成重播
-(void)playback:(NSNotification*)notification {
    
    [self.playerItem seekToTime:kCMTimeZero];
    [player play];
}

#pragma mark- 地图定位授权状态改变
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    //    NSLog(@"地图状态改变%@",status);
    
    [_scrollView setContentOffset:CGPointMake(careCommonWidth*1, 0) animated:YES];
    
    
}

#pragma mark- 移除通知
-(void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:player.currentItem];
}



@end

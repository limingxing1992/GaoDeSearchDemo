//
//  ViewController.m
//  GaoDeSearchDemo
//
//  Created by qianfeng on 15/12/1.
//  Copyright © 2015年 李明星. All rights reserved.
//

#import "ViewController.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapSearchKit.h>

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height



@interface ViewController ()<MAMapViewDelegate,AMapSearchDelegate>
{
    MAMapView *_mapView;
    BOOL _isLoacling;
    AMapSearchAPI *_search;
    CGFloat _currentLatitude;
    CGFloat _currentLongtude;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createMapView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -----------------------构建地图视图
-(void)createMapView
{
//    //取消自动布局对导航栏影响
//    self.automaticallyAdjustsScrollViewInsets = NO;
    
    _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
    _mapView.delegate = self;
    
    //进入页面默认开启定位
    _mapView.showsUserLocation = YES;
    _isLoacling = YES;
    //设置地图缩放级别
    [_mapView setZoomLevel:15 animated:YES];
    
    
    //自定义当前地址气泡
    _mapView.userTrackingMode = MAUserTrackingModeFollowWithHeading;
    
    [_mapView setUserTrackingMode:MAUserTrackingModeFollow animated:YES];
    
    [self.view addSubview:_mapView];
    
    
//    添加关闭定位和开启定位按钮
    UIButton *local_button = [[UIButton alloc] initWithFrame:CGRectMake(kScreenWidth/2, kScreenHeight - 50, 50, 50)];
    [local_button setBackgroundImage:[UIImage imageNamed:@"定位中"] forState:UIControlStateNormal];
    [local_button addTarget:self action:@selector(localing:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:local_button];
    
    
    
    //添加搜索按钮
    UIButton *food_search = [[UIButton alloc] initWithFrame:CGRectMake(0, kScreenHeight -50, 50, 50)];
    food_search.backgroundColor = [UIColor redColor];
    [food_search setTitle:@"餐饮服务" forState:UIControlStateNormal];
    [food_search addTarget:self action:@selector(searchFood:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:food_search];
    
    
    
}
#pragma mark -------------------------餐饮搜索
-(void)searchFood:(UIButton *)sender
{
    //添加搜索功能

    _search = [[AMapSearchAPI alloc] init];
    _search.delegate = self;
    AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest   alloc] init];
    request.location  = [AMapGeoPoint locationWithLatitude:_currentLatitude longitude:_currentLongtude];
    request.types = sender.titleLabel.text;
    request.keywords = @"河南教育学院";
    request.sortrule = 0;
    request.requireExtension = YES;
    
    //发起周边搜索
    [_search AMapPOIAroundSearch:request];
}
#pragma mark -------------------------定位开关按钮
-(void)localing:(UIButton *)local_button
{
    if (_isLoacling == YES) {
        _isLoacling = NO;
        
        //关闭定位
        _mapView.showsUserLocation = NO;
        
        [local_button setBackgroundImage:[UIImage imageNamed:@"未定位"] forState:UIControlStateNormal];
    }else{
        
        _isLoacling = YES;
        //开启定位
        _mapView.showsUserLocation = YES;
        
        [local_button setBackgroundImage:[UIImage imageNamed:@"定位中"] forState:UIControlStateNormal];
    }
}
#pragma mark --------------------------定位代理
-(void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    if (updatingLocation) {
        _currentLatitude = userLocation.coordinate.latitude;
        _currentLongtude = userLocation.coordinate.longitude;

    }
    
    //进行反地理编码取得地址信息
    AMapReGeocodeSearchRequest *request = [[AMapReGeocodeSearchRequest alloc] init];
    request.location = [AMapGeoPoint locationWithLatitude:userLocation.coordinate.latitude longitude:userLocation.coordinate.longitude];
    request.radius = 1000;
    request.requireExtension = YES;
    [_search AMapReGoecodeSearch:request];
    
    
}

#pragma mark ----------------------------反地理编码返回结果
-(void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response
{
    if (response.regeocode != nil) {
        
        UITextView *view = [[UITextView alloc] initWithFrame:CGRectMake(kScreenWidth -100, kScreenHeight - 50, 100, 50)];
        view.text = response.regeocode.formattedAddress;
        [self.view addSubview:view];
        
    }
    
}

#pragma mark ----------------------------自定义当前位置经纬度圈样式
- (void)mapView:(MAMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    MAAnnotationView *view = views[0];
    
    // 放到该方法中用以保证userlocation的annotationView已经添加到地图上了。
    if ([view.annotation isKindOfClass:[MAUserLocation class]])
    {
        MAUserLocationRepresentation *pre = [[MAUserLocationRepresentation alloc] init];
        pre.fillColor = [UIColor colorWithRed:0.9 green:0.1 blue:0.1 alpha:0.3];
        pre.strokeColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.9 alpha:1.0];
        pre.image = [UIImage imageNamed:@"location.png"];
        pre.lineWidth = 3;
        pre.lineDashPattern = @[@6, @3];
        
        [_mapView updateUserLocationRepresentation:pre];
        
        view.calloutOffset = CGPointMake(0, 0);
    }  
}
#pragma mark --------------------------周边搜索结果
-(void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response
{
    if (response.pois.count == 0) {
        return;
    }
    
    NSString *strCount = [NSString stringWithFormat:@"count: %ld",response.count];
    NSString *strSuggestion = [NSString stringWithFormat:@"Suggestion: %@", response.suggestion];
    NSString *strPoi = @"";
    for (AMapPOI *p in response.pois) {
        strPoi = [NSString stringWithFormat:@"%@\nPOI: %@", strPoi, p.description];
        NSLog(@"%@",p.name);
    }
    NSString *result = [NSString stringWithFormat:@"RESULT====%@ \n %@ \n %@", strCount, strSuggestion, strPoi];
    NSLog(@"Place: %@", result);
}

@end

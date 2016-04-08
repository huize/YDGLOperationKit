//
//  ViewController.m
//  test_openges
//
//  Created by 辉泽许 on 16/1/4.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "ViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>

#import "LVECatpureSessionHelper.h"

#import <YDGLOperationKit/YDGLOperationKit.h>

@import ImageIO;

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>{

    UIImage *_image;
    
    YDGLOperationNodeView *_customView;
    
    LVECatpureSessionHelper *_captureSessionHelper;
    
    YDGLOperationCVPixelBufferSourceNode *_operationSource;
    
    dispatch_queue_t _captureQueue;

}

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    _captureSessionHelper=[[LVECatpureSessionHelper alloc]init];
    
    CGSize screenSize=[UIScreen mainScreen].bounds.size;
    
    _customView=[[YDGLOperationNodeView alloc]initWithFrame:CGRectMake(0, 0,screenSize.width, screenSize.height)];
    
    _customView.center=[_customView convertPoint:self.view.center fromView:self.view];
    
    [self.view addSubview:_customView];
    
    [self buildBeautyGroupLayer];
    
    [_customView addDependency:_operationSource];
    
    __weak typeof(self) weakSelf=self;
    
    //_captureQueue=dispatch_queue_create([@"拍摄线程" UTF8String], DISPATCH_QUEUE_SERIAL);
    
    _captureQueue=[YDGLOperationNode getWorkQueue];
    
    [_captureSessionHelper setSampleBufferDelegate:weakSelf queue:_captureQueue];
    
    //[_operationSecondSource start];
    
    
    YDGLOperationNV12SourceNode *nvNode=[YDGLOperationNV12SourceNode new];
    
    NSLog(@"%@",nvNode);
    
}

-(void)viewDidAppear:(BOOL)animated{

    [super viewDidAppear:animated];
    
    [_captureSessionHelper startRunning];
    
}

-(void)buildBeautyGroupLayer{
    
    _operationSource=[YDGLOperationCVPixelBufferSourceNode new];
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{

    
    if ([_operationSource isLocked]) {
        
        NSLog(@"_operationSource 节点被锁");
        
        return;
        
    }
    
    CVImageBufferRef imageBufferRef=CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(imageBufferRef, 0);
    
    [_operationSource uploadCVPixelBuffer:imageBufferRef];
    
    //[_operationSource uploadImage:[UIImage imageNamed:@"rgb"]];
    
    [_operationSource start];
    
    //[_operationSecondSource start];
    
    CVPixelBufferUnlockBaseAddress(imageBufferRef, 0);
    
}


-(void)startRun{
    
    [_operationSource start];
    
}

-(void)dealloc{

    [_captureSessionHelper stopRunning];
    
    NSLog(@"视频测试页面已经销毁了");
    
    [_operationSource destory];
       
    [_customView removeFromSuperview];

}


@end

//
//  ViewController.m
//  test_openges
//
//  Created by 辉泽许 on 16/1/4.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "ViewController.h"
#import "CustomGLView.h"
#import <MobileCoreServices/MobileCoreServices.h>

#import "LVECatpureSessionHelper.h"

#import <YDGLOperationKit/YDGLOperationKit.h>

#import "YDGLBeautyOperationLayer.h"

#import "YDGLGaussianBlurOperationLayer.h"

@import ImageIO;

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>{

    UIImage *_image;
    
    CustomGLView *_customView;
    
    LVECatpureSessionHelper *_captureSessionHelper;
    
    YDGLOperationSourceNode *_operationSource;
    
    YDGLOperationSourceNode *_operationSecondSource;
    
    YDGLOperationNode * _middleNode;
    
    YDGLOperationNode *_finalNode;
    
    dispatch_queue_t _captureQueue;

}

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    _captureSessionHelper=[[LVECatpureSessionHelper alloc]init];
    
    CGSize screenSize=[UIScreen mainScreen].bounds.size;
    
    _customView=[[CustomGLView alloc]initWithFrame:CGRectMake(0, 0,screenSize.width, screenSize.height)];
    
    _customView.center=[_customView convertPoint:self.view.center fromView:self.view];
    
    [self.view addSubview:_customView];
    
    [self buildBeautyGroupLayer];
    
    [_customView addDependency:_finalNode];
    
    __weak typeof(self) weakSelf=self;
    
    //_captureQueue=dispatch_queue_create([@"拍摄线程" UTF8String], DISPATCH_QUEUE_SERIAL);
    
    _captureQueue=[YDGLOperationNode getWorkQueue];
    
    [_captureSessionHelper setSampleBufferDelegate:weakSelf queue:_captureQueue];
    
    [_operationSecondSource start];
    
}

-(void)viewDidAppear:(BOOL)animated{

    [super viewDidAppear:animated];
    
    [_customView startRender];
    
    [_captureSessionHelper startRunning];
    
}

-(void)buildBeautyGroupLayer{
    
    _operationSource=[YDGLOperationSourceNode new];
    
    _middleNode=[YDGLOperationNode new];
    
    [_middleNode addDependency:_operationSource];
    
    
    int level=5;
    
    int blur=4;
    
  
    YDGLGaussianBlurOperationLayer *gaussianFirst=[[YDGLGaussianBlurOperationLayer alloc]initWithVertexShader:[YDGLGaussianBlurOperationLayer vertexShaderForOptimizedBlurOfRadius:blur sigma:2.0f] andFragmentShader:[YDGLGaussianBlurOperationLayer fragmentShaderForOptimizedBlurOfRadius:blur sigma:2.0f]];
    
    [gaussianFirst addDependency:_operationSource];
    
    [gaussianFirst setWidthOffset:0.0029166667F andHeightOffset:0.0029166667F];
    
    YDGLGaussianBlurOperationLayer *gaussianSecond=[[YDGLGaussianBlurOperationLayer alloc]initWithVertexShader:[YDGLGaussianBlurOperationLayer vertexShaderForOptimizedBlurOfRadius:blur sigma:2.0f] andFragmentShader:[YDGLGaussianBlurOperationLayer fragmentShaderForOptimizedBlurOfRadius:blur sigma:2.0f]];
    
    [gaussianSecond addDependency:gaussianFirst];
    
    [gaussianSecond setWidthOffset:-0.0029166667F andHeightOffset:0.0029166667F];
    
    YDGLBeautyOperationLayer *finalLayer=[YDGLBeautyOperationLayer new];
    
    [finalLayer addDependency:_operationSource];
    
    [finalLayer addDependency:gaussianSecond];
    
    UIImage *image2=[UIImage imageNamed:@"beauty_qupai_7"];
    
    _operationSecondSource=[[YDGLOperationSourceNode alloc]initWithUIImage:image2];
    
    [finalLayer addDependency:_operationSecondSource];
    
    _finalNode=finalLayer;
    
    
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
    
    [_operationSecondSource start];
}

-(void)dealloc{

    [_captureSessionHelper stopRunning];
    
    NSLog(@"视频测试页面已经销毁了");
    
    [_operationSource destory];
    
    [_operationSecondSource destory];
    
    [_middleNode destory];
    
    [_customView removeFromSuperview];

}


@end

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

@import ImageIO;

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>{

    UIImage *_image;
    
    CustomGLView *_customView;
    
    LVECatpureSessionHelper *_captureSessionHelper;
    
    YDGLOperationSourceNode *_operationSource;
    
    YDGLOperationSourceNode *_operationSecondSource;
    
    YDGLOperationNode * _middleNode;
    
    
    CADisplayLink *_displayLink;

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
    
    _middleNode=[self buildBeautyGroupLayer];
    
    [_customView addDependency:_middleNode];
    
    _displayLink=[CADisplayLink displayLinkWithTarget:self selector:@selector(startRun)];
    _displayLink.frameInterval=3;
    
    _displayLink.paused=YES;
    
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    [_captureSessionHelper setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    
}

-(void)viewDidAppear:(BOOL)animated{

    [super viewDidAppear:animated];
    
    [_customView startRender];
    
    [_captureSessionHelper startRunning];
    
}

-(YDGLOperationNode*)buildBeautyGroupLayer{
    
    
     /*NSString *path=[[NSBundle mainBundle] pathForResource:@"头像" ofType:@".jpg"];
     
     UIImage *image=[UIImage imageWithContentsOfFile:path];
     
     _operationSource=[[YDGLOperationSourceNode alloc]initWithUIImage:image];
     
     NSString *path2=[[NSBundle mainBundle] pathForResource:@"rgb" ofType:@".png"];
     
     UIImage *image2=[UIImage imageWithContentsOfFile:path2];
     
     _operationSecondSource=[[YDGLOperationSourceNode alloc]initWithUIImage:image2];
     
     YDGLOperationTwoInputNode *secondLayer=[YDGLOperationTwoInputNode new];*/
    
    _operationSource=[YDGLOperationSourceNode new];
    
    YDGLOperationNode *thirdLayer=[YDGLOperationNode new];
    
    [thirdLayer addDependency:_operationSource];
    
    return thirdLayer;
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{

    CVImageBufferRef imageBufferRef=CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(imageBufferRef, 0);
    
    [_operationSource uploadCVPixelBuffer:imageBufferRef];
    
    //[_operationSource uploadImage:[UIImage imageNamed:@"rgb"]];
    
    [_operationSource start];
    
    CVPixelBufferUnlockBaseAddress(imageBufferRef, 0);
    
}


-(void)startRun{
    
    [_operationSource start];
    
    [_operationSecondSource start];
}

-(void)dealloc{

    [_displayLink invalidate];

}


@end

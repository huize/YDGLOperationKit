//
//  YDGLOperationImageTestViewController.m
//  ydgloperationTest
//
//  Created by 辉泽许 on 16/3/17.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationImageTestViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>

#import <YDGLOperationKit/YDGLOperationKit.h>

#import "YDGLAlphaNode.h"

@implementation YDGLOperationImageTestViewController
{

    UIImage *_image;
    
    YDGLOperationNodeDisplayView *_customView;
    
    YDGLOperationUIImageSourceNode *_operationSource;
    
    YDGLOperationUIImageSourceNode *_operationSecondSource;
    
    YDGLOperationNode *_thirdNode;

    YDGLOperationNodeLayer *_secondNode;
    
    CADisplayLink *_displayLink;
    
    YDGLAlphaNode *_alphaNode;
    
    UIButton *_button;

    BOOL _stoped;
    
    dispatch_queue_t _workQueue;
    
    BOOL _invalidate;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    CGSize screenSize=[UIScreen mainScreen].bounds.size;
    
    [YDGLOperationContext pushContext];
    
    _customView=[[YDGLOperationNodeDisplayView alloc]initWithFrame:CGRectMake(0, 0,screenSize.width, screenSize.height-100)];
    
    //_customView.center=[_customView convertPoint:self.view.center fromView:self.view];
    
    [self.view addSubview:_customView];
    
    [self initLayer];
    
    [_customView setContentProviderNode:_thirdNode];
    
    __weak typeof (self) weakSelf=self;
    
    _displayLink=[CADisplayLink displayLinkWithTarget:weakSelf selector:@selector(startRun)];

    _displayLink.paused=YES;
    
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    _button=[[UIButton alloc]initWithFrame:CGRectMake(0, screenSize.height-100, 50, 40)];
    
    [_button setTitle:@"挂起" forState:UIControlStateNormal];
    [_button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    
    
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc]initWithTarget:weakSelf action:@selector(stopGPUQueue:)];
    
    [_button addGestureRecognizer:tap];
    
    [self.view addSubview:_button];
    
    _workQueue=dispatch_queue_create([@"node 工作线程" UTF8String], DISPATCH_QUEUE_CONCURRENT);
    
}

-(void)stopGPUQueue:(id)sender{
   
    if (_stoped) {
        
        dispatch_resume(_workQueue);
        _stoped=NO;
        
        
    }else{
    
        dispatch_suspend(_workQueue);
        
        _stoped=YES;
    }

}

-(void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];

    _displayLink.paused=NO;
    

}

-(void)viewDidDisappear:(BOOL)animated{

    [super viewDidDisappear:animated];
    
    _displayLink.paused=YES;
    
    [_displayLink invalidate];
    
    _displayLink=nil;
    
    _invalidate=YES;
    
    [_operationSource destory];
    
    [_operationSecondSource destory];
    
    [_thirdNode destory];
    
    [_secondNode destory];
    
    //[_customView removeFromSuperview];

}


-(void)initLayer{
    
    NSString *path=[[NSBundle mainBundle] pathForResource:@"头像" ofType:@".jpg"];
    
    UIImage *image=[UIImage imageWithContentsOfFile:path];
        
    _operationSource=[YDGLOperationUIImageSourceNode new];
    
    [_operationSource uploadImage:image];
    
    UIImage *image2=[UIImage imageNamed:@"star22"];
    
    _operationSecondSource =[YDGLOperationUIImageSourceNode new];
    
    [_operationSecondSource uploadImage:image2];
    
    _alphaNode=[YDGLAlphaNode new];
    
    [_alphaNode addDependency:_operationSecondSource];
    
    _secondNode=[YDGLOperationNodeLayer new];
        
    [_secondNode addDependency:_operationSource];
    
    YDGLOperationNodeLayer *layer2=[YDGLOperationNodeLayer new];
    
    [layer2 addDependency:_operationSecondSource];
    
    layer2.frame=CGRectMake(50.0, 50.0, image2.size.width,image2.size.height);
    
    [_secondNode addSubNode:layer2];
    
    layer2.opaticy=1.0f;
    
    layer2.transform=GLKMatrix4Rotate(GLKMatrix4Identity, M_PI_4, 0.0, 0.0, 1.0);
    
    _thirdNode=_secondNode;
    
    
    

    
//    _secondNode.operationCompletionBlock=^(YDGLOperationNodeOutput *outputData){
//    
//        
//        CVPixelBufferRef imageBufferRef=outputData.pixelBuffer;
//        
//        CVPixelBufferLockBaseAddress(imageBufferRef, 0);
//        
//        UInt8 *data=CVPixelBufferGetBaseAddress(imageBufferRef);
//        
//        struct BGRA{
//            
//            uint8_t B;
//            uint8_t G;
//            uint8_t R;
//            uint8_t A;
//            
//        };
//        
//        struct BGRA *tt=(struct BGRA*)data;
//        
//        for (int index=0; index<50; index++) {
//            
//            struct   BGRA pixel=tt[index];
//            
//            NSLog(@"B:%i G:%i R:%i A:%i",pixel.B,pixel.G,pixel.R,pixel.A);
//        }
//        
//    };
    

    
}

-(void)startRun{
    
    //dispatch_barrier_async will crash
    
    dispatch_barrier_async(_workQueue, ^{
        
        if (_invalidate) {
            
            return ;
        }
        
        [_operationSource start];
        
        [_operationSecondSource start];
        
        [_operationSource setNeedDisplay];
        
        [_operationSecondSource setNeedDisplay];
    
    });
    
}

-(void)dealloc{
    
    [_displayLink invalidate];
    
    [YDGLOperationContext popContext];
    
    NSLog(@"图片测试页面已经销毁了:%@",self);

}

@end

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
    
    YDGLOperationNodeLayer *_starLayer1,*_starLayer2;
    
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
    
    _customView=[[YDGLOperationNodeDisplayView alloc]initWithFrame:CGRectMake(0, 0,screenSize.width, screenSize.height)];
    
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

-(void)showNotifice{


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
    
    [_starLayer1 removeFromSuperNodeLayer];
    
    [_starLayer2 removeFromSuperNodeLayer];
    
}

-(void)initLayer{
    
    NSString *path=[[NSBundle mainBundle] pathForResource:@"头像" ofType:@".png"];
    
    UIImage *image=[UIImage imageWithContentsOfFile:path];
        
    _operationSource=[YDGLOperationUIImageSourceNode new];
    
    NSLog(@"----%@",_operationSource);
    
    [_operationSource uploadImage:image];
    
    UIImage *image2=[UIImage imageNamed:@"star22"];
    
    _operationSecondSource =[YDGLOperationUIImageSourceNode new];
    
    NSLog(@"----%@",_operationSecondSource);//TODO
    
    [_operationSecondSource uploadImage:image2];
    
    _alphaNode=[YDGLAlphaNode new];
    
    NSLog(@"----%@",_alphaNode);

    
    [_alphaNode addDependency:_operationSecondSource];
    
    _secondNode=[YDGLOperationNodeLayer new];
    
    NSLog(@"----%@",_secondNode);

    
    [_secondNode addDependency:_operationSource];
    
    _starLayer1=[YDGLOperationNodeLayer new];
    
    NSLog(@"----%@",_starLayer1);

    
    [_starLayer1 addDependency:_operationSecondSource];
    
    _starLayer1.frame=CGRectMake(100.0, 50.0, 100 ,100);
    
    [_secondNode addSubNodeLayer:_starLayer1];
    
    _starLayer1.opaticy=1.0f;
    
    _starLayer2=[YDGLOperationNodeLayer new];
    
    NSLog(@"----%@",_starLayer2);//TODO:

    
    [_starLayer2 addDependency:_operationSecondSource];
    
    _starLayer2.opaticy=0.0;
    
    _starLayer2.frame=_starLayer1.frame;
    
    [_secondNode addSubNodeLayer:_starLayer2];
    
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
        
        
        if([YDGLOperationContext currentGLContext]==nil){
        
            [YDGLOperationContext pushContext];

        }
        
        if (_invalidate) {
            
            return ;
        }
        
        static float scale=1.0f,alpha=0.0f;
        
        _starLayer2.transform=GLKMatrix4Scale(GLKMatrix4Identity, scale, scale, 1.0);
        _starLayer2.opaticy=alpha;
        
        scale+=0.05f;
        
        alpha+=0.05f;
        
        if (scale>2.0f) {
            
            scale=1.0f;
        }
        
        if (alpha>1.0) {
            
            alpha=0.0f;
        }
        
        
        [_operationSource drive];
        
        [_operationSecondSource drive];
        
        //[_operationSource setNeedDisplay];
        
        //[_operationSecondSource setNeedDisplay];
    
    });
    
}

-(void)dealloc{
    
    [_displayLink invalidate];
    
    [YDGLOperationContext popContext];

    NSLog(@"图片测试页面已经销毁了:%@",self);
    
}

@end

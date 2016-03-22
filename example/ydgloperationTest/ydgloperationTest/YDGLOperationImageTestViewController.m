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

@implementation YDGLOperationImageTestViewController
{

    UIImage *_image;
    
    YDGLOperationNodeView *_customView;
    
    YDGLOperationSourceNode *_operationSource;
    
    YDGLOperationSourceNode *_operationSecondSource;
    
    YDGLOperationNode *_thirdNode;

    YDGLOperationTwoInputNode *_secondNode;
    
    CADisplayLink *_displayLink;
    
    
    UIButton *_button;

    
    BOOL _stoped;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    CGSize screenSize=[UIScreen mainScreen].bounds.size;
    
    _customView=[[YDGLOperationNodeView alloc]initWithFrame:CGRectMake(0, 0,screenSize.width, screenSize.height-100)];
    
    //_customView.center=[_customView convertPoint:self.view.center fromView:self.view];
    
    _customView.cube=YES;
    
    [self.view addSubview:_customView];
    
    [self initLayer];
    
    [_customView addDependency:_thirdNode];
    
    
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
    
}

-(void)stopGPUQueue:(id)sender{
   
    if (_stoped) {
        
        dispatch_resume([YDGLOperationSourceNode getWorkQueue]);
        _stoped=NO;
        
        
    }else{
    
        dispatch_suspend([YDGLOperationSourceNode getWorkQueue]);
        
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
    
    
}


-(void)initLayer{
    
    NSString *path=[[NSBundle mainBundle] pathForResource:@"头像" ofType:@".jpg"];
    
    UIImage *image=[UIImage imageWithContentsOfFile:path];
    
    _operationSource=[[YDGLOperationSourceNode alloc]initWithUIImage:image];
    
    NSString *path2=[[NSBundle mainBundle] pathForResource:@"rgb" ofType:@".png"];
    
    UIImage *image2=[UIImage imageWithContentsOfFile:path2];
    
    
    _operationSecondSource =[[YDGLOperationSourceNode alloc]initWithUIImage:image2];
    
    _secondNode=[YDGLOperationTwoInputNode new];
    
    [_secondNode setMix:0.5f];
    
    [_secondNode addDependency:_operationSource];
    
    [_secondNode addDependency:_operationSecondSource];

    _thirdNode=_secondNode;
    
}

-(void)startRun{
    
   // [_operationSource start];
    
    if ([_operationSource isLocked]==NO) {
        
        [_operationSource start];
        
        [_operationSecondSource start];
    }else{
    
       // NSLog(@"掉帧了");
    }
    
}

-(void)dealloc{
    
    [_displayLink invalidate];
    
    NSLog(@"图片测试页面已经销毁了");
    
    [_operationSource destory];
    
    [_operationSecondSource destory];
    
    [_thirdNode destory];
    
    [_secondNode destory];
        
    [_customView removeFromSuperview];
    
}

@end

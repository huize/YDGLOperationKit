//
//  YDGLOperationImageTestViewController.m
//  ydgloperationTest
//
//  Created by 辉泽许 on 16/3/17.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationImageTestViewController.h"

#import "CustomGLView.h"
#import <MobileCoreServices/MobileCoreServices.h>

#import <YDGLOperationKit/YDGLOperationKit.h>

@implementation YDGLOperationImageTestViewController
{

    UIImage *_image;
    
    CustomGLView *_customView;
    
    YDGLOperationSourceNode *_operationSource;
    
    YDGLOperationSourceNode *_operationSecondSource;
    
    YDGLOperationNode *_thirdNode;

    YDGLOperationTwoInputNode *_secondNode;
    
    CADisplayLink *_displayLink;

}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    CGSize screenSize=[UIScreen mainScreen].bounds.size;
    
    _customView=[[CustomGLView alloc]initWithFrame:CGRectMake(0, 0,screenSize.width, screenSize.height)];
    
    _customView.center=[_customView convertPoint:self.view.center fromView:self.view];
    
    _customView.cube=YES;
    
    [self.view addSubview:_customView];
    
    [self initLayer];
    
    [_customView addDependency:_thirdNode];
    
    
    __weak typeof (self) weakSelf=self;
    
    _displayLink=[CADisplayLink displayLinkWithTarget:weakSelf selector:@selector(startRun)];
    _displayLink.frameInterval=3;
    
    _displayLink.paused=YES;
    
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

-(void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
    
    [_customView startRender];
    
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
    
    _operationSecondSource=[[YDGLOperationSourceNode alloc]initWithUIImage:image2];
    
    _secondNode=[YDGLOperationTwoInputNode new];
    
    [_secondNode addDependency:_operationSource];
    
    [_secondNode addDependency:_operationSecondSource];
    
    [_secondNode setMix:0.5f];
    
    _thirdNode=[YDGLOperationNode new];
    
    [_thirdNode addDependency:_secondNode];
    
}

-(void)startRun{
    
    [_operationSource start];
    
    [_operationSecondSource start];
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

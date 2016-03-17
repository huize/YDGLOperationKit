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
    
    YDGLOperationNode * _middleNode;

    CADisplayLink *_displayLink;

}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    CGSize screenSize=[UIScreen mainScreen].bounds.size;
    
    _customView=[[CustomGLView alloc]initWithFrame:CGRectMake(0, 0,screenSize.width, screenSize.height)];
    
    _customView.center=[_customView convertPoint:self.view.center fromView:self.view];
    
    _customView.cube=YES;
    
    [self.view addSubview:_customView];
    
    _middleNode=[self buildBeautyGroupLayer];
    
    [_customView addDependency:_middleNode];
    
    _displayLink=[CADisplayLink displayLinkWithTarget:self selector:@selector(startRun)];
    _displayLink.frameInterval=3;
    
    _displayLink.paused=YES;
    
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
}

-(void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
    
    [_customView startRender];
    
    _displayLink.paused=NO;
    

}

-(YDGLOperationNode*)buildBeautyGroupLayer{
    
    NSString *path=[[NSBundle mainBundle] pathForResource:@"头像" ofType:@".jpg"];
    
    UIImage *image=[UIImage imageWithContentsOfFile:path];
    
    _operationSource=[[YDGLOperationSourceNode alloc]initWithUIImage:image];
    
    NSString *path2=[[NSBundle mainBundle] pathForResource:@"rgb" ofType:@".png"];
    
    UIImage *image2=[UIImage imageWithContentsOfFile:path2];
    
    _operationSecondSource=[[YDGLOperationSourceNode alloc]initWithUIImage:image2];
    
    YDGLOperationTwoInputNode *secondLayer=[YDGLOperationTwoInputNode new];
    
    [secondLayer addDependency:_operationSource];
    
    [secondLayer addDependency:_operationSecondSource];
    
    [secondLayer setMix:0.5f];
    
    YDGLOperationNode *thirdLayer=[YDGLOperationNode new];
    
    [thirdLayer addDependency:secondLayer];

    return thirdLayer;
    
}

-(void)startRun{
    
    [_operationSource start];
    
    [_operationSecondSource start];
}

-(void)dealloc{
    
    [_displayLink invalidate];
    
}

@end

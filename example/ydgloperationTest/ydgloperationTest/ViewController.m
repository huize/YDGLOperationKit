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

@interface ViewController (){

    UIImage *_image;
    
    CustomGLView *_customView;
    
    LVECatpureSessionHelper *_captureSessionHelper;
    
    YDGLOperationSourceNode *_operationSource;
    
    YDGLOperationSourceNode *_operationSecondSource;
    
    CADisplayLink *_displayLink;

}

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    //_captureSessionHelper=[[LVECatpureSessionHelper alloc]init];
    
    CGSize screenSize=[UIScreen mainScreen].bounds.size;
    
    _customView=[[CustomGLView alloc]initWithFrame:CGRectMake(0, 0,screenSize.width, screenSize.height)];
    
    _customView.center=[_customView convertPoint:self.view.center fromView:self.view];
    
    [self.view addSubview:_customView];
    
    YDGLOperationNode *beautyLayer=[self buildBeautyGroupLayer];
    
    [_customView addDependency:beautyLayer];
    
    _displayLink=[CADisplayLink displayLinkWithTarget:self selector:@selector(startRun)];
    _displayLink.frameInterval=3;
    
    _displayLink.paused=YES;
    
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    
}

-(void)viewDidAppear:(BOOL)animated{

    [super viewDidAppear:animated];
    
    [_customView startRender];
    

    if (DRAWCUBE) {
        
        _displayLink.paused=NO;
        
    }else{
    
        [_operationSource start];
        
        [_operationSecondSource start];
    
    }
    
}

-(YDGLOperationNode*)buildBeautyGroupLayer{
    
    
     NSString *path=[[NSBundle mainBundle] pathForResource:@"头像" ofType:@".jpg"];
     
     UIImage *image=[UIImage imageWithContentsOfFile:path];
     
     _operationSource=[[YDGLOperationSourceNode alloc]initWithUIImage:image];
     
     NSString *path2=[[NSBundle mainBundle] pathForResource:@"rgb" ofType:@".png"];
     
     UIImage *image2=[UIImage imageWithContentsOfFile:path2];
     
     _operationSecondSource=[[YDGLOperationSourceNode alloc]initWithUIImage:image2];
     
     YDGLOperationTwoInputNode *secondLayer=[YDGLOperationTwoInputNode new];
     
     YDGLOperationNode *thirdLayer=[YDGLOperationNode new];
     
     [_customView addDependency:thirdLayer];
     
     [thirdLayer addDependency:secondLayer];
     
     [secondLayer addDependency:_operationSource];
     
     [secondLayer addDependency:_operationSecondSource];
     
     [secondLayer setMix:0.5f];
     
    
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

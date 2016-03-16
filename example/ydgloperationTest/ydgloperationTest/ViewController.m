//
//  ViewController.m
//  ydgloperationTest
//
//  Created by 辉泽许 on 16/3/16.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "ViewController.h"

#import <YDGLOperationKit/YDGLOperationKit.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    YDGLOperationSourceNode *sorceNode=[YDGLOperationSourceNode new];
    
    NSLog(@"%@",sorceNode);
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

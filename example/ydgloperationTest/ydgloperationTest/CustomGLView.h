//
//  CustomGLView.h
//  test_openges
//
//  Created by 辉泽许 on 16/1/4.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <YDGLOperationKit/YDGLOperationKit.h>

@interface CustomGLView : UIView<YDGLOperationNode>

@property(nonatomic,assign) BOOL cube;//

-(void)startRender;

@end

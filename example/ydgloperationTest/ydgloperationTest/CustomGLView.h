//
//  CustomGLView.h
//  test_openges
//
//  Created by 辉泽许 on 16/1/4.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <YDGLOperationKit/YDGLOperationKit.h>


#define DRAWCUBE 0

@interface CustomGLView : UIView<YDGLOperationNode>

-(void)startRender;

@end

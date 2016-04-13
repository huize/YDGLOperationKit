//
//  YDGLOperationBlendNode.h
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/4/12.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationNode.h"

@interface YDGLOperationBlendNode : YDGLOperationNode

-(void)addDependency:(YDGLOperationNode*_Nonnull)operation atFrame:(CGRect)frame;

@end

@interface YDGLOperationNode(FrameSupport)

-(CGRect)getFrame;

-(void)setFrame:(CGRect)frame;

@end

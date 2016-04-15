//
//  YDGLOperationBlendNode.h
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/4/12.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationNode.h"

@interface YDGLOperationBlendNode : YDGLOperationNode

-(void)addSubNode:(id<YDGLOperationNode>_Nonnull)node atFrame:(CGRect)frame;

-(void)updateFrame:(CGRect)frame forSubNode:(id<YDGLOperationNode>_Nonnull)subNode;

@end


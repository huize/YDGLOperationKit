//
//  YDGLOperationBlendNode.h
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/4/12.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationNode.h"
/**
 *  @author 9527, 16-04-16 14:37:00
 *
 *  use glBlend to blend the dependency node content
 *
 *  @since 1.0.0
 */
@interface YDGLOperationBlendNode : YDGLOperationNode

-(void)addSubNode:(id<YDGLOperationNode>_Nonnull)node atFrame:(CGRect)frame;

-(void)updateFrame:(CGRect)frame forSubNode:(id<YDGLOperationNode>_Nonnull)subNode;

@end


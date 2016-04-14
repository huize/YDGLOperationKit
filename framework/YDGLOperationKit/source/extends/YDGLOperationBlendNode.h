//
//  YDGLOperationBlendNode.h
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/4/12.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationNode.h"

@interface YDGLOperationBlendNode : YDGLOperationNode

-(void)addSubNode:(YDGLOperationNode*_Nonnull)node atFrame:(CGRect)frame;

@end

@interface YDGLOperationNode(FrameSupport)

-(CGRect)getFrame;
/**
 *  @author 许辉泽, 16-04-13 17:06:27
 *
 *  注意:frame 是以左下角为原点,origin 表示的是矩形的左下角
 *
 *  @param frame frame description
 *
 *  @since 1.0.0
 */
-(void)setFrame:(CGRect)frame;

@end

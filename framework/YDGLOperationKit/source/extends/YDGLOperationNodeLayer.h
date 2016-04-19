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
 * like CALayer
 *
 *  @since 1.0.0
 */
@interface YDGLOperationNodeLayer : YDGLOperationNode

@property(nonatomic,assign)float opaticy;//alpha 0.0~1.0

@property(nonatomic,assign)CGRect frame;

@property(nonatomic,assign)GLKMatrix4 transform;//frame center as (0,0,0)

@property(nonatomic,assign,nullable)YDGLOperationNodeLayer* superNode;

-(void)addSubNode:(YDGLOperationNodeLayer*_Nonnull)subNode;

@end


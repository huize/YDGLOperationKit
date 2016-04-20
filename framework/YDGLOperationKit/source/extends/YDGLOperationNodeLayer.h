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
 * like CALayer,make YDGLOperationNode blendable
 *
 *  @since 1.0.0
 */
@interface YDGLOperationNodeLayer : YDGLOperationNode

@property(nonatomic,assign)float opaticy;//alpha 0.0~1.0

@property(nonatomic,assign)CGRect frame;

@property(nonatomic,assign)GLKMatrix4 transform;//frame center as (0,0,0)

@property(nonatomic,assign,nullable,readonly)YDGLOperationNodeLayer* superNodeLayer;
/**
 *  @author 9527, 16-04-20 20:58:10
 *
 *  like CALayer addSubLayer
 *
 *  @param subLayer layer you want to add
 *
 *  @since 1.0.0
 */
-(void)addSubNodeLayer:(YDGLOperationNodeLayer*_Nonnull)subLayer;
/**
 *  @author 9527, 16-04-20 20:58:27
 *
 *  like CALayer removeSubLayer
 *
 *  @param subLayer layer you want to remove
 *
 *  @since 1.0.0
 */
-(void)removeSubNodeLayer:(YDGLOperationNodeLayer*_Nonnull)subLayer;
/**
 *  @author 9527, 16-04-20 20:58:46
 *
 *  like CALayer removeFromSuperLayer
 *
 *  @since 1.0.0
 */
-(void)removeFromSuperNodeLayer;

@end


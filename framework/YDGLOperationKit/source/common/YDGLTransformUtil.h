//
//  YDGLTransformUtil.h
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/3/29.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import <Foundation/Foundation.h>
@import QuartzCore;
/**
 *  @author 许辉泽, 16-03-29 18:29:08
 *
 *  矩阵变换辅助类
 *
 *  @since 1.0.0
 */
@interface YDGLTransformUtil : NSObject

+(CATransform3D)Frustum:(CGFloat)left andRight:(CGFloat) right andBottom:(CGFloat) bottom andTop:(CGFloat)top andNearZ:(CGFloat)nearZ andFarZ:(CGFloat) farZ;
/**
 *  @author 许辉泽, 16-03-29 18:34:41
 *
 *  创建一个透明投影矩阵
 *
 *  @param fovy
 *  @param aspect
 *  @param nearZ
 *  @param farZ
 *
 *  @return
 *
 *  @since 1.0.0
 */
+(CATransform3D)Perspective:(CGFloat)fovy andAspect:(CGFloat) aspect andNearZ:(CGFloat)nearZ andFarZ:(CGFloat) farZ;

@end

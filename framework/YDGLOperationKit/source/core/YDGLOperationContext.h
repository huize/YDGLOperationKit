//
//  YDGLOperationContext.h
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/4/14.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import <Foundation/Foundation.h>

@import OpenGLES;
/**
 *  @author 9527, 16-04-14 14:02:47
 *
 *  manager EGALContext of YDGLOperationNode
 *
 *  @since 1.0.0
 */
@interface YDGLOperationContext : NSObject
/**
 *  @author 9527, 16-04-14 17:02:44
 *
 *  you should push a context before you call YDGLOperationNode every thing,and pop context when you exit viewcontroller or app
 *
 *  @since 1.0.0
 */
+(void)pushContext;
/**
 *  @author 9527, 16-04-14 17:05:02
 *
 *  get the last context did push
 *
 *  @return
 *
 *  @since 1.0.0
 */
+(EAGLContext*_Nullable)currentGLContext;
/**
 *  @author 9527, 16-04-14 17:03:31
 *
 *  if you call pushContext,you should call popContext at viewController dealloc
 *
 *  @since 1.0.0
 */
+(void)popContext;

@end

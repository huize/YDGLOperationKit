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

+(void)pushContext;

+(EAGLContext*_Nullable)currentGLContext;

+(void)popContext;

@end

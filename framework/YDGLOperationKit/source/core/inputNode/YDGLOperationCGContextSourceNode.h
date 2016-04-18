//
//  YDGLOperationCGContextSourceNode.h
//  YDGLOperationKit
//
//  Created by xuhuize on 16/4/16.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import <YDGLOperationKit/YDGLOperationKit.h>
/**
 *  @author 9527, 16-04-16 18:04:06
 *
 *  node content provide by CGContext
 */
@interface YDGLOperationCGContextSourceNode : YDGLOperationSourceNode

-(instancetype _Nonnull)initWithSize:(CGSize)size;
/**
 *  @author 9527, 16-04-18 17:28:41
 *
 *  get the CGContextRef to draw you content
 *
 *  @param drawBlock drawBlock description
 *
 *  @since 1.0.0
 */
-(void)commitCGContextTransaction:(void(^_Nullable)(CGContextRef _Nonnull))drawBlock;

@end

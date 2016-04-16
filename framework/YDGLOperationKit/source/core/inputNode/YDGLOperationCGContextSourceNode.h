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

-(instancetype)initWithSize:(CGSize)size;

-(void)clearContent;

-(void)drawCGPoint:(CGPoint)point;

-(void)drawCGRect:(CGRect)rect;
/**
 *  @author 9527, 16-04-16 18:04:15
 *
 *  upload the context content to the node
 */
-(void)commit;

@end

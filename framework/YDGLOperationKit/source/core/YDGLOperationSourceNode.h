//
//  GLOperation.h
//  LiveVideo
//
//  Created by 辉泽许 on 16/3/10.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationNode.h"

@interface YDGLOperationSourceNode :YDGLOperationNode

@property(nonatomic,assign) BOOL textureAvailable;//纹理是否可用

-(void)prepareForRender;

-(void)start;
/**
 *  @author 许辉泽, 16-04-09 16:26:54
 *
 *  mark the node content invalidate
 *
 *  @since 1.0.0
 */
-(void)setNeedDisplay;

@end

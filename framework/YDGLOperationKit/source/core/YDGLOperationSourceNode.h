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

/**
 *  @author 9527, 16-05-29 17:05:28
 *
 *  drive the node tree be traversals
 */
-(void)drive;
/**
 *  @author 许辉泽, 16-04-09 16:26:54
 *
 *  mark the node content invalidate
 *
 *  @since 1.0.0
 */
-(void)invalidateNodeContent;

-(void)bindTexture:(GLuint)textureId;

@end

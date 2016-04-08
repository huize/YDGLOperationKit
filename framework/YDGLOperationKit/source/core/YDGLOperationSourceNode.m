//
//  GLOperation.m
//  LiveVideo
//
//  Created by 辉泽许 on 16/3/10.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationSourceNode.h"

@implementation YDGLOperationSourceNode

-(void)start{
    
    //RunInNodeProcessQueue(^{
    
    [self activeGLContext:^{
        
        [self prepareForRender];
        
    }];
    
    [self renderIfCanWhenDependencyDone:self];
    
    self.textureAvailable=NO;
    
    //});
    
}

-(BOOL)canPerformTraversals{
    
    return self.textureAvailable;//纹理准备好之后才可以遍历
}

-(void)prepareForRender{
    
    
}

-(void)setTextureCoord{
    
    GLint location_texturecoord=glGetAttribLocation(_drawModel.program, [ATTRIBUTE_TEXTURE_COORDINATE UTF8String]);
    
    glEnableVertexAttribArray(location_texturecoord);
    
    glVertexAttribPointer(location_texturecoord, 2, GL_FLOAT, GL_FALSE,sizeof(GLfloat)*2,0);//纹理坐标
    
}

-(void)addDependency:(id<YDGLOperationNode>)operation{

    NSAssert(NO, @"YDGLOperationSourceNode must be as root Node");

}


@end

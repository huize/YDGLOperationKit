//
//  YDGLOperationBlendNode.m
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/4/12.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationBlendNode.h"
#import <objc/runtime.h>

@interface YDGLOperationBlendNode()

@property(nonatomic,assign)GLKMatrix4 projection;//

@property(nonatomic,assign)GLKMatrix4 modelview;//

@end

@implementation YDGLOperationBlendNode

- (instancetype)init
{
    self = [super init];
    if (self) {
 
        [self commonInitialization];
        
    }
    return self;
}

-(void)commonInitialization{

    

}

-(void)didSetInputSize:(CGSize)newInputSize{

    CGSize sizeInPixel=CGSizeMake(newInputSize.width,newInputSize.height);
    
    float aspect=sizeInPixel.width/sizeInPixel.height;
    float nearZ=sizeInPixel.height/2;
    
    float farZ=nearZ+100;
    
    GLKMatrix4 projection=GLKMatrix4MakePerspective(M_PI_2, aspect, nearZ, farZ);

    self.projection=projection;
    
    GLKMatrix4 modelview=GLKMatrix4Identity;
    
    modelview=GLKMatrix4Translate(modelview, 0.0, 0.0, -nearZ);
    
    modelview=GLKMatrix4Translate(modelview, -sizeInPixel.width/2, -sizeInPixel.height/2, 0.0);
    
    self.modelview=modelview;

}

-(void)addSubNode:(YDGLOperationNode*_Nonnull)operation atFrame:(CGRect)frame{

    [operation setFrame:frame];
    
    [self addDependency:operation];
    
}

-(void)drawFrameBuffer:(GLuint)frameBuffer inRect:(CGRect)rect{
    
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    
    glViewport(rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    glEnable(GL_BLEND);
    
    glDisable(GL_DEPTH_TEST);
    
    glUseProgram(_drawModel.program);
    
    for (int index=0; index<_dependency.count; index++) {
        
        YDGLOperationNode *subNode=_dependency[index];
        
        YDGLOperationNodeOutput *output=[_dependency[index] getOutput];

        //1.设置变换矩阵
        GLint location= glGetUniformLocation(_drawModel.program, [UNIFORM_MATRIX UTF8String]);
        
        GLKMatrix4 matrix=self.modelview;
        
        matrix=GLKMatrix4Translate(matrix, 0.0, 0.0, 0.0-0.01*index);//set z index
        
        matrix=GLKMatrix4Multiply(self.projection, matrix);
        
        float*mm=(float*)matrix.m;
        
        GLfloat* finalMatrix=malloc(sizeof(GLfloat)*16);
        
        for (int index=0; index<16; index++) {
            
            finalMatrix[index]=(GLfloat)mm[index];
            
        }
        
        glUniformMatrix4fv(location, 1, GL_FALSE, (const GLfloat*)finalMatrix);
        
        free(finalMatrix);
        
        //2.设置顶点坐标
        
        GLint location_position=glGetAttribLocation(_drawModel.program, [ATTRIBUTE_POSITION UTF8String]);
        
        
        CGRect frame=[subNode getFrame];
        
        if (CGRectIsEmpty(frame)) {
            
            frame=CGRectMake(0, 0, output.size.width, output.size.height);
            
        }
        
        CGSize size=frame.size;
        
        GLfloat vex[12]={
            
            frame.origin.x,frame.origin.y,0.0,//left bottom
            frame.origin.x+size.width,frame.origin.y,0.0,//right bottom
            frame.origin.x+size.width,frame.origin.y+size.height,0.0,//right top
            frame.origin.x,frame.origin.y+size.height,0.0,//left top
        };
        
        glEnableVertexAttribArray(location_position);//顶点坐标
        
        glVertexAttribPointer(location_position, 3, GL_FLOAT, GL_FALSE,sizeof(GLfloat)*3,vex);
        
        //3.设置纹理坐标
        
        glBindBuffer(GL_ARRAY_BUFFER, _drawModel.texture_vertices_buffer_obj);
        
        GLint location_texturecoord=glGetAttribLocation(_drawModel.program, [ATTRIBUTE_TEXTURE_COORDINATE UTF8String]);
        
        glEnableVertexAttribArray(location_texturecoord);
        
        glVertexAttribPointer(location_texturecoord, 2, GL_FLOAT, GL_FALSE,sizeof(GLfloat)*2,0);//纹理坐标
        
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        
        //4.设置纹理
        
        GLint location_s_texture=glGetUniformLocation(_drawModel.program, [UNIFORM_INPUTTEXTURE UTF8String]);
        
        glActiveTexture(GL_TEXTURE0+index);
        
        [YDGLOperationNode bindTexture:output.texture];
        
        glUniform1i ( location_s_texture,index);
        //5. draw
        glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _drawModel.indices_buffer_obj);
        
        GLsizei count=_drawModel.count_indices;
        
        count=count/4;
        
        for (int index=0; index<count; index++) {
            
            glDrawElements(_drawModel.drawStyle, 4, GL_UNSIGNED_BYTE,(GLvoid*)(index*4));
            
        }
        
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        
    }
    
    glDisable(GL_BLEND);
    
    //glEnable(GL_DEPTH_TEST);
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
}


@end


@implementation YDGLOperationNode(FrameSupport)

-(void)setFrame:(CGRect)frame{

    objc_setAssociatedObject(self, [@"frame" UTF8String],[NSValue valueWithCGRect:frame], OBJC_ASSOCIATION_RETAIN_NONATOMIC);

}

-(CGRect)getFrame{

    NSValue *frame= objc_getAssociatedObject(self, [@"frame" UTF8String]);
    
    return frame.CGRectValue;

}

@end


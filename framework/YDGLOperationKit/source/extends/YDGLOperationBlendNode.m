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
@property(nonatomic,assign)GLKMatrix4 view;//
@property(nonatomic,assign)GLKMatrix4 model; //subNode

@property(nonatomic,retain)NSMutableArray<YDGLOperationBlendNode*> *subNodes;

@end

@implementation YDGLOperationBlendNode

-(instancetype)initWithVertexShader:(NSString *)vertexShaderString andFragmentShader:(NSString *)fragmentShaderString{

    if (self=[super initWithVertexShader:vShaderStr andFragmentShader:fShaderStr]) {
        
        [self commonInitialization];
        
        return  self;
    }

    return  nil;
}

-(void)commonInitialization{

    
    _subNodes=[NSMutableArray array];
    
    _transform=GLKMatrix4Identity;
    
    //_transform=GLKMatrix4MakeScale(0.5, 0.5, 1.0);
    
    //_transform=GLKMatrix4Rotate(_transform, M_PI_4, 0.0, 0.0, 1.0);
    
}

-(void)willSetNodeSize:(CGSize *)newInputSize{

    CGSize sizeWillSet=*newInputSize;
    
    CGSize sizeInPixel=CGSizeMake(sizeWillSet.width,sizeWillSet.height);
    
    float aspect=sizeInPixel.width/sizeInPixel.height;
    float nearZ=sizeInPixel.height/2;
    
    float farZ=nearZ+100;
    
    GLKMatrix4 projection=GLKMatrix4MakePerspective(M_PI_2, aspect, nearZ, farZ);

    self.projection=projection;
    
    GLKMatrix4 view=GLKMatrix4Identity;
    
    view=GLKMatrix4Translate(view, 0.0, 0.0, -nearZ);
    
    view=GLKMatrix4Translate(view, -sizeInPixel.width/2, -sizeInPixel.height/2, 0.0);
    
    self.view=view;
    
    self.model=GLKMatrix4Identity;
    

}
-(void)drawFrameBuffer:(GLuint)frameBuffer inRect:(CGRect)rect{
    
    //1. draw self content
    
    [super drawFrameBuffer:frameBuffer inRect:rect];
    
    if (_subNodes.count<1)return;
    
    //2. draw subNodes
    
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    
    glViewport(rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
    
    glEnable(GL_BLEND);
    
    glDisable(GL_DEPTH_TEST);
    
    glUseProgram(_drawModel.program);
    
    for (int index=0; index<_subNodes.count; index++) {
        
        YDGLOperationBlendNode* subNode=_subNodes[index];
        
        [self drawSubNode:subNode widthIndex:index];
        
    }
    
    glDisable(GL_BLEND);
        
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
}

-(void)drawSubNode:(YDGLOperationBlendNode*_Nonnull)subNode widthIndex:(int)indexOfSubNode{
    
    YDGLOperationNodeOutput *output=[subNode getOutput];
    
    CGRect frame=subNode.frame;
    
    if (CGRectIsEmpty(frame)) {
        
        frame=CGRectMake(0, 0, output.size.width, output.size.height);
        
    }

    //1.设置变换矩阵
    GLint location= glGetUniformLocation(_drawModel.program, [UNIFORM_MATRIX UTF8String]);
    
    GLKMatrix4 modelMatrix=self.model;
    
    modelMatrix=GLKMatrix4Translate(modelMatrix, CGRectGetMidX(frame), CGRectGetMidY(frame), 0);//subnode center as (0,0,0)
    
    modelMatrix=GLKMatrix4Multiply(modelMatrix,_transform);//multipy transform
    
    modelMatrix=GLKMatrix4Translate(modelMatrix, 0.0, 0.0, 0.0-0.01*indexOfSubNode);//set z index
    
    modelMatrix=GLKMatrix4Translate(modelMatrix, -CGRectGetMidX(frame), -CGRectGetMidY(frame), 0);
    
    GLKMatrix4 mvpMatrix=GLKMatrix4Multiply(self.view, modelMatrix);
    mvpMatrix=GLKMatrix4Multiply(self.projection, mvpMatrix);
    
    float*mm=(float*)mvpMatrix.m;
    
    GLfloat* const finalMatrix=malloc(sizeof(GLfloat)*16);
    
    for (int index=0; index<16; index++) {
        
        finalMatrix[index]=(GLfloat)mm[index];
        
    }
    
    glUniformMatrix4fv(location, 1, GL_FALSE, (const GLfloat*)finalMatrix);
    
    free(finalMatrix);
    
    //2.设置顶点坐标
    
    GLint location_position=glGetAttribLocation(_drawModel.program, [ATTRIBUTE_POSITION UTF8String]);
    
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
    
    glActiveTexture(GL_TEXTURE0);
    
    [YDGLOperationNode bindTexture:output.texture];
    
    glUniform1i ( location_s_texture,0);
    //5. draw
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _drawModel.indices_buffer_obj);
    
    GLsizei count=_drawModel.count_indices;
    
    count=count/4;
    
    for (int index=0; index<count; index++) {
        
        glDrawElements(_drawModel.drawStyle, 4, GL_UNSIGNED_BYTE,(const GLvoid*)(index*4*sizeof(GLubyte)));
        
    }
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    
}

-(BOOL)innerAllSubNodeDone{

    if (self.subNodes.count==0)return YES;
    
    __block BOOL done=YES;
    
    [self.subNodes enumerateObjectsUsingBlock:^(YDGLOperationBlendNode*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        YDGLOperationNodeOutput *output=[obj getOutput];
        
        if (output==nil) {
            
            done=NO;
            *stop=YES;
            
        }
    }];
    
    
    return done;


}


#pragma -mark override protected method

-(void)addDependency:(id<YDGLOperationNode>)operation{

    [super addDependency:operation];
    
    if (_dependency.count>1) {
        
        NSAssert(NO, @"because dependency node provide the blend node content,so only support one dependency");
    }

}

-(BOOL)canPerformTraversals{
    
   return [super canPerformTraversals]&&[self innerAllSubNodeDone];
}


#pragma -mark public api

-(void)addSubNode:(YDGLOperationBlendNode *)subNode{

    [_subNodes addObject:subNode];
    
    subNode.superNode=self;

}

-(void)dealloc{

    [_subNodes removeAllObjects];

}

@end


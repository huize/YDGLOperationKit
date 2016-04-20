//
//  YDGLOperationBlendNode.m
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/4/12.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationNodeLayer.h"
#import <objc/runtime.h>

/**
 *  @author 9527, 16-04-19 16:56:38
 *
 *  fragment shader use for draw subNode
 *
 *  @return
 *
 *  @since <#1.0.0#>
 */
static NSString *_Nonnull const fBlendShaderStr=SHADER_STRING(
                                                         precision mediump float;
                                                         
                                                         varying highp vec2 textureCoordinate;
                                                         
                                                         uniform sampler2D inputImageTexture;
                                                              
                                                         uniform float opaticy;//opaticy,0.0~1.0
                                                         
                                                         void main()
                                                         {
                                                             float fixedOpaticy=opaticy;
                                                             
                                                             if(fixedOpaticy<0.0)fixedOpaticy=0.0;
                                                             
                                                             if(fixedOpaticy>1.0)fixedOpaticy=1.0;
                                                             
                                                             vec4 color=texture2D(inputImageTexture, textureCoordinate.xy);
                                                             
                                                             gl_FragColor=color*fixedOpaticy;
                                                         }
                                                         );

@interface YDGLOperationNodeLayer()

@property(nonatomic,assign)GLKMatrix4 projection;//
@property(nonatomic,assign)GLKMatrix4 view;//
@property(nonatomic,assign)GLKMatrix4 model; //subNode

@property(nonatomic,retain)NSMutableArray<YDGLOperationNodeLayer*> *subNodes;

@end

@implementation YDGLOperationNodeLayer


#pragma -mark override protected method


-(instancetype)initWithVertexShader:(NSString *)vertexShaderString andFragmentShader:(NSString *)fragmentShaderString{

    if (self=[super initWithVertexShader:vShaderStr andFragmentShader:fBlendShaderStr]) {
        
        [self commonInitialization];
        
        return  self;
    }

    return  nil;
}

-(void)commonInitialization{

    _subNodes=[NSMutableArray array];
    
    _transform=GLKMatrix4Identity;
    
    [self setOpaticy:1.0f];
    
    //_transform=GLKMatrix4MakeScale(0.5, 0.5, 1.0);
    
    //_transform=GLKMatrix4Rotate(_transform, M_PI_4, 0.0, 0.0, 1.0);
    
}

-(void)willSetNodeSize:(CGSize *)newInputSize{

    //force set the node size equalTo frame size
    
    if (CGSizeEqualToSize(_size, CGSizeZero)==NO) {
        
        *newInputSize=CGSizeMake(_size.width, _size.height);

    }
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
    
    glUseProgram(_drawModel.program);
    
    float opaticy=_opaticy;
    
    GLint location_opaticy=[_drawModel locationOfUniform:@"opaticy"];
    
    glUniform1f(location_opaticy, opaticy);

    [super drawFrameBuffer:frameBuffer inRect:rect];
    
    if (_subNodes.count<1)return;
    
    //2. draw subNodes
    
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    
    glViewport(rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
    
    glEnable(GL_BLEND);
    
    //https://www.opengl.org/wiki/Blending
    //premultiplied alpha blending
    
    //notice:use follow onfig will make export image something wrong
    //glBlendEquationSeparate(GL_FUNC_ADD, GL_FUNC_ADD);
    //glBlendFuncSeparate(GL_ONE, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ZERO);
    
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    glDisable(GL_DEPTH_TEST);
    
    glUseProgram(_drawModel.program);
    
    for (int index=0; index<_subNodes.count; index++) {
        
        YDGLOperationNodeLayer* subNode=_subNodes[index];
        
        [self drawSubNode:subNode widthIndex:index];
        
    }
    
    glDisable(GL_BLEND);
        
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
}

-(void)drawSubNode:(YDGLOperationNodeLayer*_Nonnull)subNode widthIndex:(int)indexOfSubNode{
    
    YDGLOperationNodeOutput *output=[subNode getOutput];
    
    float opaticy=subNode.opaticy;
    
    GLint location_opaticy=[_drawModel locationOfUniform:@"opaticy"];
    
    glUniform1f(location_opaticy, opaticy);
    
    GLKMatrix4 subTransform=subNode.transform;
    
    CGRect frame=subNode.frame;
    
    if (CGRectIsEmpty(frame)) {
        
        frame=CGRectMake(0, 0, output.size.width, output.size.height);
        
    }
    //1.设置变换矩阵
    
    GLint location=[_drawModel locationOfUniform:UNIFORM_MATRIX];
    
    GLKMatrix4 modelMatrix=self.model;
    
    modelMatrix=GLKMatrix4Translate(modelMatrix, CGRectGetMidX(frame), CGRectGetMidY(frame), 0);//subnode center as (0,0,0)
    
    modelMatrix=GLKMatrix4Multiply(modelMatrix,subTransform);//multipy transform
    
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
        
    GLint location_s_texture=[_drawModel locationOfUniform:UNIFORM_INPUTTEXTURE];
    
    glActiveTexture(GL_TEXTURE0);
    
    [YDGLOperationNode bindTexture:output.texture];
    
    glUniform1i ( location_s_texture,0);
    //5. draw    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _drawModel.indices_buffer_obj);
    
    GLsizei count=_drawModel.count_indices;
    
    count=count/4;
    
    for (int index=0; index<count; index++) {
        
        glDrawElements(_drawModel.drawStyle, 4, GL_UNSIGNED_BYTE,(const GLvoid*)(index*4*sizeof(GLubyte)));
        
    }
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    
}

-(void)addDependency:(id<YDGLOperationNode>)operation{

    [super addDependency:operation];
    
    if (_dependency.count>1) {
        
        NSAssert(NO, @"because dependency node provide the blend node content,so only support one dependency");
    }

}

-(BOOL)canPerformTraversals{
    
   return [super canPerformTraversals]&&[self innerAllSubNodeDone];
}


#pragma -mark private method

-(BOOL)innerAllSubNodeDone{
    
    if (self.subNodes.count==0)return YES;
    
    __block BOOL done=YES;
    
    [self.subNodes enumerateObjectsUsingBlock:^(YDGLOperationNodeLayer*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        YDGLOperationNodeOutput *output=[obj getOutput];
        
        if (output==nil) {
            
            done=NO;
            *stop=YES;
            
        }
    }];
    
    
    return done;
    
    
}

-(void)setSuperNodeLayer:(YDGLOperationNodeLayer * _Nullable)superNodeLayer{

    _superNodeLayer=superNodeLayer;

}

#pragma -mark public api

-(void)setOpaticy:(float)opaticy{

    _opaticy=opaticy;
    
    [self setFloat:_opaticy forUniformName:@"opaticy"];

}

-(void)addSubNodeLayer:(YDGLOperationNodeLayer *)subNode{

    NSAssert(subNode.superNodeLayer==nil, @"YDGLOperationNodeLayer must be have one superLayer");
    
    [_subNodes addObject:subNode];

    subNode.superNodeLayer=self;

}

-(void)removeSubNodeLayer:(YDGLOperationNodeLayer *)subNode{

    if ([_subNodes containsObject:subNode]) {
        
        [_subNodes removeObject:subNode];
        
        subNode.superNodeLayer=nil;
    }
    
}

-(void)removeFromSuperNodeLayer{

    if (_superNodeLayer) {
        
        [_superNodeLayer removeSubNodeLayer:self];
        
        _superNodeLayer=nil;
        
    }

}

-(void)setFrame:(CGRect)frame{

    _frame=frame;
    
    _size=frame.size;

}

-(void)dealloc{

    [_subNodes removeAllObjects];

}

@end


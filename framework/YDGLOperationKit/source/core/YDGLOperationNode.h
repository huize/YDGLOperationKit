//
//  GLOperationLayer.h
//  test_openges
//
//  Created by 辉泽许 on 16/3/11.
//  Copyright © 2016年 yifan. All rights reserved.
//

@import OpenGLES.ES2;

@import QuartzCore;

@import UIKit;

@import Foundation;

#import "ShaderLoader.h"

#import "ESTransform.h"

#import "YDDrawModel.h"

/**
 *  @author 许辉泽, 16-03-12 15:40:08
 *
 *  GLOperation的输出
 *
 *  @since 1.0.0
 */
@interface YDGLOperationNodeOutput : NSObject

@property(nonatomic,assign) GLuint texture;//

@property(nonatomic,assign)GLuint frameBuffer;

@property(nonatomic,assign) CGSize size;//

@property(nonatomic,nullable,assign)CVPixelBufferRef pixelBuffer;

@end


/**
 *  @author 许辉泽, 16-03-11 17:05:38
 *
 *  OpenGL 操作协议
 *
 *  @since 1.0.0
 */
@protocol YDGLOperationNode <NSObject>
/**
 *  @author 许辉泽, 16-03-12 14:57:43
 *
 *  开始渲染
 *
 *  @since 1.0.0
 */
-(void)render;

/**
 *  @author 许辉泽, 16-03-12 14:57:54
 *
 *  添加依赖
 *
 *  @param operation 该操作所依赖的操作
 *
 *  @since 1.0.0
 */
-(void)addDependency:(id<YDGLOperationNode>_Nonnull)operation;
/**
 *  @author 许辉泽, 16-03-12 15:00:01
 *
 *
 *
 *  @param nextOperation 下一项操作
 *
 *  @since 1.0.0
 */
-(void)addNextOperation:(id<YDGLOperationNode>_Nonnull)nextOperation;
/**
 *  @author 许辉泽, 16-03-12 15:00:21
 *
 *  该操作的输出
 *
 *  @return
 *
 *  @since 1.0.0
 */
-(YDGLOperationNodeOutput*_Nullable)getOutput;
/**
 *  @author 许辉泽, 16-03-12 15:00:34
 *
 *  通知 doneOperation 已经完成.
 *  注意:在render方法里面最好都应该调用notifyDependencyDone,这样其他依赖于该operation的operation才能进行操作
 *  @param doneOperation 已经完成的dependency
 *
 *  @since 1.0.0
 */
-(void)notifyDependencyDone:(id<YDGLOperationNode>_Nonnull)doneOperation;


@end

static NSString  *_Nonnull const vShaderStr=SHADER_STRING(
                                                          attribute vec3 position;
                                                          attribute vec2 inputTextureCoordinate;
                                                          varying   vec2 textureCoordinate;
                                                          uniform  mat4 u_mvpMatrix;
                                                          void main()
                                                          {
                                                              gl_Position =u_mvpMatrix*vec4(position,1.0);
                                                              
                                                              textureCoordinate = inputTextureCoordinate.xy;
                                                          }
                                                          
                                                          );

static NSString *_Nonnull const fShaderStr=SHADER_STRING(
                                                         precision mediump float;
                                                         
                                                         varying highp vec2 textureCoordinate;
                                                         
                                                         uniform sampler2D inputImageTexture;
                                                         
                                                         void main()
                                                         {
                                                             
                                                             gl_FragColor = texture2D(inputImageTexture, textureCoordinate.xy);
                                                             
                                                             
                                                         }
                                                         );


static NSString *_Nonnull  const UNIFORM_MATRIX=@"u_mvpMatrix";
static NSString *_Nonnull  const UNIFORM_INPUTTEXTURE=@"inputImageTexture";
static NSString *_Nonnull  const UNIFORM_POSITION=@"position";
static NSString *_Nonnull  const UNIFORM_TEXTURE_COORDINATE=@"inputTextureCoordinate";

@protocol YDGLOperationTextureLoaderDelegate <NSObject>

@required
-(NSString*_Nonnull)textureUniformNameAtIndex:(NSInteger)index;

-(NSString*_Nonnull)textureCoordUniformNameAtIndex:(NSInteger)index;

@end

/**
 *  @author 许辉泽, 16-03-11 17:10:21
 *
 *  每一次的OpenGL操作都可以抽象成OperationLayer
 *
 *  @since 1.0.0
 */

@interface YDGLOperationNode : NSObject<YDGLOperationNode,YDGLOperationTextureLoaderDelegate>
{
    
@protected
    
    GLuint _frameBuffer,_renderTexture_out;
    
    CGSize _size;
    
    ESMatrix _mvpMatrix;
    
    YDDrawModel _drawModel;
    
    NSMutableArray<id<YDGLOperationNode>> *_dependency;
    
    NSMutableArray<id<YDGLOperationNode>> *_nextOperations;
    
    __weak id<YDGLOperationTextureLoaderDelegate> _Nonnull _textureLoaderDelegate;
    
    EAGLContext *_glContext;
    
}

@property(nonatomic,nullable,copy) void(^operationCompletionBlock)(YDGLOperationNodeOutput*_Nonnull);//

-(instancetype _Nullable)initWithVertexShader:(NSString*_Nonnull)vertexShaderString andFragmentShader:(NSString*_Nonnull)fragmentShaderString;

-(instancetype _Nullable)initWithFragmentShader:(NSString*_Nonnull)fragmentShaderString;

+(EAGLContext*_Nonnull)getGLContext;

+(dispatch_queue_t _Nonnull)getWorkQueue;

//-------------------------
/**
 *  @author 许辉泽, 16-03-12 17:36:46
 *
 *  加载当前program的纹理,子类可以重载它来自定义加载纹理
 *  @param program 当前使用的program
 *  @since 1.0.0
 */
-(void)setupTextureForProgram:(GLuint)program;

//opengl operation
- (void)setFloat:(GLfloat)newFloat forUniformName:(NSString *_Nonnull)uniformName;

-(void)activeGLContext:(void(^_Nonnull)(void))block;


@end





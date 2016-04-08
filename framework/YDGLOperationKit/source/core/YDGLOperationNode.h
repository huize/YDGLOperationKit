//
//  GLOperationLayer.h
//  test_openges
//
//  Created by 辉泽许 on 16/3/11.
//  Copyright © 2016年 yifan. All rights reserved.
//

@import GLKit;

@import OpenGLES.ES2;

@import QuartzCore;

@import UIKit;

@import Foundation;

#import "ShaderLoader.h"

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

@required
/**
 *  @author 许辉泽, 16-03-17 16:39:58
 *
 *  销毁节点,导致不可再用
 *
 *  @since 1.0.0
 */
-(void)destory;

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
 *  @param doneOperation 已经完成的dependency
 *  注意,node必须在这里检查所有的依赖时候已经准备好了,
 *  如果准备好了,则应该开始进行渲染,然后通知下一个节点
 *
 *
 *  @since 1.0.0
 */

-(void)renderIfCanWhenDependencyDone:(id<YDGLOperationNode>_Nonnull)doneOperation;

/**
 *  @author 许辉泽, 16-03-18 13:53:26
 *
 *  锁节点,将不再收到输入
 *  注意:目前的实现是一个递归操作,会锁住所有的dependency 节点
 *
 *  @since 1.0.0
 */
-(void)lock;
/**
 *  @author 许辉泽, 16-03-18 13:54:41
 *
 *  解锁节点
 *
 *  @since 1.0.0
 */
-(void)unlock;

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
static NSString *_Nonnull  const ATTRIBUTE_POSITION=@"position";
static NSString *_Nonnull  const ATTRIBUTE_TEXTURE_COORDINATE=@"inputTextureCoordinate";

@protocol YDGLOperationTextureLoaderDelegate <NSObject>

@required
-(NSString*_Nonnull)textureUniformNameAtIndex:(NSInteger)index;

-(NSString*_Nonnull)textureCoordAttributeNameAtIndex:(NSInteger)index;

@end


typedef void(^OperationCompletionBlock)(YDGLOperationNodeOutput*_Nonnull);

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
    
    GLKMatrix4 _mvpMatrix;
    
    YDDrawModel *_drawModel;
    
    NSMutableArray<id<YDGLOperationNode>> *_dependency;
    
    NSMutableArray<id<YDGLOperationNode>> *_nextOperations;
    
    __weak id<YDGLOperationTextureLoaderDelegate> _Nonnull _textureLoaderDelegate;
    
    EAGLContext *_glContext;
}

@property(nonatomic,nullable,copy)OperationCompletionBlock completionBlock;

@property(nonatomic,readonly,getter=isLocked) BOOL locked;

-(instancetype _Nullable)initWithVertexShader:(NSString*_Nonnull)vertexShaderString andFragmentShader:(NSString*_Nonnull)fragmentShaderString;

-(instancetype _Nullable)initWithFragmentShader:(NSString*_Nonnull)fragmentShaderString;

+(EAGLContext*_Nonnull)getGLContext;

+(void)bindTexture:(GLuint)textureId;

//-------------------------
/**
 *  @author 许辉泽, 16-03-12 17:36:46
 *
 *  加载当前program的纹理,子类可以重载它来自定义加载纹理
 *  @param program 当前使用的program
 *  @since 1.0.0
 */
-(void)setupTextureForProgram:(GLuint)program;
/**
 *  @author 许辉泽, 16-03-24 15:28:13
 *
 *  该节点的渲染过程
 *
 *  @param frameBuffer 渲染缓冲区
 *  @param CGRect      区域
 *
 *  @since 1.0.0
 */
-(void)drawFrameBuffer:(GLuint)frameBuffer inRect:(CGRect)rect;

-(void)activeGLContext:(void(^_Nonnull)(void))block;

//opengl operation
- (void)setFloat:(GLfloat)newFloat forUniformName:(NSString *_Nonnull)uniformName;

- (void)setInt:(GLint)newInt forUniformName:(NSString *_Nonnull)uniformName;

- (void)setBool:(GLboolean)newBool forUniformName:(NSString *_Nonnull)uniformName;

/**
 *  @author 许辉泽, 16-03-19 16:14:32
 *
 *  该node的size 发生改变了
 *
 *  @param newInputSize node 最新的size
 *
 *  @since 1.0.0
 */
-(void)didSetInputSize:(CGSize)newInputSize;

/**
 *  @author 许辉泽, 16-03-18 17:56:56
 *
 * 绕Z轴旋转
 *
 *  @param angle 90,180,270
 *
 *  @since 1.0.0
 */
-(void)rotateAtZ:(int)angle;
/**
 *  @author 许辉泽, 16-03-18 21:57:48
 *
 *  绕Y轴旋转
 *
 *  @param angle
 *
 *  @since 1.0.0
 */
-(void)rotateAtY:(int)angle;

/**
 *  @author 许辉泽, 16-04-01 15:15:11
 *
 *  是否可以开始遍历节点了,默认实现是所有的dependency完成之后的情况下才返回YES
 *
 *  @return
 *
 *  @since 1.0.0
 */
-(BOOL)canPerformTraversals;

@end





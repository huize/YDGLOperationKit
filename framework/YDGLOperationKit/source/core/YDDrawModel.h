//
//  DrawModel.h
//  test_openges
//
//  Created by 辉泽许 on 16/1/14.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import <Foundation/Foundation.h>

@import OpenGLES.ES2;

@class YDGLProgram;

/**
 *  @author 许辉泽, 16-01-14 20:18:22
 *
 *  数组的简易封装
 *
 * 
 */
struct ArrayWrapper {
    
    const void *pointer;
    
    const GLsizeiptr size;
    
    const int count;
    
};


/**
 *  @author 许辉泽, 16-01-14 15:28:23
 *
 *  绘制模型
 *
 *
 */
@interface YDDrawModel : NSObject

@property(nonatomic,readonly,assign,getter=getRealProgram) GLuint program;//

@property(nonatomic,assign,readonly) GLuint vertices_buffer_obj;//顶点数组缓存对象

@property(nonatomic,assign,readonly) GLuint texture_vertices_buffer_obj;//纹理坐标缓存对象

@property(nonatomic,assign,readonly) GLuint indices_buffer_obj;//索引数组缓存对象

@property(nonatomic,assign,readonly) int count_vertices;//顶点数组元素个数

@property(nonatomic,assign,readonly) int count_texture_vertices;//纹理坐标数组元素的个数

@property(nonatomic,assign,readonly) int count_indices;//索引数组元素的个数

@property(nonatomic,assign,readonly) GLenum drawStyle;//

-(void)setvShaderSource:(const char*)vSource andfShaderSource:(const char*)fSource;


@property(nonatomic,readonly)NSDictionary<NSString*,NSNumber*> *uniformDictionary;

@property(nonatomic,readonly)NSDictionary<NSString*,NSNumber*> *attributeDictionary;

/**
 *  @author 许辉泽, 16-03-18 14:07:09
 *
 *  加载指定矩形顶点,必须左下角开始,逆时针顺序
 *
 *  @param vertices_position
 *
 *  @since 1.0.0
 */
-(void)loadSquareVex:(const GLfloat[12])vertices_position;

/**
 *  @author 许辉泽, 16-03-21 16:04:32
 *
 *
 *
 *  @param vertices_position 顶点坐标
 *  @param textureCoord      纹理坐标
 *
 *  @since 1.0.0
 *
 *注意:左下角开始,逆时针顺序,GL_TRIANGLE_FAN 方式,必须是这种顺序
 *
 */
-(void)loadSquareVex:(const GLfloat [12])vertices_position andTextureCoord:(const GLfloat[8])textureCoord;

/**
 *  @author 许辉泽, 16-03-11 16:29:39
 *
 *  加载矩形顶点
 *
 *  @since 1.0.0
 */
-(void)loadSquareVex;
/**
 *  @author 许辉泽, 16-03-11 16:29:56
 *
 *  加载立方体顶点
 *
 *  @since 1.0.0
 */
-(void)loadCubeVex;
/**
 *  @author 许辉泽, 16-03-17 21:56:21
 *
 *  查询该program attribute的位置
 *
 *  @param attributeName
 *
 *  @return
 *
 *  @since 1.0.0
 */
//-(GLint)locationOfAttribute:(NSString*_Nonnull)attributeName;
/**
 *  @author 许辉泽, 16-03-17 21:56:43
 *
 *  查询该program 统一变量的位置
 *
 *  @param uniformName
 *
 *  @return
 *
 *  @since 1.0.0
 */
-(GLint)locationOfUniform:(NSString*_Nonnull)uniformName;

@end


@interface YDGLProgram : NSObject

@property(nonatomic,assign,readonly)GLuint program;

@property(nonatomic,assign,readonly)GLuint vShader;

@property(nonatomic,assign,readonly)GLuint fShader;

-(instancetype)initWithVertexString:(const char *)vSharderSource andFragmentString:(const char *)fShaderSource;

@end


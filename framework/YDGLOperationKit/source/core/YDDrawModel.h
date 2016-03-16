//
//  DrawModel.h
//  test_openges
//
//  Created by 辉泽许 on 16/1/14.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import <Foundation/Foundation.h>

@import OpenGLES.ES2;

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

@property(nonatomic,readonly,assign) GLuint program;//

@property(nonatomic,assign) GLuint vertices_buffer_obj;//顶点数组缓存对象

@property(nonatomic,assign) GLuint texture_vertices_buffer_obj;//纹理坐标缓存对象

@property(nonatomic,assign) GLuint indices_buffer_obj;//索引数组缓存对象

@property(nonatomic,assign) int count_vertices;//顶点数组元素个数

@property(nonatomic,assign) int count_texture_vertices;//纹理坐标数组元素的个数

@property(nonatomic,assign) int count_indices;//索引数组元素的个数

@property(nonatomic,assign) GLenum drawStyle;//

-(void)setvShaderSource:(const char*)vSource andfShaderSource:(const char*)fSource;
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

@end

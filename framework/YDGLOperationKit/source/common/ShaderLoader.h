//
//  ShaderLoader.h
//  test_openges
//
//  Created by 辉泽许 on 16/1/14.
//  Copyright © 2016年 yifan. All rights reserved.
//

#ifndef ShaderLoader_h
#define ShaderLoader_h

#include <stdio.h>
#include <stdlib.h>

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

#define GLSLVERSION #version 300 es \n
/**
 *  @author 许辉泽, 16-01-14 13:27:51
 *
 *  编译着色器
 *
 *  @param type      着色器类型 GL_VERTEX_SHADER GL_FRAGMENT_SHADER
 *  @param shaderSrc 着色器源码
 *
 *  @return
 *
 *  @since
 */
GLuint LoadShader(GLenum type,const char *shaderSrc);
/**
 *  @author 许辉泽, 16-01-14 13:29:25
 *
 *  使用顶点着色器源码和片元着色器源码创建一段程序
 *
 *  @param vShaderSource 顶点着色器源码
 *  @param fShaderSource 片元着色器源码
 *
 *  @return 
 *
 *  @since <#1.0.2#>
 */
GLuint LinkPorgram(const char* const vShaderSource,const char * const fShaderSource);

GLuint LinkPorgramWithShader(GLuint vShader,GLuint fShader);

#endif /* ShaderLoader_h */



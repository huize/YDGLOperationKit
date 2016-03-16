//
//  ShaderLoader.c
//  test_openges
//
//  Created by 辉泽许 on 16/1/14.
//  Copyright © 2016年 yifan. All rights reserved.
//

#include "ShaderLoader.h"

GLuint LoadShader(GLenum type,const char *shaderSrc){
    
    GLuint shader;
    GLint compiled;
    
    shader=glCreateShader(type);
    
    if (shader==0) {
        
        return  0;
    }
    
    glShaderSource(shader, 1, &shaderSrc, NULL);
    
    glCompileShader(shader);
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    
    if (!compiled) {
        
        GLint infoLen=0;
        
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
        
        if (infoLen>1) {
            
            char *infoLog=calloc(1,sizeof(char)*infoLen);
            
            glGetShaderInfoLog(shader, infoLen, NULL, infoLog);
            
            printf("error compiling shader:\n%s\n",infoLog);
            
            free(infoLog);
            
            
        }
        
        glDeleteShader(shader);
        
        return 0;
    }
    
    return  shader;
    
}


GLuint LinkPorgram(const char* const vShaderSource,const char * const fShaderSource){
    
    GLuint vertexShader=LoadShader(GL_VERTEX_SHADER,vShaderSource);
    
    GLuint fragmentShader=LoadShader(GL_FRAGMENT_SHADER,fShaderSource);
    
    GLuint programObject;
    
    programObject=glCreateProgram();
    
    if (programObject==0) {
        
        return 0;
    }
    
    glAttachShader(programObject, vertexShader);
    
    glAttachShader(programObject, fragmentShader);
    
    glLinkProgram(programObject);
    
    GLint linked;
    
    glGetProgramiv(programObject, GL_LINK_STATUS, &linked);
    
    if (!linked) {
        
        GLint infoLen=0;
        
        glGetProgramiv(programObject, GL_INFO_LOG_LENGTH, &infoLen);
        
        if (infoLen>1) {
            
            char *infoLog=malloc(sizeof(char)*infoLen);
            
            glGetProgramInfoLog(programObject, infoLen, NULL, infoLog);
            
            printf("error linking program:\n%s\n",infoLog);
            
            free(infoLog);
        }
        
        glDeleteProgram(programObject);
        
        return 0;
        
    }
    
    return programObject;
    
}





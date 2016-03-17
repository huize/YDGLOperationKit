//
//  DrawModel.m
//  test_openges
//
//  Created by 辉泽许 on 16/1/14.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDDrawModel.h"
#import "ShaderLoader.h"

@interface YDDrawModel(){

}

@end

@implementation YDDrawModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

-(void)setvShaderSource:(const char *)vSource andfShaderSource:(const char *)fSource{

    GLint program=LinkPorgram(vSource, fSource);
    
    glDeleteProgram(_program);
    //TODO:不需要delete shader?
    _program=program;

}
/**
 *  @author 许辉泽, 16-01-14 20:18:45
 *
 *  @param vertices        顶点数据
 *  @param textureVertices 纹理坐标数据
 *  @param indices         索引数据
 *  @param drawModel       绘制方式
 *
 */
-(void)setVertices:(struct ArrayWrapper)vertices andTextureVertices:(struct ArrayWrapper)textureVertices andIndices:(struct ArrayWrapper)indices andDrawStyle:(GLenum)drawModel{
    
    GLuint* bufferId=malloc(sizeof(GLuint)*3);
    
    glGenBuffers(3, bufferId);
    
    glBindBuffer(GL_ARRAY_BUFFER, bufferId[0]);
    
    glBufferData(GL_ARRAY_BUFFER, vertices.size, vertices.pointer, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ARRAY_BUFFER, bufferId[1]);
    
    glBufferData(GL_ARRAY_BUFFER, textureVertices.size, textureVertices.pointer, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, bufferId[2]);
    
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.size, indices.pointer, GL_DYNAMIC_DRAW);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    _vertices_buffer_obj=bufferId[0];
    
    _count_vertices=vertices.count;
    
    _texture_vertices_buffer_obj=bufferId[1];
    
    _count_texture_vertices=textureVertices.count;
    
    _indices_buffer_obj=bufferId[2];
    
    _count_indices=indices.count;
    
    _drawStyle=drawModel;
    
}


-(void)loadSquareVex{
    
    const GLfloat vertices_position[]={
        
        -1.0,-1.0,0.0,
        
        1.0,-1.0,0.0,
        
        1.0,1.0,0.0,
        
        -1.0,1.0,0.0,
        
    };
    
    const GLubyte indices_position[]={
        
        0,1,2,3,
        
    };
    
    const GLfloat vertices_texture[]={
        
        0.0,0.0, 1.0,0.0, 1.0,1.0, 0.0,1.0,
        
    };
    
    struct ArrayWrapper vertices_wrapper={vertices_position,sizeof(vertices_position),sizeof(vertices_position)/sizeof(GLfloat)};
    struct ArrayWrapper texturecoord_warpper={vertices_texture,sizeof(vertices_texture),sizeof(vertices_texture)/sizeof(GLfloat)};
    struct ArrayWrapper indices_warpper={indices_position,sizeof(indices_position),sizeof(indices_position)/sizeof(GLubyte)};
    
    [self setVertices:vertices_wrapper andTextureVertices:texturecoord_warpper andIndices:indices_warpper andDrawStyle:GL_TRIANGLE_FAN];
    
}


-(void)loadCubeVex{
    
    static const GLfloat vertices_position[]={
        
        0.0,0.0,1.0, 0.0,1.0,1.0, 0.0,1.0,0.0, 0.0,0.0,0.0,//1,2,3,0,
        
        0.0,0.0,0.0, 0.0,1.0,0.0, 1.0,1.0,0.0, 1.0,0.0,0.0,//0,3,5,4
        
        1.0,0.0,0.0, 1.0,1.0,0.0, 1.0,1.0,1.0, 1.0,0.0,1.0,//4,5,7,6
        
        0.0,0.0,1.0, 1.0,0.0,1.0, 1.0,1.0,1.0, 0.0,1.0,1.0,//1,6,7,2
        
        0.0,1.0,1.0, 1.0,1.0,1.0, 1.0,1.0,0.0, 0.0,1.0,0.0,//2,7,5,3,
        
        0.0,0.0,0.0, 1.0,0.0,0.0, 1.0,0.0,1.0, 0.0,0.0,1.0,//0,4,6,1
        
        
    };
    
    static const GLubyte indices_position[]={
        
        0,1,2,3,
        4,5,6,7,
        8,9,10,11,
        12,13,14,15,
        16,17,18,19,
        20,21,22,23
        
    };
    
    static const GLfloat vertices_texture[]={
        
        1.0,0.0, 1.0,1.0, 0.0,1.0, 0.0,0.0,
        1.0,0.0, 1.0,1.0, 0.0,1.0, 0.0,0.0,
        1.0,0.0, 1.0,1.0, 0.0,1.0, 0.0,0.0,
        0.0,0.0, 1.0,0.0, 1.0,1.0, 0.0,1.0,
        0.0,0.0, 1.0,0.0, 1.0,1.0, 0.0,1.0,
        0.0,0.0, 1.0,0.0, 1.0,1.0, 0.0,1.0,
        
    };
    
    struct ArrayWrapper vertices_wrapper={vertices_position,sizeof(vertices_position),sizeof(vertices_position)/sizeof(GLfloat)};
    struct ArrayWrapper texturecoord_warpper={vertices_texture,sizeof(vertices_texture),sizeof(vertices_texture)/sizeof(GLfloat)};
    struct ArrayWrapper indices_warpper={indices_position,sizeof(indices_position),sizeof(indices_position)/sizeof(GLubyte)};
    
    [self setVertices:vertices_wrapper andTextureVertices:texturecoord_warpper andIndices:indices_warpper andDrawStyle:GL_TRIANGLE_FAN];
    
}



-(void)dealloc{

    NSLog(@"drawModel 已经销毁了");
    
    glDeleteBuffers(1, &_vertices_buffer_obj);
    glDeleteBuffers(1, &_texture_vertices_buffer_obj);
    glDeleteBuffers(1, &_indices_buffer_obj);
    
    glDeleteProgram(_program);
    
}


@end

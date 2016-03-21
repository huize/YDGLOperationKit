//
//  DrawModel.m
//  test_openges
//
//  Created by 辉泽许 on 16/1/14.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDDrawModel.h"
#import "ShaderLoader.h"

@interface YDDrawModel()

@property(nonatomic,nullable,retain) NSMutableDictionary *uniformDictionary;//

@property(nonatomic,nullable,retain) NSMutableDictionary *attributeDictionary;//


@end

@implementation YDDrawModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.uniformDictionary=[NSMutableDictionary dictionary];
        
        self.attributeDictionary=[NSMutableDictionary dictionary];
        
    }
    return self;
}

-(void)setvShaderSource:(const char *)vSource andfShaderSource:(const char *)fSource{

    GLint program=LinkPorgram(vSource, fSource);
    
    glDeleteProgram(_program);
    //TODO:不需要delete shader?
    _program=program;
    
    [self loadProgram];
    
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
    
    glDeleteBuffers(1, &_vertices_buffer_obj);
    glDeleteBuffers(1, &_texture_vertices_buffer_obj);
    glDeleteBuffers(1, &_indices_buffer_obj);
    
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

-(void)loadSquareVex:(const GLfloat [12])vertices_position{

    const GLfloat vertices_texture[]={
        
        0.0,0.0, 1.0,0.0, 1.0,1.0, 0.0,1.0,
        
        //旋转90度 1.0,1.0, 0.0,1.0 ,0.0,0.0, 1.0,0.0,
        
    };
    
    [self loadSquareVex:vertices_position andTextureCoord:vertices_texture];

}

-(void)loadSquareVex:(const GLfloat [12])vertices_position andTextureCoord:(const GLfloat [8])textureCoord{

    const GLubyte indices_position[]={
        
        0,1,2,3,
        
    };

    struct ArrayWrapper vertices_wrapper={vertices_position,12*sizeof(GLfloat),12};
    struct ArrayWrapper texturecoord_warpper={textureCoord,8*sizeof(GLfloat),8};
    struct ArrayWrapper indices_warpper={indices_position,sizeof(indices_position),sizeof(indices_position)/sizeof(GLubyte)};
    
    [self setVertices:vertices_wrapper andTextureVertices:texturecoord_warpper andIndices:indices_warpper andDrawStyle:GL_TRIANGLE_FAN];

}



-(void)loadSquareVex{
    
    const GLfloat vertices_position[]={
        
        -1.0,-1.0,0.0,
        
        1.0,-1.0,0.0,
        
        1.0,1.0,0.0,
        
        -1.0,1.0,0.0,
        
    };
    
    [self loadSquareVex:vertices_position];
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
    
    [_uniformDictionary removeAllObjects];
    
    [_attributeDictionary removeAllObjects];
    
}

/**
 *  @author 许辉泽, 16-03-17 19:53:30
 *
 *  查询位置是一个比较耗时的操作
 *
 *  @since 1.0.0
 */
-(void)loadProgram{

    [self.uniformDictionary removeAllObjects];
    
    [self.attributeDictionary removeAllObjects];
    
    glUseProgram(_program);
    
    //查询统一变量
    
    GLint maxUniformLen;
    GLint numUniforms;
    char *uniformName;
    glGetProgramiv ( _program, GL_ACTIVE_UNIFORMS, &numUniforms );
    glGetProgramiv ( _program, GL_ACTIVE_UNIFORM_MAX_LENGTH,
                    &maxUniformLen);
    
    uniformName = malloc ( sizeof ( char ) * maxUniformLen );
    
    for (int index=0; index<numUniforms; index++) {
        
        GLint size;
        GLenum type;
        GLint location;
        
        glGetActiveUniform(_program, index, maxUniformLen, NULL, &size, &type, uniformName);
        
        location=glGetUniformLocation(_program, uniformName);
        
        NSString *name=[NSString stringWithUTF8String:uniformName];
        
        //NSLog(@" uniform name:%@  location:%i",name,location);
    
        [self.uniformDictionary setObject:@(location) forKey:name];
        
    }
    
    free(uniformName);
    
    //查询 attribute
    
    GLint maxAttributeLen;
    GLint numAttributes;
    char *attributeName;
    
    glGetProgramiv(_program, GL_ACTIVE_ATTRIBUTES, &numAttributes);
    glGetProgramiv(_program, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &maxAttributeLen);
    
    attributeName=malloc(sizeof(char)*maxAttributeLen);
    
    for (int index=0; index<maxAttributeLen; index++) {
        
        GLint size;
        GLenum type;
        GLint location;
        
        glGetActiveAttrib(_program, index, maxAttributeLen, NULL, &size, &type, attributeName);
        
        location=glGetAttribLocation(_program, attributeName);
        
        NSString *name=[NSString stringWithUTF8String:attributeName];
        
        //NSLog(@" attribute name:%@  location:%i",name,location);

        [self.attributeDictionary setObject:@(location) forKey:name];
    }
    
    free(attributeName);
    
    
}

-(GLint)locationOfUniform:(NSString *)uniformName{

    NSNumber *location=self.uniformDictionary[uniformName];
    
    //NSAssert(location!=nil, @"招不到着色器里面的统一变量名:%@,请检查清楚",uniformName);
    
//    if (location==nil) {
//        
//        NSLog(@"错误,找不到unifrom %@ location",uniformName);
//    }
    
    return location.intValue;

}

-(GLint)locationOfAttribute:(NSString *)attributeName{

    NSNumber *location=self.attributeDictionary[attributeName];
    
    //NSAssert(location!=nil, @"招不到着色器里面的属性名:%@,请检查清楚",attributeName);
    
    return location.intValue;

}



@end

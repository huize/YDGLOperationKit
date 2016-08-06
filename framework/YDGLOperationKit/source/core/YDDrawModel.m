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

@property(nonatomic,retain)YDGLProgram *glProgram;

@property(nonatomic,retain)NSMutableDictionary<NSString*,NSNumber*> *uniformDictionary;

@property(nonatomic,retain)NSMutableDictionary<NSString*,NSNumber*> *attributeDictionary;

@property(nonatomic,assign)BOOL needLoad;

@property(nonatomic,copy)NSString * vertexSource;

@property(nonatomic,copy)NSString * fragmentSource;

@property(nonatomic,assign)struct ArrayWrapper vertices_wrapper;

@property(nonatomic,assign)struct ArrayWrapper texturecoord_warpper;

@property(nonatomic,assign)struct ArrayWrapper indices_warpper;

@end

@implementation YDDrawModel

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        
        _uniformDictionary=[NSMutableDictionary dictionary];
        
        _attributeDictionary=[NSMutableDictionary dictionary];
        
        self.needLoad=YES;
        
    }
    return self;
}

#pragma  -mark private

-(void)loadSquareVex:(const GLfloat [12])vertices_position andTextureCoord:(const GLfloat [8])textureCoord{
    
    const GLubyte indices_position[]={
        
        0,1,2,3,
        
    };
    
    struct ArrayWrapper vertices_wrapper={vertices_position,12*sizeof(GLfloat),12};
    struct ArrayWrapper texturecoord_warpper={textureCoord,8*sizeof(GLfloat),8};
    struct ArrayWrapper indices_warpper={indices_position,sizeof(indices_position),sizeof(indices_position)/sizeof(GLubyte)};
    
    [self setVertices:vertices_wrapper andTextureVertices:texturecoord_warpper andIndices:indices_warpper andDrawStyle:GL_TRIANGLE_FAN];
    
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
    
    self.vertices_wrapper=vertices;
    
    self.texturecoord_warpper=textureVertices;
    
    self.indices_warpper=indices;
    
    _drawStyle=drawModel;
    
    self.needLoad=YES;
    
}
/**
 *  @author 许辉泽, 16-03-17 19:53:30
 *
 *  查询位置是一个比较耗时的操作
 *
 *  @since 1.0.0
 */
-(void)innerloadProgram{
    
    self.glProgram=[[YDGLProgram alloc]initWithVertexString:[self.vertexSource UTF8String] andFragmentString:[self.fragmentSource UTF8String]];
    
    [_uniformDictionary removeAllObjects];
    
    [_attributeDictionary removeAllObjects];
    
    glUseProgram([self getRealProgram]);
    
    //查询统一变量
    
    GLint maxUniformLen;
    GLint numUniforms;
    char *uniformName;
    glGetProgramiv ( [self getRealProgram], GL_ACTIVE_UNIFORMS, &numUniforms );
    glGetProgramiv ( [self getRealProgram], GL_ACTIVE_UNIFORM_MAX_LENGTH,
                    &maxUniformLen);
    
    uniformName = malloc ( sizeof ( char ) * maxUniformLen );
    
    for (int index=0; index<numUniforms; index++) {
        
        GLint size;
        GLenum type;
        GLint location;
        
        glGetActiveUniform([self getRealProgram], index, maxUniformLen, NULL, &size, &type, uniformName);
        
        location=glGetUniformLocation([self getRealProgram], uniformName);
        
        NSString *name=[NSString stringWithUTF8String:uniformName];
        
        //NSLog(@" uniform name:%@  location:%i",name,location);
        if (!name) continue;
        
        [_uniformDictionary setObject:@(location) forKey:name];
        
    }
    
    free(uniformName);
    
    //查询 attribute
    
    //    GLint maxAttributeLen;
    //    GLint numAttributes;
    //    char *attributeName;
    //
    //    glGetProgramiv([self getRealProgram], GL_ACTIVE_ATTRIBUTES, &numAttributes);
    //    glGetProgramiv([self getRealProgram], GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, &maxAttributeLen);
    //
    //    attributeName=malloc(sizeof(char)*100);
    //
    //    for (int index=0; index<maxAttributeLen; index++) {
    //
    //        GLint size;
    //        GLenum type;
    //        GLint location;
    //
    //        glGetActiveAttrib([self getRealProgram], index, maxAttributeLen, NULL, &size, &type, attributeName);
    //
    //        location=glGetAttribLocation([self getRealProgram], attributeName);
    //
    //        NSString *name=[NSString stringWithUTF8String:attributeName];
    //
    //        NSLog(@" attribute name:%@  location:%i",name,location);
    //
    //        [_attributeDictionary setObject:@(location) forKey:name];
    //    }
    //
    //    free(attributeName);
    
    
}

-(void)innerLoadVertix{
    
    struct ArrayWrapper vertices=self.vertices_wrapper;
    struct ArrayWrapper textureVertices=self.texturecoord_warpper;
    struct ArrayWrapper indices=self.indices_warpper;
    
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
    
    //_drawStyle=drawModel;
    
    free(bufferId);
    
}


#pragma -mark public

-(void)setvShaderSource:(NSString*)vSource andfShaderSource:(NSString*)fSource{
    
    self.vertexSource=vSource;
    
    self.fragmentSource=fSource;
    
    self.needLoad=YES;
    
}
-(void)loadSquareVex:(const GLfloat [12])vertices_position{
    
    const GLfloat vertices_texture[]={
        
        0.0,0.0, 1.0,0.0, 1.0,1.0, 0.0,1.0,
        
        //旋转90度 1.0,1.0, 0.0,1.0 ,0.0,0.0, 1.0,0.0,
        
    };
    
    [self loadSquareVex:vertices_position andTextureCoord:vertices_texture];
    
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
    
    glDeleteBuffers(1, &_vertices_buffer_obj);
    glDeleteBuffers(1, &_texture_vertices_buffer_obj);
    glDeleteBuffers(1, &_indices_buffer_obj);
    [_uniformDictionary removeAllObjects];
    [_attributeDictionary removeAllObjects];
    
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

-(GLuint)getRealProgram{
    
    return self.glProgram.program;
    
}

-(void)loadIfNeed{
    
    if (self.needLoad) {
        
        [self innerLoadVertix];
        [self innerloadProgram];
        self.needLoad=NO;
        
    }
    
}

@end


@implementation YDGLProgram

-(instancetype)initWithVertexString:(const char *)vShaderSource andFragmentString:(const char *)fShaderSource{
    
    if (self=[super init]) {
        
        _vShader=LoadShader(GL_VERTEX_SHADER,vShaderSource);
        
        _fShader=LoadShader(GL_FRAGMENT_SHADER,fShaderSource);
        
        _program=LinkPorgramWithShader(_vShader,_fShader);
        
        return  self;
    }
    
    return nil;
}

- (void)dealloc
{
    glDeleteShader(_vShader);
    
    glDeleteShader(_fShader);
    
    glDeleteProgram(_program);
}


@end

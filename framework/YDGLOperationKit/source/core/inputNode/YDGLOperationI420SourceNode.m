//
//  YDGLOperationI420SourceNode.m
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/4/1.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationI420SourceNode.h"

NSString *const kYDGLOperationI420ToLAFragmentShaderString = SHADER_STRING
(
 
 uniform sampler2D SamplerY;
 uniform sampler2D SamplerU;
 uniform sampler2D SamplerV;
 
 varying highp vec2 textureCoordinate;
 
 uniform lowp int isFullRange;
 
 uniform lowp int isBT709;
 
 void main()
{
    mediump vec3 yuv;
    lowp vec3 rgb;
    
    if(isFullRange==1){
        
        yuv.x = texture2D(SamplerY, textureCoordinate).r;
        
    }else{
        
        yuv.x = texture2D(SamplerY, textureCoordinate).r - (16.0/255.0);
        
    }
    
    yuv.y = texture2D(SamplerU, textureCoordinate).r - 0.5;
    yuv.z = texture2D(SamplerV, textureCoordinate).r - 0.5;
    
    if(isBT709==1){
        
        rgb=mat3( 1.164,  1.164, 1.164,
                 0.0, -0.213, 2.112,
                 1.793, -0.533,   0.0)*yuv;
    }else{
        
        rgb=mat3( 1.0,    1.0,    1.0,
                 0.0,    -0.343, 1.765,
                 1.4,    -0.711, 0.0)*yuv;
        
    }
    
    gl_FragColor = vec4(rgb, 1);
}
 
 
 );

@interface YDGLOperationI420SourceNode()

@property(nonatomic,assign)GLuint textureY;
@property(nonatomic,assign)GLuint textureU;
@property(nonatomic,assign)GLuint textureV;



@property(nonatomic,assign)uint8_t*baseAddress;

@property(nonatomic,assign)CGSize imageSize;

@property(nonatomic,assign)size_t dataSize;

@end


@implementation YDGLOperationI420SourceNode

- (instancetype)init
{
    self = [super initWithFragmentShader:kYDGLOperationI420ToLAFragmentShaderString];
    if (self) {
        
        [self commonInitialization];
    }
    return self;
}

-(void)commonInitialization{
    
    
}

-(void)uploadI420Data:(uint8_t *)baseAddress andDataSize:(size_t)dataSize andImageSize:(CGSize)imageSize{
    
    self.baseAddress=baseAddress;
    
    self.dataSize=dataSize;
    
    self.imageSize=imageSize;
    
}

-(void)innerUpload{
    
    if (_textureY==0) {
        
        GLuint *tmp=malloc(sizeof(GLuint)*3);
        
        glGenTextures(3, tmp);
        
        _textureY=tmp[0];
        
        _textureU=tmp[1];
        
        _textureV=tmp[2];
        
        free(tmp);
        
    }
    
    glActiveTexture(GL_TEXTURE0);
    
    glBindTexture(GL_TEXTURE_2D, _textureY);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    //TODO 一定要加上这2句话
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, _imageSize.width, _imageSize.height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE,_baseAddress);
    
    
    glActiveTexture(GL_TEXTURE1);
    
    glBindTexture(GL_TEXTURE_2D, _textureU);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    //TODO 一定要加上这2句话
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, _imageSize.width/2, _imageSize.height/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE,_baseAddress+(int)(_imageSize.width*_imageSize.height));
    
    glActiveTexture(GL_TEXTURE2);
    
    glBindTexture(GL_TEXTURE_2D, _textureV);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    //TODO 一定要加上这2句话
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, _imageSize.width/2, _imageSize.height/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE,_baseAddress+(int)(_imageSize.width*_imageSize.height+_imageSize.width*_imageSize.height/4));
    
    _size=self.imageSize;
    
    self.textureAvailable=YES;
    
    
}

-(void)setupTextureForProgram:(GLuint)program{
    
    GLint location_texture_Y=glGetUniformLocation(program, [@"SamplerY" UTF8String]);
    
    glActiveTexture(GL_TEXTURE0);
    
    [YDGLOperationNode bindTexture:_textureY];
    
    glUniform1i(location_texture_Y, 0);
    
    GLint location_texture_U=glGetUniformLocation(program, [@"SamplerU" UTF8String]);
    
    glActiveTexture(GL_TEXTURE1);
    
    [YDGLOperationNode bindTexture:_textureU];
    
    glUniform1i(location_texture_U, 1);
    
    GLint location_texture_V=glGetUniformLocation(program, [@"SamplerV" UTF8String]);
    
    glActiveTexture(GL_TEXTURE2);
    
    [YDGLOperationNode bindTexture:_textureV];
    
    glUniform1i(location_texture_V, 2);
    
}

-(void)prepareForRender{
    
    [self innerUpload];
}

-(void)dealloc{
    
    [self activeGLContext:^{
        
        glDeleteTextures(1, &_textureY);
        
        _textureY=0;
        
        glDeleteTextures(1, &_textureU);
        
        _textureU=0;
        
        glDeleteTextures(1, &_textureV);
        
        _textureV=0;
    }];
    
}


@end

//
//  YDGLOperationNV12SourceNode.m
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/4/5.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationNV12SourceNode.h"
NSString *const kYDGLOperationNV12ToLAFragmentShaderString = SHADER_STRING
(
 
 uniform sampler2D SamplerY;
 uniform sampler2D SamplerUV;
 
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
    
    yuv.yz = texture2D(SamplerUV, textureCoordinate).ra - vec2(0.5,0.5);
    
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


@interface YDGLOperationNV12SourceNode()

@property(nonatomic,assign)GLuint textureY;
@property(nonatomic,assign)GLuint textureUV;

@property(nonatomic,assign)uint8_t*baseAddress;

@property(nonatomic,assign)CGSize imageSize;

@property(nonatomic,assign)size_t dataSize;

@end

@implementation YDGLOperationNV12SourceNode

- (instancetype)init
{
    self = [super initWithFragmentShader:kYDGLOperationNV12ToLAFragmentShaderString];
    if (self) {
        
        [self commonInitialization];
    }
    return self;
}

-(void)commonInitialization{
    
    
}

-(void)uploadNV12Data:(uint8_t *)baseAddress andDataSize:(size_t)dataSize andImageSize:(CGSize)imageSize{
    
    self.baseAddress=baseAddress;
    
    self.dataSize=dataSize;
    
    self.imageSize=imageSize;
    
}

-(void)innerUpload{
    
    if (_textureY==0) {
        
        GLuint *tmp=malloc(sizeof(GLuint)*2);
        
        glGenTextures(2, tmp);
        
        _textureY=tmp[0];
        
        _textureUV=tmp[1];
        
        free(tmp);
        
    }
    
    glActiveTexture(GL_TEXTURE0);
    
    [self bindTexture:_textureY];
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, _imageSize.width, _imageSize.height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE,_baseAddress);
    
    
    glActiveTexture(GL_TEXTURE1);
    
    [self bindTexture:_textureUV];
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE_ALPHA, _imageSize.width/2, _imageSize.height/2, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE,_baseAddress+(int)(_imageSize.width*_imageSize.height));
    
    self.size=self.imageSize;
    
    self.textureAvailable=YES;
    
    
}

-(void)setupTextureForProgram:(GLuint)program{
        
    GLint location_texture_Y=[_drawModel locationOfUniform:@"SamplerY"];
    
    glActiveTexture(GL_TEXTURE0);
    
    [YDGLOperationNode bindTexture:_textureY];
    
    glUniform1i(location_texture_Y, 0);
    
    GLint location_texture_UV=[_drawModel locationOfUniform:@"SamplerUV"];
    
    glActiveTexture(GL_TEXTURE1);
    
    [YDGLOperationNode bindTexture:_textureUV];
    
    glUniform1i(location_texture_UV, 1);
    
}

-(void)prepareForRender{
    
    [self innerUpload];
}

-(void)dealloc{
    
    [self activeGLContext:^{
        
        glDeleteTextures(1, &_textureY);
        
        _textureY=0;
        
        glDeleteTextures(1, &_textureUV);
        
        _textureUV=0;
        
    } autoRestore:YES];
    
}


-(void)setBT709:(BOOL)yes{

    [self setInt:yes==YES?1:0 forUniformName:@"isBT709"];

}

-(void)setFullRange:(BOOL)fullRange{

    [self setInt:fullRange==YES?1:0 forUniformName:@"isFullRange"];

}

@end

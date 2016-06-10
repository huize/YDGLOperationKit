//
//  YDGLOperationCVPixelBufferSourceNode.m
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/4/8.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationCVPixelBufferSourceNode.h"

NSString *const kYDGLOperationYUVToLAFragmentShaderString = SHADER_STRING
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
    
    yuv.yz = texture2D(SamplerUV, textureCoordinate).ra - vec2(0.5, 0.5);
    
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

@interface YDGLOperationCVPixelBufferSourceNode ()

@property(nonatomic,assign) GLuint renderTexture_input;//

@property(nonatomic,nullable,assign) CVOpenGLESTextureRef lumaTexture;//

@property(nonatomic,nullable,assign) CVOpenGLESTextureRef chromaTexture;//

@property(nonatomic,nullable,assign) CVOpenGLESTextureCacheRef textureCache;//

@property(nonatomic,assign) CVPixelBufferRef pixelBufferRef;//

@property(nonatomic,assign) OSType pixelFormatType;//


@end

@implementation YDGLOperationCVPixelBufferSourceNode

- (instancetype)init
{
    self = [super initWithFragmentShader:kYDGLOperationYUVToLAFragmentShaderString];
    if (self) {
    }
    return self;
}


-(void)initTexureCacheIfNeed{
    
    if(_textureCache==NULL){
        
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL,_glContext, NULL, &_textureCache);
        
        NSAssert(err==kCVReturnSuccess, @"创建纹理缓冲区失败%i",err);
        
    }
    
}


-(void)innerUploadPixelBufferToTexture{
    
    CVPixelBufferLockBaseAddress(_pixelBufferRef, 0);
    
    size_t width= CVPixelBufferGetWidth(_pixelBufferRef);
    
    size_t height=CVPixelBufferGetHeight(_pixelBufferRef);
    
    self.size=CGSizeMake(width, height);
    
    _pixelFormatType= CVPixelBufferGetPixelFormatType(_pixelBufferRef);
    
    CVOpenGLESTextureCacheRef textureCacheRef=_textureCache;
    
    [self cleanUpTextures];
    
    // Y-plane
    glActiveTexture(GL_TEXTURE0);
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                textureCacheRef,
                                                                _pixelBufferRef,
                                                                NULL,
                                                                GL_TEXTURE_2D,
                                                                GL_LUMINANCE,
                                                                (int)width,
                                                                (int)height,
                                                                GL_LUMINANCE,
                                                                GL_UNSIGNED_BYTE,
                                                                0,
                                                                &_lumaTexture);
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    [self bindTexture:CVOpenGLESTextureGetName(_lumaTexture)];
    
    // UV-plane
    glActiveTexture(GL_TEXTURE1);
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       textureCacheRef,
                                                       _pixelBufferRef,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_LUMINANCE_ALPHA,
                                                       (int)width/2,
                                                       (int)height/2,
                                                       GL_LUMINANCE_ALPHA,
                                                       GL_UNSIGNED_BYTE,
                                                       1,
                                                       &_chromaTexture);
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    [self bindTexture:CVOpenGLESTextureGetName(_chromaTexture)];
    
    CVPixelBufferUnlockBaseAddress(_pixelBufferRef, 0);
    
    self.textureAvailable=YES;
    
}

-(void)uploadCVPixelBuffer:(CVPixelBufferRef)pixelBufferRef{
    
    //TODO:where to release pixelBufferRef
    
    OSType pixelFormate= CVPixelBufferGetPixelFormatType(pixelBufferRef);
    
    NSAssert(kCVPixelFormatType_420YpCbCr8Planar==pixelFormate||kCVPixelFormatType_420YpCbCr8PlanarFullRange==pixelFormate, @"YDGLOperationCVPixelBufferSourceNode now only support I420");
    
    CVPixelBufferRetain(pixelBufferRef);
    
    CVPixelBufferRelease(_pixelBufferRef);
    
    _pixelBufferRef=pixelBufferRef;
    
    self.textureAvailable=NO;
    
}


-(void)prepareForRender{
    
    [self initTexureCacheIfNeed];
    
    if (_renderTexture_input==0) {
        
        glGenTextures(1, &_renderTexture_input);
    }
    
    if (self.textureAvailable==NO) {
        
        [self innerUploadPixelBufferToTexture];
        
        
        switch (_pixelFormatType) {
            case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            {
                
                [self setBool:NO forUniformName:@"isFullRange"];
                
            }
                break;
            case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
            {
                
                [self setBool:YES forUniformName:@"isFullRange"];
            }
                
                break;
                
            default:
                break;
        }
        
        
        CFTypeRef colorAttachments = CVBufferGetAttachment(_pixelBufferRef, kCVImageBufferYCbCrMatrixKey, NULL);
        if (colorAttachments != NULL)
        {
            if(CFStringCompare(colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4, 0) == kCFCompareEqualTo)
            {
                
                [self setBool:NO forUniformName:@"isBT709"];
            }
            else
            {
                [self setBool:YES forUniformName:@"isBT709"];
            }
        }
        
    }
}

-(void)setupTextureForProgram:(GLuint)program{
    
    GLint location_texture_Y=[_drawModel locationOfUniform:@"SamplerY"];
    
    glActiveTexture(GL_TEXTURE0);
    
    [YDGLOperationNode bindTexture:CVOpenGLESTextureGetName(_lumaTexture)];
    
    glUniform1i(location_texture_Y, 0);
    
    GLint location_texture_UV=[_drawModel locationOfUniform:@"SamplerUV"];
    
    glActiveTexture(GL_TEXTURE1);
    
    [YDGLOperationNode bindTexture:CVOpenGLESTextureGetName(_chromaTexture)];
    
    glUniform1i(location_texture_UV, 1);
}

- (void)cleanUpTextures
{
    if (_lumaTexture)
    {
        CFRelease(_lumaTexture);
        _lumaTexture = NULL;
    }
    
    if (_chromaTexture)
    {
        CFRelease(_chromaTexture);
        _chromaTexture = NULL;
    }
    
}

-(void)dealloc{
    
    CVOpenGLESTextureCacheFlush(_textureCache, 0);
    
    CFRelease(_textureCache);
    
    _textureCache=NULL;

}

-(void)destoryEAGLResource{

    [super destoryEAGLResource];
    
    glDeleteTextures(1, &_renderTexture_input);
    
    [self cleanUpTextures];

}


@end

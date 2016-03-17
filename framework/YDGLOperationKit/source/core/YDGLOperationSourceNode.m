//
//  GLOperation.m
//  LiveVideo
//
//  Created by 辉泽许 on 16/3/10.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationSourceNode.h"

NSString *const kYDGLOperationYUVFragmentShaderString = SHADER_STRING
(
 
 uniform sampler2D SamplerY;
 uniform sampler2D SamplerUV;
 
 varying highp vec2 textureCoordinate;
 
 void main()
{
    mediump vec3 yuv;
    lowp vec3 rgb;
    
    yuv.x = texture2D(SamplerY, textureCoordinate).r;
    yuv.yz = texture2D(SamplerUV, textureCoordinate).rg - vec2(0.5, 0.5);
    
    // BT.601, which is the standard for SDTV is provided as a reference
    /*
     rgb = mat3(    1,       1,     1,
     0, -.34413, 1.772,
     1.402, -.71414,     0) * yuv;*/
     
    
    // Using BT.709 which is the standard for HDTV
    rgb = mat3(      1,       1,      1,
               0, -.18732, 1.8556,
               1.57481, -.46813,      0) * yuv;
    
    gl_FragColor = vec4(rgb, 1);
}

 
 );



@interface YDGLOperationSourceNode ()

@property(nonatomic,assign) GLuint renderTexture_input;//

@property(nonatomic,nullable,assign) CVOpenGLESTextureRef lumaTexture;//

@property(nonatomic,nullable,assign) CVOpenGLESTextureRef chromaTexture;//

@property(nonatomic,assign) OSType pixelFormatType;//

@property(nonatomic,assign) BOOL shouldSwitchShader;//

@property(nonatomic,nullable,retain) UIImage *image;//

@property(nonatomic,assign) CVPixelBufferRef pixelBufferRef;//


@end

@implementation YDGLOperationSourceNode

-(instancetype)initWithUIImage:(UIImage *)image{

    if (self==[super init]) {
        
        _image=image;
        
        return  self;
    }
    
    return nil;

}

-(void)commonInitialization{

    glDeleteTextures(1, &_renderTexture_input);
    
    glGenTextures(1, &_renderTexture_input);

}

-(void)uploadImage:(UIImage *)image{
    
    self.image=image;
    
    CVPixelBufferRelease(_pixelBufferRef);
    
    _pixelBufferRef=NULL;
    
}

-(void)innerUploadImageToTexture{

    size_t width = CGImageGetWidth(_image.CGImage);
    size_t height = CGImageGetHeight(_image.CGImage);
    
    GLubyte *data=calloc(1, width*height*4*sizeof(GLubyte));
    
    CGContextRef context= CGBitmapContextCreate(data, width, height, 8, width*4, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    CGImageRef ci=_image.CGImage;
    
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), ci);
    
    glBindTexture(GL_TEXTURE_2D, _renderTexture_input);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)width,(int)height, 0, GL_RGBA,
                 GL_UNSIGNED_BYTE, data);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    //TODO 一定要加上这2句话
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    _size=CGSizeMake(width, height);
    
    if (_pixelFormatType!=kCVPixelFormatType_32RGBA) {
        
        _pixelFormatType=kCVPixelFormatType_32RGBA;
        _shouldSwitchShader=YES;
        
    }
    
    CGContextRelease(context);
    free(data);
}

-(void)innerUploadPixelBufferToTexture{

    CVPixelBufferLockBaseAddress(_pixelBufferRef, 0);
    
    size_t width= CVPixelBufferGetWidth(_pixelBufferRef);
    
    size_t height=CVPixelBufferGetHeight(_pixelBufferRef);
    
    _size=CGSizeMake(width, height);
    
    OSType pixelFormatType= CVPixelBufferGetPixelFormatType(_pixelBufferRef);
    
    if (_pixelFormatType!=pixelFormatType) {
        
        _shouldSwitchShader=YES;
        
        _pixelFormatType=pixelFormatType;
        
    }
    
    CVOpenGLESTextureCacheRef textureCacheRef=[[self class] getTextureCache];
    
    [self cleanUpTextures];
    
    // Y-plane
    glActiveTexture(GL_TEXTURE0);
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                textureCacheRef,
                                                                _pixelBufferRef,
                                                                NULL,
                                                                GL_TEXTURE_2D,
                                                                GL_RED_EXT,
                                                                width,
                                                                height,
                                                                GL_RED_EXT,
                                                                GL_UNSIGNED_BYTE,
                                                                0,
                                                                &_lumaTexture);
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    
    // UV-plane
    glActiveTexture(GL_TEXTURE1);
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                       textureCacheRef,
                                                       _pixelBufferRef,
                                                       NULL,
                                                       GL_TEXTURE_2D,
                                                       GL_RG_EXT,
                                                       width/2,
                                                       height/2,
                                                       GL_RG_EXT,
                                                       GL_UNSIGNED_BYTE,
                                                       1,
                                                       &_chromaTexture);
    if (err)
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    
    CVPixelBufferUnlockBaseAddress(_pixelBufferRef, 0);

}



-(void)uploadCVPixelBuffer:(CVPixelBufferRef)pixelBufferRef{
    
    CVPixelBufferRelease(_pixelBufferRef);
    
    CVPixelBufferRetain(pixelBufferRef);
    
    _pixelBufferRef=pixelBufferRef;
    
    self.image=nil;
    
    
}

-(void)setupTextureForProgram:(GLuint)program{
    
    if (_pixelFormatType==kCVPixelFormatType_32RGBA) {
        
        GLint location_s_texture=glGetUniformLocation(program, [UNIFORM_INPUTTEXTURE UTF8String]);
        
        glActiveTexture(GL_TEXTURE0);
        
        glBindTexture(GL_TEXTURE_2D, _renderTexture_input);
        
        glUniform1i ( location_s_texture,0);
    }else{
        
        GLint location_texture_Y=glGetUniformLocation(program, [@"SamplerY" UTF8String]);
        
        glActiveTexture(GL_TEXTURE0);
        
        glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
        
        glUniform1i(location_texture_Y, 0);
        
        GLint location_texture_UV=glGetUniformLocation(program, [@"SamplerUV" UTF8String]);
        
        glActiveTexture(GL_TEXTURE1);
        
        glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
        
        glUniform1i(location_texture_UV, 1);
    }
    
}

-(void)start{
    
    dispatch_async([[self class]getWorkQueue], ^{
        
        [self activeGLContext:^{
            
            [self prepareForRender];
        
            [self render];
        }];
    
    });
    
}


-(void)prepareForRender{


    if (_image) {
        
        [self innerUploadImageToTexture];
        
    }else if(_pixelBufferRef!=NULL){
    
        [self innerUploadPixelBufferToTexture];
        
    }
    

    if (_shouldSwitchShader) {
        
        NSString *fragmentShader=fShaderStr;
        
        switch (_pixelFormatType) {
            case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
                fragmentShader=kYDGLOperationYUVFragmentShaderString;
                break;
                
            default:
                break;
        }
        
        [_drawModel setvShaderSource:[vShaderStr UTF8String] andfShaderSource:[fragmentShader UTF8String]];
        
        _shouldSwitchShader=NO;
        
    }
    
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
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush([[self class]getTextureCache], 0);
    
    
}



-(void)dealloc{

    glDeleteTextures(1, &_renderTexture_input);

}

@end

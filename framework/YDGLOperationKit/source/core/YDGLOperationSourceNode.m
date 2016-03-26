//
//  GLOperation.m
//  LiveVideo
//
//  Created by 辉泽许 on 16/3/10.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationSourceNode.h"

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


#define  DEFAULT_IMAGE_PIXEL_FORMAT_TYPE kCVPixelFormatType_32BGRA

@interface YDGLOperationSourceNode ()

@property(nonatomic,assign) GLuint renderTexture_input;//

@property(nonatomic,nullable,assign) CVOpenGLESTextureRef lumaTexture;//

@property(nonatomic,nullable,assign) CVOpenGLESTextureRef chromaTexture;//

@property(nonatomic,nullable,assign) CVOpenGLESTextureCacheRef textureCache;//

@property(nonatomic,assign) OSType pixelFormatType;//

@property(nonatomic,assign) BOOL shouldSwitchShader;//

@property(nonatomic,nullable,retain) UIImage *image;//

@property(nonatomic,assign) CVPixelBufferRef pixelBufferRef;//

@property(nonatomic,assign) BOOL textureAvailable;//纹理是否可用


@end

@implementation YDGLOperationSourceNode

-(instancetype)initWithUIImage:(UIImage *)image{

    if (self=[self init]) {
        
        _image=image;
        
        return  self;
    }
    
    return nil;

}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self commonInitialization];
        
    }
    return self;
}


-(void)commonInitialization{
    
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [[self class] getGLContext], NULL, &_textureCache);
    
    NSAssert(err==kCVReturnSuccess, @"创建纹理缓冲区失败%i",err);
    
    //[self rotateAtZ:180];//注意:UIKit和AVFoundationKit的坐标原点在左上角,openGL ES/CGContext 的坐标原点在左下角
    
    
    
}

-(void)innerUploadImageToTexture{

    
    self.textureAvailable=YES;
    
    CGImageRef newImageSource=_image.CGImage;
    
    // TODO: Dispatch this whole thing asynchronously to move image loading off main thread
    CGFloat widthOfImage = CGImageGetWidth(newImageSource);
    CGFloat heightOfImage = CGImageGetHeight(newImageSource);
    
    // If passed an empty image reference, CGContextDrawImage will fail in future versions of the SDK.
    NSAssert( widthOfImage > 0 && heightOfImage > 0, @"Passed image must not be empty - it should be at least 1px tall and wide");
    
    CGSize pixelSizeOfImage = CGSizeMake(widthOfImage, heightOfImage);
    CGSize pixelSizeToUseForTexture = pixelSizeOfImage;
    
    BOOL shouldRedrawUsingCoreGraphics = NO;
    
    GLubyte *imageData = NULL;
    CFDataRef dataFromImageDataProvider = NULL;
    GLenum format = GL_BGRA;
    
    if (!shouldRedrawUsingCoreGraphics) {
        /* Check that the memory layout is compatible with GL, as we cannot use glPixelStore to
         * tell GL about the memory layout with GLES.
         */
        if (CGImageGetBytesPerRow(newImageSource) != CGImageGetWidth(newImageSource) * 4 ||
            CGImageGetBitsPerPixel(newImageSource) != 32 ||
            CGImageGetBitsPerComponent(newImageSource) != 8)
        {
            shouldRedrawUsingCoreGraphics = YES;
        } else {
            /* Check that the bitmap pixel format is compatible with GL */
            CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(newImageSource);
            if ((bitmapInfo & kCGBitmapFloatComponents) != 0) {
                /* We don't support float components for use directly in GL */
                shouldRedrawUsingCoreGraphics = YES;
            } else {
                CGBitmapInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
                if (byteOrderInfo == kCGBitmapByteOrder32Little) {
                    /* Little endian, for alpha-first we can use this bitmap directly in GL */
                    CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
                    if (alphaInfo != kCGImageAlphaPremultipliedFirst && alphaInfo != kCGImageAlphaFirst &&
                        alphaInfo != kCGImageAlphaNoneSkipFirst) {
                        shouldRedrawUsingCoreGraphics = YES;
                    }
                } else if (byteOrderInfo == kCGBitmapByteOrderDefault || byteOrderInfo == kCGBitmapByteOrder32Big) {
                    /* Big endian, for alpha-last we can use this bitmap directly in GL */
                    CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
                    if (alphaInfo != kCGImageAlphaPremultipliedLast && alphaInfo != kCGImageAlphaLast &&
                        alphaInfo != kCGImageAlphaNoneSkipLast) {
                        shouldRedrawUsingCoreGraphics = YES;
                    } else {
                        /* Can access directly using GL_RGBA pixel format */
                        format = GL_RGBA;
                    }
                }
            }
        }
    }
    
    //    CFAbsoluteTime elapsedTime, startTime = CFAbsoluteTimeGetCurrent();
    
    if (shouldRedrawUsingCoreGraphics)
    {
        // For resized or incompatible image: redraw
        imageData = (GLubyte *) calloc(1, (int)pixelSizeToUseForTexture.width * (int)pixelSizeToUseForTexture.height * 4);
        
        CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
        
        CGContextRef imageContext = CGBitmapContextCreate(imageData, (size_t)pixelSizeToUseForTexture.width, (size_t)pixelSizeToUseForTexture.height, 8, (size_t)pixelSizeToUseForTexture.width * 4, genericRGBColorspace,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        //        CGContextSetBlendMode(imageContext, kCGBlendModeCopy); // From Technical Q&A QA1708: http://developer.apple.com/library/ios/#qa/qa1708/_index.html
        CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, pixelSizeToUseForTexture.width, pixelSizeToUseForTexture.height), newImageSource);
        CGContextRelease(imageContext);
        CGColorSpaceRelease(genericRGBColorspace);
    }
    else
    {
        // Access the raw image bytes directly
        dataFromImageDataProvider = CGDataProviderCopyData(CGImageGetDataProvider(newImageSource));
        
        imageData = (GLubyte *)CFDataGetBytePtr(dataFromImageDataProvider);
    }
    
    [YDGLOperationNode bindTexture:_renderTexture_input];
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)pixelSizeToUseForTexture.width, (int)pixelSizeToUseForTexture.height, 0, format, GL_UNSIGNED_BYTE, imageData);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    //TODO 一定要加上这2句话
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
        
    _size=pixelSizeToUseForTexture;
    
    if (_pixelFormatType!=DEFAULT_IMAGE_PIXEL_FORMAT_TYPE) {
        
        _pixelFormatType=DEFAULT_IMAGE_PIXEL_FORMAT_TYPE;
        
        _shouldSwitchShader=YES;
        
    }
    
    
    if (shouldRedrawUsingCoreGraphics)
    {
        free(imageData);
    }
    else
    {
        if (dataFromImageDataProvider)
        {
            CFRelease(dataFromImageDataProvider);
        }
    }
   
}

-(void)innerUploadPixelBufferToTexture{

    //self.textureAvailable=YES;
    
    CVPixelBufferLockBaseAddress(_pixelBufferRef, 0);
    
    size_t width= CVPixelBufferGetWidth(_pixelBufferRef);
    
    size_t height=CVPixelBufferGetHeight(_pixelBufferRef);
    
    _size=CGSizeMake(width, height);
    
    OSType pixelFormatType= CVPixelBufferGetPixelFormatType(_pixelBufferRef);
    
    if (_pixelFormatType!=pixelFormatType) {
        
        _shouldSwitchShader=YES;
        
        _pixelFormatType=pixelFormatType;
        
    }
    
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
    
    [YDGLOperationNode bindTexture:CVOpenGLESTextureGetName(_lumaTexture)];
    
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
    
    [YDGLOperationNode bindTexture:CVOpenGLESTextureGetName(_chromaTexture)];
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    
    CVPixelBufferUnlockBaseAddress(_pixelBufferRef, 0);

}

-(void)setupTextureForProgram:(GLuint)program{
    
    if (_pixelFormatType==DEFAULT_IMAGE_PIXEL_FORMAT_TYPE) {
        
        GLint location_s_texture=glGetUniformLocation(program, [UNIFORM_INPUTTEXTURE UTF8String]);
        
        glActiveTexture(GL_TEXTURE0);
        
        [YDGLOperationNode bindTexture:_renderTexture_input];
        
        glUniform1i ( location_s_texture,0);
    }else{
        
        GLint location_texture_Y=glGetUniformLocation(program, [@"SamplerY" UTF8String]);
        
        glActiveTexture(GL_TEXTURE0);
        
        [YDGLOperationNode bindTexture:CVOpenGLESTextureGetName(_lumaTexture)];
        
        glUniform1i(location_texture_Y, 0);
        
        GLint location_texture_UV=glGetUniformLocation(program, [@"SamplerUV" UTF8String]);
        
        glActiveTexture(GL_TEXTURE1);
        
        [YDGLOperationNode bindTexture:CVOpenGLESTextureGetName(_chromaTexture)];
        
        glUniform1i(location_texture_UV, 1);
    }
    
}

-(void)start{
    
    RunInNodeProcessQueue(^{
        
        [self activeGLContext:^{
            
            [self prepareForRender];
        
        }];
        
        [self renderIfCanWhenDependencyDone:self];
        
    });
    
}

-(void)prepareForRender{
    
    if (_renderTexture_input==0) {
        
        glGenTextures(1, &_renderTexture_input);
    }
    
    if (self.textureAvailable==NO) {
        
        if (_image) {
            
            [self innerUploadImageToTexture];
            
        }else if(_pixelBufferRef!=NULL){
            
            [self innerUploadPixelBufferToTexture];
            
        }
        
        if (_shouldSwitchShader) {
            
            NSString *fragmentShader=fShaderStr;
            
            switch (_pixelFormatType) {
                case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
                {
                    
                    fragmentShader=kYDGLOperationYUVToLAFragmentShaderString;
                    [self setBool:NO forUniformName:@"isFullRange"];
                    
                }
                    break;
                case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
                {
                    
                    fragmentShader=kYDGLOperationYUVToLAFragmentShaderString;
                    
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
            
            [_drawModel setvShaderSource:[vShaderStr UTF8String] andfShaderSource:[fragmentShader UTF8String]];
            
            _shouldSwitchShader=NO;
            
        }
        
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
    
}


-(void)dealloc{

    glDeleteTextures(1, &_renderTexture_input);
    
    CVOpenGLESTextureCacheFlush(_textureCache, 0);

}


#pragma -mark 对外接口

-(void)uploadImage:(UIImage *)image{
    
    if (self.image==image) {
        
        return;
    }
    
    RunInNodeProcessQueue(^{
        
        self.image=image;
        
        CVPixelBufferRelease(_pixelBufferRef);
        
        _pixelBufferRef=NULL;
        
        self.textureAvailable=NO;
        
    });
    
}

-(void)uploadCVPixelBuffer:(CVPixelBufferRef)pixelBufferRef{
    
    CVPixelBufferRetain(pixelBufferRef);
    
    RunInNodeProcessQueue(^{
        
        CVPixelBufferRelease(_pixelBufferRef);
        
        _pixelBufferRef=pixelBufferRef;
        
        self.image=nil;
        
        self.textureAvailable=NO;

    });
    
}

@end

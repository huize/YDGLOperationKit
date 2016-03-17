//
//  GLOperation.m
//  LiveVideo
//
//  Created by 辉泽许 on 16/3/10.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationSourceNode.h"

@implementation YDGLOperationSourceNode

{

    GLuint _renderTexture_input;
    
    UIImage *_image;

}

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
    
    size_t width = CGImageGetWidth(image.CGImage);
    size_t height = CGImageGetHeight(image.CGImage);
    
    GLubyte *data=calloc(1, width*height*4*sizeof(GLubyte));
    
    CGContextRef context= CGBitmapContextCreate(data, width, height, 8, width*4, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    CGImageRef ci=image.CGImage;
    
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
    
    CGContextRelease(context);
    free(data);

    
}

-(void)uploadCVPixelBuffer:(CVPixelBufferRef)pixelBufferRef{
    
    OSType pixelFormatType= CVPixelBufferGetPixelFormatType(pixelBufferRef);

}


-(void)loadTexture{
    
    [self uploadImage:_image];
    
}

-(void)setupTextureForProgram:(GLuint)program{

    GLint location_s_texture=glGetUniformLocation(program, [UNIFORM_INPUTTEXTURE UTF8String]);
    
    glActiveTexture(GL_TEXTURE0);
    
    glBindTexture(GL_TEXTURE_2D, _renderTexture_input);
    
    glUniform1i ( location_s_texture,0);

}

-(void)start{
    
    dispatch_async([[self class]getWorkQueue], ^{
        
        
        [self activeGLContext:^{
            
            [self loadTexture];
            
            [self render];
        }];
    
    });
    
}

-(void)dealloc{

    glDeleteTextures(1, &_renderTexture_input);

}


@end

//
//  YDGLOperationCGContextSourceNode.m
//  YDGLOperationKit
//
//  Created by xuhuize on 16/4/16.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationCGContextSourceNode.h"

@interface YDGLOperationCGContextSourceNode()

@property(nonatomic,assign)CGContextRef context;

@property(nonatomic,assign) GLuint renderTexture_input;//


@end

@implementation YDGLOperationCGContextSourceNode

-(instancetype)initWithSize:(CGSize)size{
    
    if (self=[super init]) {
        
        _size=size;
        
        [self commonInitialization];
        
        return self;
    }
    
    return nil;
}

-(void)commonInitialization{
    
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    
    _context = CGBitmapContextCreate(NULL, _size.width,_size.height, 8, _size.width * 4, genericRGBColorspace,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGContextSetRGBStrokeColor(_context, 0.0, 1.0, 0.0, 1.0);//draw with green color;

}

-(void)drawCGPoint:(CGPoint)point{
    
    CGContextAddArc(_context, point.x, point.y, 2, 0, M_PI, 1);
    
}

-(void)drawCGRect:(CGRect)rect{
    
    CGContextAddRect(_context, rect);
    
}


-(void)clearContent{
    
    [self setNeedDisplay];
    
    CGContextClearRect(_context, CGRectMake(0, 0, _size.width, _size.height));
    
}

-(void)commit{
    
    CGContextFlush(_context);
    
    [self start];
    
}

/**
 *  @author 9527, 16-04-16 18:04:00
 *
 *  upload the cgcontext content to the texture as input
 */
-(void)innerUploadCGContextToTexture{
    
    [YDGLOperationNode bindTexture:_renderTexture_input];
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    //TODO 一定要加上这2句话
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
    
    
    uint8_t *data= CGBitmapContextGetData(_context);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)_size.width, (int)_size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    self.textureAvailable=YES;
    
}

-(void)prepareForRender{
    
    if (_renderTexture_input==0) {
        
        glGenTextures(1, &_renderTexture_input);
    }
    
    if (self.textureAvailable==NO) {
        
        [self innerUploadCGContextToTexture];
        
    }
    
}

-(void)willSetNodeSize:(CGSize *)newInputSize{

    *newInputSize=_size;

}


@end

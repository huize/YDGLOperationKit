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

@property(nonatomic,assign)GLubyte *baseAddress;


@end

@implementation YDGLOperationCGContextSourceNode

- (instancetype)init
{
   
    return [self initWithSize:CGSizeMake(100, 100)];//default size is (100,100)
    
}

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
    
    _baseAddress=(GLubyte*)calloc(1,sizeof(GLubyte)*_size.width*_size.height*4);
    
    _context = CGBitmapContextCreate(_baseAddress, (int)_size.width,(int)_size.height, 8,(int)_size.width * 4, genericRGBColorspace,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);

    
    
    //init CGContext config
    
    CGContextSetStrokeColorWithColor(_context, [UIColor greenColor].CGColor);
    
    CGContextSetFillColorWithColor(_context, [UIColor greenColor].CGColor);
    
    
    CGContextSetLineWidth(_context, 1.0);


}


-(void)commitCGContextTransaction:(void (^)(CGContextRef))drawBlock{
    
    [self setNeedDisplay];
    
    [self clearContext];
    
    if (drawBlock) {
        
        drawBlock(_context);
    }
    
}

/**
 *  @author 9527, 16-04-18 17:32:24
 *
 *  clear the CGContextRef
 *
 *  @since 1.0.0
 */
-(void)clearContext{
    
    CGContextClearRect(_context, CGRectMake(0, 0, _size.width, _size.height));
    
}

/**
 *  @author 9527, 16-04-16 18:04:00
 *
 *  upload the cgcontext content to the texture as input
 */
-(void)innerUploadCGContextToTexture{
    
    [YDGLOperationNode bindTexture:_renderTexture_input];
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    //TODO 一定要加上这2句话
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)_size.width, (int)_size.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, _baseAddress);
    
   self.textureAvailable=YES;
    
}

-(void)setupTextureForProgram:(GLuint)program{
    
    GLint location_s_texture=glGetUniformLocation(program, [UNIFORM_INPUTTEXTURE UTF8String]);
    
    glActiveTexture(GL_TEXTURE0);
    
    [YDGLOperationNode bindTexture:_renderTexture_input];
    
    glUniform1i ( location_s_texture,0);
    
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

    *newInputSize=CGSizeMake(_size.width, _size.height);

}

-(void)dealloc{

    CGContextRelease(_context);
    
    _context=NULL;

    free(_baseAddress);
    
    _baseAddress=0;

    [self activeGLContext:^{
        
        glDeleteTextures(1, &_renderTexture_input);
        
        _renderTexture_input=0;
    }];

}


@end

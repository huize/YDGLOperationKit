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
        
        self.size=size;
        
        [self commonInitialization];
        
        return self;
    }
    
    return nil;
}

-(void)commonInitialization{
    
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    
    _baseAddress=(GLubyte*)calloc(1,sizeof(GLubyte)*self.size.width*self.size.height*4);
    
    _context = CGBitmapContextCreate(_baseAddress, (int)self.size.width,(int)self.size.height, 8,(int)self.size.width * 4, genericRGBColorspace,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
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
    
    CGContextClearRect(_context, CGRectMake(0, 0, self.size.width, self.size.height));
    
}

/**
 *  @author 9527, 16-04-16 18:04:00
 *
 *  upload the cgcontext content to the texture as input
 */
-(void)innerUploadCGContextToTexture{
    
    
    [self bindTexture:_renderTexture_input];
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)self.size.width, (int)self.size.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, _baseAddress);
    
   self.textureAvailable=YES;
    
}

-(void)setupTextureForProgram:(GLuint)program{
        
    GLint location_s_texture=[_drawModel locationOfUniform:UNIFORM_INPUTTEXTURE];
    
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

-(void)dealloc{

    CGContextRelease(_context);
    
    _context=NULL;

    free(_baseAddress);
    
    _baseAddress=0;

    [self activeGLContext:^{
        
        glDeleteTextures(1, &_renderTexture_input);
        
        _renderTexture_input=0;
    } autoRestore:YES];

}


@end

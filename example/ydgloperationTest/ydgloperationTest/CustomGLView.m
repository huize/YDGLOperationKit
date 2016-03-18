//
//  CustomGLView.m
//  test_openges
//
//  Created by 辉泽许 on 16/1/4.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "CustomGLView.h"

#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

@implementation CustomGLView{

    CAEAGLLayer *_egallayer;
    
    EAGLContext *_context;

    GLuint _renderBuffer,_frameBuffer;//最终的缓冲区对象
    
    GLuint _resolveRenderBuffer,_resolveFrameBuffer,_resolveDepthBuffer;//用于多重采样缓冲区对象
    
    GLint _framebufferWidth;
    
    GLint _framebufferHeight;
    
    GLuint _textureId;
    
    CGSize _sizeInPixel;
    
    float _angle;

    dispatch_semaphore_t _semaphore_t_render;
    
    YDDrawModel *_drawModel;
    
    //渲染到纹理的
    
    dispatch_queue_t _queue;

    
}

+(Class)layerClass{

    return [CAEAGLLayer class];

}

-(void)setupLayer{

    self.opaque = YES;
    self.hidden = NO;
   
    _egallayer=(CAEAGLLayer *)[self layer];

    _egallayer.opaque=YES;
    
    _egallayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking:@NO, kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};

}

-(void)commonInit{
    
    _drawModel=[YDDrawModel new];

    _queue=[[YDGLOperationNode class] getWorkQueue];
    
    _sizeInPixel=self.bounds.size;
    
    //dispatch_barrier_sync(_queue, ^{
        
    [self setupLayer];
    
    [self setupContext];
    
    [self setupProgram];
    
    [self destoryRenderAndFrameBuffer];
    
    [self setupBuffer];
    
    [self setupMSAABuffer];
    
    //TODO:暂时设置无效
    if (self.cube) {
        
        [self loadCubeVex];
    }else{
        
        [self loadSquareVex];
    }
    
    //});
    
    [EAGLContext setCurrentContext:nil];
    
    _semaphore_t_render=dispatch_semaphore_create(0);

    dispatch_semaphore_wait(_semaphore_t_render, 0);
    
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)setupContext {
    
    _context=[YDGLOperationNode getGLContext];
    
    // 设置为当前上下文
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }

    
}

- (void)setupBuffer {
    
    glGenRenderbuffers(1, &_renderBuffer);
    // 设置为当前 renderbuffer
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    // 为 color renderbuffer 分配存储空间
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_egallayer];
    
    GLint backingWidth, backingHeight;
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    _sizeInPixel=CGSizeMake(backingWidth, backingHeight);
    
    glGenFramebuffers(1, &_frameBuffer);
    // 设置为当前 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _renderBuffer);
    
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
}

/**
 *  @author 许辉泽, 16-01-14 19:53:01
 *
 *  创建用于多重采样的缓冲区,用于offscreen 渲染
 *
 *  @since <#1.0.2#>
 */
- (void)setupMSAABuffer {
    
    glGenFramebuffers(1, &_resolveFrameBuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _resolveFrameBuffer);
    
    glGenRenderbuffers(1, &_resolveRenderBuffer);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _resolveRenderBuffer);
    
    GLint max_samples;
    
    glGetIntegerv(GL_MAX_SAMPLES_APPLE, &max_samples);
    
    glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER,max_samples,GL_RGBA8_OES, _sizeInPixel.width, _sizeInPixel.height);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _resolveRenderBuffer);
    
    
    glGenRenderbuffers(1, &_resolveDepthBuffer);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _resolveDepthBuffer);
    glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, 4, GL_DEPTH_COMPONENT16, _sizeInPixel.width , _sizeInPixel.height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _resolveDepthBuffer);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE){
    
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));

    }
    
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
}

-(void)destoryRenderAndFrameBuffer{

    glDeleteBuffers(1, &_frameBuffer);
    
    _frameBuffer=0;
    
    glDeleteBuffers(1, &_renderBuffer);
    
    _renderBuffer=0;
    
    
    glDeleteBuffers(1, &_resolveFrameBuffer);
    
    _resolveFrameBuffer=0;
    
    glDeleteBuffers(1, &_resolveRenderBuffer);
    
    _resolveRenderBuffer=0;
    

}

-(void)loadCubeVex{
    
    [self activeGLContext:^{
        
        [_drawModel loadCubeVex];

    }];
    
}

-(void)loadSquareVex{
    
    [self activeGLContext:^{
        
        [_drawModel loadSquareVex];
        
    }];
}

-(ESMatrix)mvpMatrix4Cube{

    ESMatrix perspective;
    
    // Compute the window aspect ratio
    float aspect = _sizeInPixel.width/_sizeInPixel.height;
    
    // Generate a perspective matrix with a 60 degree FOV
    esMatrixLoadIdentity ( &perspective );
    esPerspective ( &perspective, 45.0f, aspect, 1.0f, 20.0f );
    
    ESMatrix modelview;
    
    // Compute a rotation angle based on time to rotate the cube
    _angle += ( 1 * 5.0f );
    
    if ( _angle >= 360.0f )
    {
        _angle -= 360.0f;
    }
    
    // Generate a model view matrix to rotate/translate the cube
    esMatrixLoadIdentity ( &modelview );
    
    // Translate away from the viewer
    esTranslate (&modelview, 0, 0,-3.0);
    esTranslate(&modelview, -0.5, -0.5, 0);
    
    esTranslate(&modelview, 0.5, 0.5, 0.5);
    // Rotate the cube
    esRotate ( &modelview, _angle, 1.0, 1.0, 1.0 );
    
    esTranslate(&modelview, -0.5, -0.5, -0.5);

    ESMatrix mvpMatrix;
    esMatrixMultiply ( &mvpMatrix, &modelview, &perspective);
    
    return mvpMatrix;

}

-(ESMatrix)mvpMatrix4Square{
    
    ESMatrix modelview;

    // Generate a model view matrix to rotate/translate the cube
    esMatrixLoadIdentity ( &modelview );
    
    // Translate away from the viewer
    //esTranslate (&modelview, 0, 0,-3.0);
 
    return modelview;
    
}


-(void)setupProgram{

    
    [_drawModel setvShaderSource:[vShaderStr UTF8String] andfShaderSource:[fShaderStr UTF8String]];
    
}

-(void)renderFrame{

    glBindFramebuffer(GL_FRAMEBUFFER, _resolveFrameBuffer);
    
    //glBindRenderbuffer(GL_RENDERBUFFER, _resolveRenderBuffer);
    
    //glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    //glEnable(GL_BLEND);
    
    //glEnable(GL_CULL_FACE);
    
    //glCullFace(GL_BACK);
    
    glViewport(0, 0,_sizeInPixel.width,_sizeInPixel.height);
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    
    glClear(GL_COLOR_BUFFER_BIT| GL_DEPTH_BUFFER_BIT);
    
    glUseProgram(_drawModel.program);
    
    GLint location= [_drawModel locationOfUniform:@"u_mvpMatrix"];
    
    ESMatrix _mvpMatrix;
    
    if (self.cube) {
        
        _mvpMatrix=[self mvpMatrix4Cube];
    }else{
    
        _mvpMatrix=[self mvpMatrix4Square];
    }
    
    ESMatrix matrix=_mvpMatrix;
    
    glUniformMatrix4fv(location, 1, GL_FALSE, (const GLfloat*)&matrix);
    
    GLint location_s_texture= [_drawModel locationOfUniform:@"inputImageTexture"];
    
    glActiveTexture(GL_TEXTURE0);
    
    glBindTexture(GL_TEXTURE_2D, _textureId);
    
    glUniform1i ( location_s_texture, 0);
    
    GLint location_position=[_drawModel locationOfAttribute:@"position"];
    
    glBindBuffer(GL_ARRAY_BUFFER, _drawModel.vertices_buffer_obj);
    
    glEnableVertexAttribArray(location_position);//顶点坐标
    
    glVertexAttribPointer(location_position, 3, GL_FLOAT, GL_FALSE,sizeof(GLfloat)*3,0);
    
    glBindBuffer(GL_ARRAY_BUFFER, _drawModel.texture_vertices_buffer_obj);
    
    GLint location_texturecoord=[_drawModel locationOfAttribute:@"inputTextureCoordinate"];
    
    glEnableVertexAttribArray(location_texturecoord);
    
    glVertexAttribPointer(location_texturecoord, 2, GL_FLOAT, GL_FALSE,sizeof(GLfloat)*2,0);//纹理坐标
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _drawModel.indices_buffer_obj);
    
    //glEnable(GL_PRIMITIVE_RESTART_FIXED_INDEX);//开启图元重启
    
    GLsizei count=_drawModel.count_indices;
    
    count=count/4;

    for (int index=0; index<count; index++) {
        
        glDrawElements(_drawModel.drawStyle, 4, GL_UNSIGNED_BYTE,(GLvoid*)(index*4));
        
    }

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    //    static dispatch_once_t onceToken;
    //    dispatch_once(&onceToken, ^{
    //
    //
    //        dispatch_queue_t t=dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0);
    //
    //        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), t, ^{
    //
    //            [self readBuffer];
    //        });
    //
    //
    //    });

    //glDrawArrays(GL_TRIANGLES, 0, sizeof(vertices_position)/sizeof(GLfloat));
    
    //glDisable(GL_PRIMITIVE_RESTART_FIXED_INDEX);
    glDisableVertexAttribArray(location_s_texture);
    glDisableVertexAttribArray(location_texturecoord);
    

    glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, _frameBuffer);
    
    glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, _resolveFrameBuffer);
    
    //glBlitFramebuffer(0, 0, _sizeInPixel.width, _sizeInPixel.height, 0, 0, _sizeInPixel.width, _sizeInPixel.height, GL_COLOR_BUFFER_BIT, GL_NEAREST);
    
    //glInvalidateFramebuffer(GL_READ_FRAMEBUFFER, 1, (GLenum[]){GL_COLOR_ATTACHMENT0});
    
    
    glResolveMultisampleFramebufferAPPLE();
    
    const GLenum discards[]  = {GL_COLOR_ATTACHMENT0};
    glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE,1,discards);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
}

/**
 *  @author 许辉泽, 16-01-13 18:21:26
 *
 *  从帧缓冲区对象读取像素数据
 *
 *  @since 1.0.2
 */
-(void)readBuffer{

    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    //glViewport(0, 0, _sizeInPixel.width, _sizeInPixel.height);
    
    GLubyte *t=malloc(_sizeInPixel.width*_sizeInPixel.height*4*sizeof(GLubyte));
    
    glReadPixels(0, 0, _sizeInPixel.width, _sizeInPixel.height, GL_RGBA, GL_UNSIGNED_BYTE, t);
    
    struct RGBA{
        
        uint8_t R;
        uint8_t G;
        uint8_t B;
        uint8_t A;
        
    };
 
    struct RGBA *tt=(struct RGBA*)t;
    
    for (int index=0; index<300; index++) {
        
        struct   RGBA pixel=tt[index];
        
         NSLog(@"r:%i g:%i b:%i a:%i",pixel.R,pixel.G,pixel.B,pixel.A);
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    free(t);

    
}

-(void)render{
    
    //[super layoutSubviews];
    
    dispatch_barrier_async(_queue, ^{
        
        long timeout=dispatch_semaphore_wait(_semaphore_t_render, DISPATCH_TIME_FOREVER);
        if (timeout==0) {
            
            [EAGLContext setCurrentContext:_context];
            
            [self renderFrame];
            
            [EAGLContext setCurrentContext:nil];
            
        }else{
        
          //  NSLog(@"超时了");
        }
        
        dispatch_semaphore_signal(_semaphore_t_render);
    
    });
    
}


-(void)cleanup{

    glDeleteBuffers(1, &_renderBuffer);
    
    glDeleteBuffers(1, &_frameBuffer);
    
    glDeleteBuffers(1, &_resolveRenderBuffer);
    
    glDeleteBuffers(1, &_resolveFrameBuffer);
    
    glDeleteBuffers(1, &_resolveDepthBuffer);
    
    glDeleteTextures(1, &_textureId);
    
}


-(void)dealloc{

    
    [self cleanup];

    if ([EAGLContext currentContext]==_context) {
        
        [EAGLContext setCurrentContext:nil];
        
    }
    
    _context=nil;
    
}

-(void)startRender{

    dispatch_semaphore_signal(_semaphore_t_render);
    
    NSLog(@"可以开始渲染了");

}


-(void)renderIfCanWhenDependencyDone:(id<YDGLOperationNode>)doneOperation{
    
    YDGLOperationNodeOutput* outData=[doneOperation getOutput];
    
    _textureId=outData.texture;
    
    [doneOperation lock];
    
    [self render];
    
    [doneOperation unlock];
    
}

-(void)addDependency:(id<YDGLOperationNode>)operation{

    [operation addNextOperation:self];

}


-(void)setCube:(BOOL)cube{

    _cube=cube;
    
    if (cube) {
        
        [self loadCubeVex];
    }else{
    
        [self loadSquareVex];
    }
    

}

-(void)activeGLContext:(void (^)(void))block{
    
    EAGLContext *preContext=[EAGLContext currentContext];
    
    if (preContext==_context) {
        
        block();
        
    }else{
        
        [EAGLContext setCurrentContext:_context];
        
        block();
        
        [EAGLContext setCurrentContext:preContext];
    }
}


@end

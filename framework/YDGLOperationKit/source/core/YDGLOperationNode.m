//
//  GLOperationLayer.m
//  test_openges
//
//  Created by 辉泽许 on 16/3/11.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationNode.h"


@implementation YDGLOperationNodeOutput

@end

@interface YDGLOperationNode()

@property(nonatomic,assign) GLuint frameBuffer;//
@property(nonatomic,assign) GLuint renderTexture_out;//
@property(nonatomic,assign) CVPixelBufferRef pixelBuffer_out;//
@property(nonatomic,assign) ESMatrix mvpMatrix;
@property(nonatomic,assign) CGSize size;//

@property(nonatomic,nullable,retain) YDDrawModel *drawModel;//

@property(nonatomic,nonnull,retain) NSMutableArray<id<YDGLOperationNode>> *nextOperations;//

@property(nonatomic,nonnull,retain) NSMutableArray<id<YDGLOperationNode>> *dependency;//

@property(nonatomic,assign) BOOL frameBufferAvailable;

@property(nonatomic,retain) dispatch_semaphore_t lockForRender;

@property(nonatomic,nullable,retain) NSMutableArray<dispatch_block_t> *programOperations;//program 的操作

@property(nonatomic,assign) CVOpenGLESTextureCacheRef coreVideoTextureCache;//纹理缓存池


@end

@implementation YDGLOperationNode{

    CVOpenGLESTextureRef _cvTextureRef;//从纹理缓存池获取的纹理对象

}

@synthesize renderTexture_out=_renderTexture_out;

@synthesize size=_size;

@synthesize frameBuffer=_frameBuffer;

@synthesize mvpMatrix=_mvpMatrix;

@synthesize nextOperations=_nextOperations;

@synthesize dependency=_dependency;

- (instancetype)init
{
    
    return [self initWithVertexShader:vShaderStr andFragmentShader:fShaderStr];
}

-(instancetype)initWithFragmentShader:(NSString *_Nonnull)fragmentShaderString{
    
    return [self initWithVertexShader:vShaderStr andFragmentShader:fragmentShaderString];
}

-(instancetype)initWithVertexShader:(NSString *_Nonnull)vertexShaderString andFragmentShader:(NSString *_Nonnull)fragmentShaderString{
    
    self = [super init];
    if (self) {
        
        [self commonInitializationWithVertexShader:vertexShaderString andFragmentShader:fragmentShaderString];
    }
    return self;
}


-(void)commonInitializationWithVertexShader:(NSString*_Nonnull)vertexShaderString andFragmentShader:(NSString*_Nonnull)fragmentShaderString{
    
    self.drawModel=[YDDrawModel new];
    
    self.nextOperations=[NSMutableArray array];
    
    self.mvpMatrix=[self mvpMatrix4Square];
    
    self.dependency=[NSMutableArray array];
    
    _glContext=[[self class] getGLContext];
    
    [self initTextureCache];
    
    self.programOperations=[NSMutableArray array];
    
    self.lockForRender=dispatch_semaphore_create(1);
    
    [self activeGLContext:^{
        
        [_drawModel setvShaderSource:[vertexShaderString UTF8String] andfShaderSource:[fragmentShaderString UTF8String]];
        
        [_drawModel loadSquareVex];

        
    }];

    _textureLoaderDelegate=self;
        
}

+(EAGLContext *)getGLContext{
    
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    static  EAGLContext *context;
    static dispatch_semaphore_t locker;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        context= [[EAGLContext alloc] initWithAPI:api];
        context.multiThreaded=YES;
        
        locker=dispatch_semaphore_create(1);
        
    });
    
    EAGLContext *instance;
    
    long success=dispatch_semaphore_wait(locker, dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC));
    
    if (success!=0) {
        
        NSLog(@"超时了");
    }
    
    instance=[[EAGLContext alloc]initWithAPI:context.API sharegroup:context.sharegroup];
    
    dispatch_semaphore_signal(locker);
        
    return context;//使用instance的话7.1.2的真机会有问题
}

+(dispatch_queue_t)getWorkQueue{

    static dispatch_queue_t workQueue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        workQueue=dispatch_queue_create([@"GLOperationKit工作线程" UTF8String],DISPATCH_QUEUE_SERIAL);
        
    });
    
    return workQueue;

}

-(void)setupBuffer{
    
    if (_frameBufferAvailable) {
        
        return;
    }
    
    glDeleteFramebuffers(1, &_frameBuffer);
    
    glDeleteTextures(1, &_renderTexture_out);
    
    glGenFramebuffers(1, &_frameBuffer);
    

    //TODO:glGenTextures(1, &_renderTexture_out);
    //上面那种方式创建的纹理会导致美艳算法在iOS8.4以下的机器上无效
    
    [self createRenderTexture];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    glActiveTexture(GL_TEXTURE0);
    
    glBindTexture(CVOpenGLESTextureGetTarget(_cvTextureRef), CVOpenGLESTextureGetName(_cvTextureRef));
    _renderTexture_out = CVOpenGLESTextureGetName(_cvTextureRef);
    
    glTexImage2D(GL_TEXTURE_2D, 0 ,GL_RGBA, (int)_size.width, (int)_size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    //TODO 一定要加上这2句话
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D, _renderTexture_out, 0);
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    self.frameBufferAvailable=YES;
}


-(void)setTransform:(ESMatrix)transformMatrix{
    
    self.mvpMatrix=transformMatrix;
    
}

-(ESMatrix)mvpMatrix4Square{
    
    ESMatrix modelview;
    
    // Generate a model view matrix to rotate/translate the cube
    esMatrixLoadIdentity ( &modelview );
    
    // Translate away from the viewer
    //esTranslate (&modelview, 0, 0,-3.0);
    
    return modelview;
    
}

-(void)render{
    
    dispatch_semaphore_wait(_lockForRender, DISPATCH_TIME_FOREVER);
    
    [self setupBuffer];

    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    //glEnable(GL_CULL_FACE);
    
    //glCullFace(GL_BACK);
    
    glViewport(0, 0,_size.width,_size.height);
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    
    glClear(GL_COLOR_BUFFER_BIT| GL_DEPTH_BUFFER_BIT);
    
    glUseProgram(_drawModel.program);
    
    for (int index=0; index<_programOperations.count; index++) {
        
        dispatch_block_t operation=[_programOperations objectAtIndex:index];
        
        operation();
        
    }
    
    //1.设置顶点坐标
    
    GLint location_position=glGetAttribLocation(_drawModel.program, [UNIFORM_POSITION UTF8String]);
    
    glBindBuffer(GL_ARRAY_BUFFER, _drawModel.vertices_buffer_obj);
    
    glEnableVertexAttribArray(location_position);//顶点坐标
    
    glVertexAttribPointer(location_position, 3, GL_FLOAT, GL_FALSE,sizeof(GLfloat)*3,0);
    
    //2.设置纹理坐标
    
    glBindBuffer(GL_ARRAY_BUFFER, _drawModel.texture_vertices_buffer_obj);
    
    [self setTextureCoord];
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    //3.设置纹理
    
    [self setupTextureForProgram:_drawModel.program];
    
    //4.设置变换矩阵
    GLint location= glGetUniformLocation(_drawModel.program, [UNIFORM_MATRIX UTF8String]);
    
    ESMatrix matrix=self.mvpMatrix;
    
    glUniformMatrix4fv(location, 1, GL_FALSE, (const GLfloat*)&matrix);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _drawModel.indices_buffer_obj);
    
    GLsizei count=_drawModel.count_indices;
    
    count=count/4;
    
    
    for (int index=0; index<count; index++) {
        
        glDrawElements(_drawModel.drawStyle, 4, GL_UNSIGNED_BYTE,(GLvoid*)(index*4));
        
    }

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    //glDisableVertexAttribArray(location_s_texture);
    
    //glDisableVertexAttribArray(location_texturecoord);
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    //glFlush();

    dispatch_semaphore_signal(_lockForRender);


    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        if (self.operationCompletionBlock) {
            
            self.operationCompletionBlock([self getOutput]);
            
        }
        
    });
    
    [self.nextOperations enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id<YDGLOperationNode>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [obj notifyDependencyDone:self];

    }];
    
//    dispatch_async([[self class] getWorkQueue], ^{
//        
//        dispatch_apply(_nextOperations.count, [[self class] getWorkQueue], ^(size_t index) {
//           
//            NSLog(@"index%zu",index);
//            //id<GLOperation> nextOperation=[_nextOperations objectAtIndex:index];
//            
//            //[nextOperation markDependencyDone:self];
//            
//        });
//
//        
//    });

    
    
}

-(void)setTextureCoord{

    if (self.dependency.count==0) {

        GLint location_texturecoord=glGetAttribLocation(_drawModel.program, [UNIFORM_TEXTURE_COORDINATE UTF8String]);
        
        glEnableVertexAttribArray(location_texturecoord);
        
        glVertexAttribPointer(location_texturecoord, 2, GL_FLOAT, GL_FALSE,sizeof(GLfloat)*2,0);//纹理坐标
        
    }else{
    
        for (int index=0; index<_dependency.count; index++) {
            
            NSString *name=[_textureLoaderDelegate textureCoordUniformNameAtIndex:index];
            
            GLint location_texturecoord=glGetAttribLocation(_drawModel.program, [name UTF8String]);
            
            glEnableVertexAttribArray(location_texturecoord);
            
            glVertexAttribPointer(location_texturecoord, 2, GL_FLOAT, GL_FALSE,sizeof(GLfloat)*2,0);//纹理坐标
            
        }
    
    }
    
}


-(void)setupTextureForProgram:(GLuint)program{

    for (int index=0; index<self.dependency.count;index++) {
        
        YDGLOperationNodeOutput *output=[[self.dependency objectAtIndex:index] getOutput];
        
        NSString *name=[_textureLoaderDelegate textureUniformNameAtIndex:index];
        
        GLint location_s_texture= glGetUniformLocation(_drawModel.program, [name UTF8String]);
        
        glActiveTexture(GL_TEXTURE0+index);
        
        glBindTexture(GL_TEXTURE_2D, output.texture);
        
        glUniform1i ( location_s_texture,index);
        
    }
    
}

-(void)addNextOperation:(id<YDGLOperationNode>)nextOperation{
    
    [self.nextOperations addObject:nextOperation];
    
}

-(void)addDependency:(id<YDGLOperationNode>)operation{

    [self.dependency addObject:operation];
    
    [operation addNextOperation:self];

}

-(YDGLOperationNodeOutput*)getOutput{

    if (_renderTexture_out==0) {
        
        return nil;
    }
    
    YDGLOperationNodeOutput* output=[YDGLOperationNodeOutput new];
    
    output.texture=_renderTexture_out;
    
    output.size=_size;
    
    output.frameBuffer=_frameBuffer;
    
    output.pixelBuffer=_pixelBuffer_out;
    
    return output;

}

-(void)notifyDependencyDone:(id<YDGLOperationNode>)doneOperation{
    
    __block BOOL ready=YES;
    
    __block CGSize size=self.size;
    
    [self.dependency enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id<YDGLOperationNode>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        YDGLOperationNodeOutput *output=[obj getOutput];
        
        if (output==nil) {
            
            ready=NO;
            *stop=YES;
            
        }else{
            
            //使用最大的size
            if (output.size.width>size.width&&output.size.height>size.height) {
                
                size=output.size;
            }
    
        }
        
    }];
    
    if (ready) {
        
        if (size.width!=self.size.width||size.height!=self.size.height) {
            
            self.size=size;
            self.frameBufferAvailable=NO;
            
        }
        
        dispatch_async([[self class]getWorkQueue], ^{
            
            [self activeGLContext:^{
               
                [self render];
            }];

        });
    }
    
}

-(int)getUniformLocation:(NSString *)name{

    return glGetUniformLocation(_drawModel.program, [name UTF8String]);
    
}

-(int)getAttributeLocation:(NSString *)name{
    
    return glGetAttribLocation(_drawModel.program, [name UTF8String]);
    
}

-(void)setFloat:(GLfloat)newFloat forUniformName:(NSString *)uniformName{
    
    dispatch_block_t operation=^{
    
        GLint location=glGetUniformLocation(_drawModel.program, [uniformName UTF8String]);
        
        glUniform1f(location, newFloat);
    
    };
    
    [self.programOperations addObject:operation];
    
}

-(void)activeProgram:(void(^_Nullable)(GLuint))block{
    
    [self activeGLContext:^{
        
        glUseProgram(_drawModel.program);
        
        if(block){
            
            block(_drawModel.program);
            
        }
        
    }];
    
}

-(void)activeGLContext:(void (^)(void))block{

    EAGLContext *preContext=[EAGLContext currentContext];
    
    [EAGLContext setCurrentContext:_glContext];
    
    block();
    
    [EAGLContext setCurrentContext:preContext];

}


#pragma -mark  纹理加载的代理

-(NSString *)textureUniformNameAtIndex:(NSInteger)index{

    return UNIFORM_INPUTTEXTURE;

}

-(NSString *)textureCoordUniformNameAtIndex:(NSInteger)index{

    return UNIFORM_TEXTURE_COORDINATE;

}

#pragma -mark 创建纹理缓存池


-(void)initTextureCache{

    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [[self class] getGLContext], NULL, &_coreVideoTextureCache);

}

-(void)createRenderTexture{

    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, (int)_size.width, (int)_size.height, kCVPixelFormatType_32BGRA, attrs, &_pixelBuffer_out);
    if (err)
    {
        NSLog(@"FBO size: %f, %f", _size.width, _size.height);
        NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
    }
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, _coreVideoTextureCache, _pixelBuffer_out,
                                                        NULL, // texture attributes
                                                        GL_TEXTURE_2D,
                                                        GL_RGBA, // opengl format
                                                        (int)_size.width,
                                                        (int)_size.height,
                                                        GL_RGBA, // native iOS format
                                                        GL_UNSIGNED_BYTE,
                                                        0,
                                                        &_cvTextureRef);
    if (err)
    {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    CFRelease(attrs);
    CFRelease(empty);
    
    
}


-(void)dealloc{

    glDeleteBuffers(1, &_frameBuffer);
    
    glDeleteTextures(1, &_renderTexture_out);
    
    CVPixelBufferRelease(_pixelBuffer_out);

}

@end


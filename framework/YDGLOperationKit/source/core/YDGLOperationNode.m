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

@property(nonatomic,assign) BOOL needLayout;//是否需要重新计算framebuffer的大小

@property(nonatomic,nullable,retain) NSMutableArray<dispatch_block_t> *programOperations;//program 的操作

@property(nonatomic,assign) int angle;//旋转的角度


@end

@implementation YDGLOperationNode{

    CVOpenGLESTextureRef _cvTextureRef;//从纹理缓存池获取的纹理对象

}

@synthesize renderTexture_out=_renderTexture_out;

@synthesize size=_size;

@synthesize frameBuffer=_frameBuffer;

@synthesize mvpMatrix=_mvpMatrix;

@synthesize drawModel=_drawModel;

@synthesize nextOperations=_nextOperations;

@synthesize dependency=_dependency;

static CVOpenGLESTextureCacheRef coreVideoTextureCache;//纹理缓存池

+(void)load{

    [[self class] initTextureCache];

}

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
        
    self.programOperations=[NSMutableArray array];

    self.needLayout=YES;
    
    [self activeGLContext:^{
        
        [_drawModel setvShaderSource:[vertexShaderString UTF8String] andfShaderSource:[fragmentShaderString UTF8String]];
        
        [_drawModel loadSquareVex];

        
    }];

    _textureLoaderDelegate=self;
    
}

#pragma -mark 类方法

+(EAGLContext *)getGLContext{
    
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    static  EAGLContext *context;
    static dispatch_semaphore_t locker;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        context= [[EAGLContext alloc] initWithAPI:api];
        //context.multiThreaded=YES;
        
        locker=dispatch_semaphore_create(1);
        
    });
    
    /*
    EAGLContext *instance;
    
    long success=dispatch_semaphore_wait(locker, dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC));
    
    if (success!=0) {
        
        NSLog(@"超时了");
    }
    
    instance=[[EAGLContext alloc]initWithAPI:context.API sharegroup:context.sharegroup];
    
    dispatch_semaphore_signal(locker);*/
    
        
    return context;//使用instance的话7.1.2的真机会有问题
}

+(dispatch_queue_t)getWorkQueue{

    static dispatch_queue_t workQueue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        workQueue=dispatch_queue_create([@"GLOperationKit工作线程" UTF8String],DISPATCH_QUEUE_SERIAL);
        NSString * contextProxy=@"YDGLOperationKitQueueContext";
        
        dispatch_queue_set_specific(workQueue, @"YDGLOperationKit",(__bridge void *)(contextProxy), NULL);
        
    });
    
    return workQueue;

}

+(CVOpenGLESTextureCacheRef)getTextureCache{

    return coreVideoTextureCache;
}

+(void)runInWorkQueueImmediately:(dispatch_block_t)block{

    if (dispatch_get_specific(@"YDGLOperationKit")) {
        
        if (block) {
            
            block();
        }
        
    }else{
    
        dispatch_async([YDGLOperationNode getWorkQueue],block);
    
    }

}


-(void)setupFrameBuffer{
    
    if (self.needLayout==NO) {
        
        //self.size 没有发生改变的时候,是不需要重新设置framebuffer的
        
        return ;
    }
    
    glDeleteFramebuffers(1, &_frameBuffer);
    
    glDeleteTextures(1, &_renderTexture_out);
    
    glGenFramebuffers(1, &_frameBuffer);
    
    //TODO:glGenTextures(1, &_renderTexture_out);
    //上面那种方式创建的纹理会导致美艳算法在iOS8.4以下的机器上无效
    
    [self createCVPixelBufferRef:&_pixelBuffer_out andTextureRef:&_cvTextureRef withSize:_size];
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    glActiveTexture(GL_TEXTURE0);
    
    _renderTexture_out = CVOpenGLESTextureGetName(_cvTextureRef);
    
    [YDGLOperationNode bindTexture:_renderTexture_out];
    
    //注意!:这是无效的命令
    //glTexImage2D(GL_TEXTURE_2D, 0 ,GL_RGBA, (int)_size.width, (int)_size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    //TODO 一定要加上这2句话
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D, _renderTexture_out, 0);
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    self.needLayout=NO;
    
}


#pragma -mark 内部接口

-(void)activeProgram:(void(^_Nullable)(GLuint))block{
    
    [self activeGLContext:^{
        
        glUseProgram(_drawModel.program);
        
        if(block){
            
            block(_drawModel.program);
            
        }
        
    }];
    
}

-(ESMatrix)mvpMatrix4Square{
    
    ESMatrix modelview;
    
    // Generate a model view matrix to rotate/translate the cube
    esMatrixLoadIdentity ( &modelview );
    
    // Translate away from the viewer
    //esTranslate (&modelview, 0, 0,-3.0);
    
    return modelview;
    
}

-(void)createCVPixelBufferRef:(CVPixelBufferRef*)pixelBuffer andTextureRef:(CVOpenGLESTextureRef*)textureRef withSize:(CGSize)size{
    
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, (int)size.width, (int)size.height, kCVPixelFormatType_32BGRA, attrs,pixelBuffer);
    if (err)
    {
        NSLog(@"FBO size: %f, %f", size.width, size.height);
        NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
    }
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, coreVideoTextureCache, _pixelBuffer_out,
                                                        NULL, // texture attributes
                                                        GL_TEXTURE_2D,
                                                        GL_RGBA, // opengl format
                                                        (int)size.width,
                                                        (int)size.height,
                                                        GL_BGRA, // native iOS format
                                                        GL_UNSIGNED_BYTE,
                                                        0,
                                                        textureRef);
    if (err)
    {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    CFRelease(attrs);
    CFRelease(empty);
    
}

/**
 *  @author 许辉泽, 16-03-18 18:00:28
 *
 *  根据angle 属性重新计算一次size
 *
 *  @since 1.0.0
 */
-(CGSize)calculateSizeByRotatedAngle:(CGSize)size{
    
    CGSize result;
    
    switch (self.angle) {
        case 90:
        case 270:
        {
            
            result=CGSizeMake(size.height, size.width);
            
        }
            
            break;
            
        default:
            result=size;
            break;
    }
    
    return result;
    
}

/**
 *  @author 许辉泽, 16-03-24 14:29:00
 *
 *  查询改node的所有依赖是否已经完成了
 *
 *  @param maxSize  最大尺寸
 *
 *  @return
 *
 *  @since 1.0.0
 */
-(BOOL)allDependencyDoneWithMaxSize:(CGSize*)maxSize{
    
    __block BOOL done=YES;
    
    __block CGSize size=CGSizeZero;
    
    [self.dependency enumerateObjectsUsingBlock:^(id<YDGLOperationNode>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        YDGLOperationNodeOutput *output=[obj getOutput];
        
        if (output==nil) {
            
            done=NO;
            *stop=YES;
            
        }else{
            
            //使用最大的size
            if (output.size.width>size.width&&output.size.height>size.height) {
                
                size=output.size;
            }
            
        }
        
    }];
    
    if (CGSizeEqualToSize(size, CGSizeZero)==NO&&done) {
        
        *maxSize=size;
    }
    
    return done;
    
}


-(void)innerSetInputSize:(CGSize)newSize{
    
    if (newSize.width!=self.size.width||newSize.height!=self.size.height) {
        
        self.size=[self calculateSizeByRotatedAngle:newSize];
        
        [self setNeedLayout:YES];
        
        [self didSetInputSize:self.size];
        
    }
}


-(void)activeGLContext:(void (^)(void))block{
    
    EAGLContext *preContext=[EAGLContext currentContext];
    
    if (preContext==_glContext) {
        
        block();
        
    }else{
        
        [EAGLContext setCurrentContext:_glContext];
        
        block();
        
        [EAGLContext setCurrentContext:preContext];
    }
}

/**
 *  @author 许辉泽, 16-03-24 14:35:42
 *
 *  通知所有下一个node
 *
 *  @since 1.0.0
 */
-(void)notifyNextOperation{
    
    
    if (self.operationCompletionBlock) {
        
        self.operationCompletionBlock([self getOutput]);
        
    }
    
    [self.nextOperations enumerateObjectsUsingBlock:^(id<YDGLOperationNode>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [obj renderIfCanWhenDependencyDone:self];
    }];
    
    
}

#pragma -mark 支持子类重载的接口

-(void)drawFrameBuffer:(GLuint)frameBuffer inRect:(CGRect)rect{
    
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    
    //glEnable(GL_CULL_FACE);
    
    //glCullFace(GL_BACK);
    
    glViewport(rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    
    glClear(GL_COLOR_BUFFER_BIT| GL_DEPTH_BUFFER_BIT);
    
    glUseProgram(_drawModel.program);
    
    for (int index=0; index<_programOperations.count; index++) {
        
        dispatch_block_t operation=[_programOperations objectAtIndex:index];
        
        operation();
        
    }
    
    //[_programOperations removeAllObjects];//_programOperation 里面的操作只要执行一次就生效了,不需要每次render的时候赋值
    //1.设置顶点坐标
    
    GLint location_position=glGetAttribLocation(_drawModel.program, [ATTRIBUTE_POSITION UTF8String]);
    
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
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    
}

-(void)renderAndNotify{
    
    [self drawFrameBuffer:_frameBuffer inRect:CGRectMake(0, 0, _size.width, _size.height)];
    
    [self notifyNextOperation];
    
}

-(void)setTextureCoord{

    if (self.dependency.count==0) {
        
        GLint location_texturecoord=glGetAttribLocation(_drawModel.program, [ATTRIBUTE_TEXTURE_COORDINATE UTF8String]);
        
        glEnableVertexAttribArray(location_texturecoord);
        
        glVertexAttribPointer(location_texturecoord, 2, GL_FLOAT, GL_FALSE,sizeof(GLfloat)*2,0);//纹理坐标
        
    }else{
    
        for (int index=0; index<_dependency.count; index++) {
            
            NSString *name=[_textureLoaderDelegate textureCoordAttributeNameAtIndex:index];
            
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
        
        GLint location_s_texture=glGetUniformLocation(_drawModel.program, [name UTF8String]);
        
        glActiveTexture(GL_TEXTURE0+index);
        
        [YDGLOperationNode bindTexture:output.texture];
        
        glUniform1i ( location_s_texture,index);
        
    }
    
}

-(void)didSetInputSize:(CGSize)newInputSize{
    
    
    
}

#pragma -mark Node 协议的实现

-(void)lock{
    
    _locked=YES;
    
    [self.dependency enumerateObjectsUsingBlock:^(id<YDGLOperationNode>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [obj lock];
        
    }];
    
}

-(void)unlock{
    
    _locked=NO;
    
    [self.dependency enumerateObjectsUsingBlock:^(id<YDGLOperationNode>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [obj unlock];
        
    }];
    
    
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

-(void)renderIfCanWhenDependencyDone:(id<YDGLOperationNode>)doneOperation{
    
    if (_locked){
    
        return ;
    
    }
    
    //TODO:注意,以下2句代码会导致 innerSetInputSize 一直被调用,即size!=_size,allDependencyDoneWithMaxSize 逻辑有问题,需要排查
    //CGSize size=CGSizeMake(self.size.width, self.size.height);
    
    //BOOL ready =[self allDependencyDoneWithMaxSize:&size];
    
    __block BOOL ready=YES;
    
    __block CGSize size=self.size;
    
    [self.dependency enumerateObjectsUsingBlock:^(id<YDGLOperationNode>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
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
        
        RunInNodeProcessQueue(^{
            
            [self innerSetInputSize:size];
            
            [self activeGLContext:^{
                
                if(self.needLayout){
                    
                    [self setupFrameBuffer];
                    
                }
                
                [self renderAndNotify];
                
            }];

        });
    }
    
}

#pragma -mark  纹理加载的代理

-(NSString *)textureUniformNameAtIndex:(NSInteger)index{

    return UNIFORM_INPUTTEXTURE;

}

-(NSString *)textureCoordAttributeNameAtIndex:(NSInteger)index{

    return ATTRIBUTE_TEXTURE_COORDINATE;

}

#pragma -mark 创建纹理缓存池


+(void)initTextureCache{

    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [[self class] getGLContext], NULL, &coreVideoTextureCache);
    
    NSAssert(err==kCVReturnSuccess, @"创建纹理缓冲区失败%i",err);
    
}

#pragma  -mark 清理资源

-(void)destory{

    [self.dependency removeAllObjects];
    
    [self.nextOperations removeAllObjects];
    
    self.operationCompletionBlock=nil;
    
    [self.programOperations removeAllObjects];
    
    [self cleanUpTexture];

}

-(void)dealloc{

    NSLog(@"节点销毁了");
    
    [self cleanUpTexture];

}

-(void)cleanUpTexture{

    glDeleteBuffers(1, &_frameBuffer);
    
    glDeleteTextures(1, &_renderTexture_out);
    
}

#pragma -mark 对外接口

-(void)setTransform:(ESMatrix)transformMatrix{
    
    self.mvpMatrix=transformMatrix;
    
}

-(void)setFloat:(GLfloat)newFloat forUniformName:(NSString *)uniformName{
    
    dispatch_block_t operation=^{
        
        GLint location=glGetUniformLocation(_drawModel.program, [uniformName UTF8String]);

        glUniform1f(location, newFloat);
        
    };
    
    [self.programOperations addObject:operation];
    
    
}

- (void)setInt:(GLint)newInt forUniformName:(NSString *_Nonnull)uniformName{

    dispatch_block_t operation=^{
        
        GLint location=glGetUniformLocation(_drawModel.program, [uniformName UTF8String]);
        
        glUniform1i(location, newInt);
        
    };
    
    [self.programOperations addObject:operation];

}

- (void)setBool:(GLboolean)newBool forUniformName:(NSString *_Nonnull)uniformName{

    dispatch_block_t operation=^{
        
        GLint location=glGetUniformLocation(_drawModel.program, [uniformName UTF8String]);
            
        glUniform1i(location, newBool==true);
        
    };
    
    [self.programOperations addObject:operation];

}



-(void)rotateAtZ:(int)angle{
    
    RunInNodeProcessQueue(^{
        
        CGSize currentSize=self.size;
        
        self.angle=angle;
        
        esRotate(&_mvpMatrix, self.angle, 0, 0, 1.0);
        
        [self innerSetInputSize:currentSize];
        
    });
    
}

-(void)rotateAtY:(int)angle{
    
    RunInNodeProcessQueue(^{
        
        esRotate(&_mvpMatrix, angle, 0.0, 1.0, 0.0);
        
    });
    
}

+(void)bindTexture:(GLuint)textureId{

    glBindTexture(GL_TEXTURE_2D, textureId);

}

@end


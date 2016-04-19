//
//  GLOperationLayer.m
//  test_openges
//
//  Created by 辉泽许 on 16/3/11.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationNode.h"

#import "YDGLOperationContext.h"

@implementation YDGLOperationNodeOutput

@end

@interface YDGLOperationNode()

@property(nonatomic,assign) GLuint frameBuffer;//
@property(nonatomic,assign) GLuint renderTexture_out;//
@property(nonatomic,assign) CVPixelBufferRef pixelBuffer_out;//
@property(nonatomic,assign) GLKMatrix4 projectionMatrix;
@property(nonatomic,assign) GLKMatrix4  modelViewMatrix;

@property(nonatomic,nullable,retain) YDDrawModel *drawModel;//

@property(nonatomic,nonnull,retain) NSMutableArray<id<YDGLOperationNode>> *nextOperations;//

@property(nonatomic,nonnull,retain) NSMutableArray<id<YDGLOperationNode>> *dependency;//

@property(nonatomic,assign) BOOL needLayout;//是否需要重新计算framebuffer的大小

@property(nonatomic,nullable,retain) NSMutableArray<dispatch_block_t> *programOperations;//program 的操作

@property(nonatomic,nullable,retain) NSMutableArray<dispatch_block_t> *beforePerformTraversalsOperations;//traversals 的操作

@property(nonatomic,nullable,retain) NSMutableArray<dispatch_block_t> *beforePerformDrawOperations;//draw 的操作

@property(nonatomic,nullable,retain)dispatch_semaphore_t lockForNodeStatus;

@property(nonatomic,nullable,retain)dispatch_semaphore_t lockForTraversals;//TODO:后续看看能不能和lockForNode合并成一个锁

@property(nonatomic,assign) int angle;//旋转的角度


@property(nonatomic,assign) CVOpenGLESTextureCacheRef coreVideoTextureCache;

@property(nonatomic,retain)YDGLOperationNodeOutput *outputData;//this Node output;

@end

@implementation YDGLOperationNode{

    CVOpenGLESTextureRef _cvTextureRef;//从纹理缓存池获取的纹理对象

}

@synthesize renderTexture_out=_renderTexture_out;

@synthesize size=_size;

@synthesize frameBuffer=_frameBuffer;

@synthesize modelViewMatrix=_modelViewMatrix;

@synthesize drawModel=_drawModel;

@synthesize nextOperations=_nextOperations;

@synthesize dependency=_dependency;

@synthesize outputData=_outputData;

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
    
    self.dependency=[NSMutableArray array];
    
    _glContext=[YDGLOperationContext currentGLContext];
    
    NSAssert(_glContext!=nil, @"did you forgot call [YDGLOperationContext pushContext] ?");
        
    self.programOperations=[NSMutableArray array];

    self.beforePerformDrawOperations=[NSMutableArray array];
    
    self.beforePerformTraversalsOperations=[NSMutableArray array];
    
    self.needLayout=YES;
    
    self.lockForNodeStatus=dispatch_semaphore_create(1);
    
    self.lockForTraversals=dispatch_semaphore_create(1);
    
    [self initTextureCache];
    
    [self activeGLContext:^{
        
        [_drawModel setvShaderSource:[vertexShaderString UTF8String] andfShaderSource:[fragmentShaderString UTF8String]];
        
        [_drawModel loadSquareVex];

        
    }];

    _textureLoaderDelegate=self;
    
    [self loadProjectionMatrix];
    
}

#pragma -mark 类方法

+(dispatch_queue_t)getWorkQueue{

    static dispatch_queue_t workQueue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        workQueue=dispatch_queue_create([@"GLOperationKit工作线程" UTF8String],DISPATCH_QUEUE_CONCURRENT);
        NSString * contextProxy=@"YDGLOperationKitQueueContext";
        
        dispatch_queue_set_specific(workQueue, @"YDGLOperationKit",(__bridge void *)(contextProxy), NULL);
        
    });
    
    return workQueue;

}

-(void)initTextureCache{
    
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL,_glContext, NULL, &_coreVideoTextureCache);
    
    NSAssert(err==kCVReturnSuccess, @"创建纹理缓冲区失败%i",err);
    
}

+(void)bindTexture:(GLuint)textureId{
    
    glBindTexture(GL_TEXTURE_2D, textureId);
    
}

#pragma -mark 内部接口

-(void)setupFrameBuffer{
    
    [self cleanUpTexture];
    
    if (_frameBuffer==0) {
        
        glGenFramebuffers(1, &_frameBuffer);
    }
    
    //注意:glGenTextures(1, &_renderTexture_out);
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
    
}

-(void)activeProgram:(void(^_Nullable)(GLuint))block{
    
    [self activeGLContext:^{
        
        glUseProgram(_drawModel.program);
        
        if(block){
            
            block(_drawModel.program);
            
        }
        
    }];
    
}

/**
 *  @author 9527, 16-04-18 20:44:05
 *
 *  set projection matrix
 *
 *  @return
 *
 *  @since 
 */
-(void)loadProjectionMatrix{
    
    CGSize virtualSize=CGSizeMake(2.0, 2.0);//近平面的窗口和opengl的坐标系窗口重叠,因为顶点坐标的赋值方式导致需要设置这么一个virtualSize
    
    float aspect=virtualSize.width/virtualSize.height;
    float nearZ=virtualSize.height/2;
    
    float farZ=nearZ+10;
    
    GLKMatrix4 projection=GLKMatrix4MakePerspective(M_PI_2, aspect, nearZ, farZ);
    
    _projectionMatrix=projection;

    GLKMatrix4 modelView=GLKMatrix4Identity;
    
    modelView=GLKMatrix4Translate(modelView, 0.0, 0.0, -nearZ);//移动到视锥体内,原点是(0,0,-nearZ-2)
    
    _modelViewMatrix=modelView;
   
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
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, _coreVideoTextureCache, _pixelBuffer_out,
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
-(CGSize)fixedRenderSizeByRotatedAngle:(CGSize)size{
    
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
-(BOOL)allDependencyDone{
    
    if (self.dependency.count==0)return NO;
    
    __block BOOL done=YES;
    
    [self.dependency enumerateObjectsUsingBlock:^(id<YDGLOperationNode>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        YDGLOperationNodeOutput *output=[obj getOutput];
        
        if (output==nil) {
            
            done=NO;
            *stop=YES;
            
        }
    }];
    
    
    return done;
    
}

/**
 *  @author 许辉泽, 16-04-08 18:06:52
 *
 *  根据依赖的node计算该节点的尺寸,目前的策略是 size of first dependency node
 *
 *  @return node size
 *
 *  @since
 */
-(CGSize)calculateRenderSize{
    
    YDGLOperationNodeOutput *firstNodeOutput= [[self.dependency firstObject] getOutput];

    return firstNodeOutput.size;
    
}

-(void)innerSetInputSize:(CGSize)newSize{
    
    _size=newSize;
    
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
    
    if (self.completionBlock) {
        
        self.completionBlock([self getOutput]);
        
    }
    
    dispatch_semaphore_wait(_lockForNodeStatus, DISPATCH_TIME_FOREVER);
    
    NSArray<id<YDGLOperationNode>> *nextoperations= [self.nextOperations copy];
    
    dispatch_semaphore_signal(_lockForNodeStatus);
    
    for (id<YDGLOperationNode>  nextOperation in nextoperations) {
        
        [nextOperation performTraversalsIfCanWhenDependencyDone:self];
        
    }
    
}

-(void)beforePerformTraversals{

    for (dispatch_block_t layoutOperation in self.beforePerformTraversalsOperations) {
        
        layoutOperation();
        
    }
    
    [self.beforePerformTraversalsOperations removeAllObjects];//线程同步问题

}

-(void)performTraversals{
    
    CGSize renderSize=[self calculateRenderSize];
    
    if (CGSizeEqualToSize(CGSizeZero, renderSize)) {
        
        renderSize=_size;
    }
    
    CGSize fixedRenderSize=[self fixedRenderSizeByRotatedAngle:renderSize];//需要把角度考虑进行,不然带旋转的node 的CGSizeEqualToSize 会一直是false
    
    [self willSetNodeSize:&fixedRenderSize];

    if (CGSizeEqualToSize(CGSizeZero,fixedRenderSize)==false&&CGSizeEqualToSize(fixedRenderSize, _size)==false) {
        
        [self setNeedLayout:YES];
        
    }
    
    [self activeGLContext:^{
        
        if(self.needLayout){
            
            [self innerSetInputSize:fixedRenderSize];
            
            [self performLayout];
            
            [self setNeedLayout:NO];
            
        }
        
        [self beforePerformDraw];
        
        [self performDraw];
        
    }];
    
    
    [self buildOutputData];
    
    [self notifyNextOperation];

    
    
}

-(void)performLayout{
    
    //NSAssert(self.needLayout==YES, @"不需要调用 performLayout");
    
    [self setupFrameBuffer];

}
-(void)beforePerformDraw{
    
    for (dispatch_block_t drawOperation in self.beforePerformDrawOperations) {
        
        drawOperation();
        
    }
    
    [self.beforePerformDrawOperations removeAllObjects];//线程同步问题
    
}

-(void)performDraw{
    
    assert(_frameBuffer!=0);
    
    [self drawFrameBuffer:_frameBuffer inRect:CGRectMake(0, 0, _size.width, _size.height)];
    
}

-(void)buildOutputData{

    YDGLOperationNodeOutput* output=[YDGLOperationNodeOutput new];
    
    output.texture=_renderTexture_out;
    
    output.size=_size;
    
    output.frameBuffer=_frameBuffer;
    
    output.pixelBuffer=_pixelBuffer_out;
    
    self.outputData=output;
    
}

/**
 *  @author 许辉泽, 16-04-09 15:24:14
 *
 *  if the block will change the node status,shoule use this api to run the block
 *
 *  @param block block will change the node status
 *
 *  @since 1.0.0
 */
-(void)lockNodeFor:(dispatch_block_t)block{

    dispatch_semaphore_wait(_lockForNodeStatus, DISPATCH_TIME_FOREVER);
    
    block();
    
    dispatch_semaphore_signal(_lockForNodeStatus);
    
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
    
    [_programOperations removeAllObjects];//_programOperation 里面的操作只要执行一次就生效了,不需要每次render的时候赋值
    
    //1.设置变换矩阵
    GLint location= glGetUniformLocation(_drawModel.program, [UNIFORM_MATRIX UTF8String]);
    
    GLKMatrix4 matrix=GLKMatrix4Multiply(_projectionMatrix, _modelViewMatrix);
    
    float*mm=(float*)matrix.m;
    
    GLfloat* finalMatrix=malloc(sizeof(GLfloat)*16);
    
    for (int index=0; index<16; index++) {
        
        finalMatrix[index]=(GLfloat)mm[index];
        
    }
    
    glUniformMatrix4fv(location, 1, GL_FALSE, (const GLfloat*)finalMatrix);
    
    free(finalMatrix);
    
    //2.设置顶点坐标
    
    GLint location_position=glGetAttribLocation(_drawModel.program, [ATTRIBUTE_POSITION UTF8String]);
    
    glBindBuffer(GL_ARRAY_BUFFER, _drawModel.vertices_buffer_obj);
    
    glEnableVertexAttribArray(location_position);//顶点坐标
    
    glVertexAttribPointer(location_position, 3, GL_FLOAT, GL_FALSE,sizeof(GLfloat)*3,0);
    
    //3.设置纹理坐标
    
    glBindBuffer(GL_ARRAY_BUFFER, _drawModel.texture_vertices_buffer_obj);
    
    [self setTextureCoord];
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    //4.设置纹理
    
    [self setupTextureForProgram:_drawModel.program];
    
    
    //5. draw
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _drawModel.indices_buffer_obj);
    
    GLsizei count=_drawModel.count_indices;
    
    count=count/4;
    
    for (int index=0; index<count; index++) {
        
        glDrawElements(_drawModel.drawStyle, 4, GL_UNSIGNED_BYTE,(const GLvoid*)(index*4*sizeof(GLubyte)));
        
    }
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
}

/**
 *  @author 许辉泽, 16-04-08 17:36:00
 *
 *  设置纹理坐标
 *  注意:绘制图元的时候,是从左下角开始,按照GL_TRIANGLE_FAN方式,逆时针绘制的
 *
 *
 *  @since 1.0.0
 */
-(void)setTextureCoord{

    for (int index=0; index<_dependency.count; index++) {
        
        NSString *name=[_textureLoaderDelegate textureCoordAttributeNameAtIndex:index];
        
        GLint location_texturecoord=glGetAttribLocation(_drawModel.program, [name UTF8String]);
        
        glEnableVertexAttribArray(location_texturecoord);
    
        glVertexAttribPointer(location_texturecoord, 2, GL_FLOAT, GL_FALSE,sizeof(GLfloat)*2,0);//纹理坐标
        
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

-(void)willSetNodeSize:(CGSize*_Nonnull)newInputSize{
    
    
    
}

-(BOOL)canPerformTraversals{

    return [self allDependencyDone];

}

#pragma -mark Node 协议的实现

-(void)addNextOperation:(id<YDGLOperationNode>)nextOperation{
    
    [self.nextOperations addObject:nextOperation];
    
}

-(void)addDependency:(id<YDGLOperationNode>)operation{

    [self.dependency addObject:operation];
    
    [operation addNextOperation:self];

}

-(void)removeDependency:(id<YDGLOperationNode>)operation{

    [_dependency removeObject:operation];

}

-(void)removeNextOperation:(id<YDGLOperationNode>)nextOperation{

    [_nextOperations removeObject:nextOperation];

}

-(YDGLOperationNodeOutput*)getOutput{

    return self.outputData;

}

-(void)performTraversalsIfCanWhenDependencyDone:(id<YDGLOperationNode>)doneOperation{
    
    
    dispatch_semaphore_wait(_lockForNodeStatus,DISPATCH_TIME_FOREVER);
    BOOL ready =[self canPerformTraversals];
    dispatch_semaphore_signal(_lockForNodeStatus);
    
    if (ready) {
        
        if(dispatch_semaphore_wait(_lockForTraversals, DISPATCH_TIME_NOW)==0){
            
            [self beforePerformTraversals];
            
            [self performTraversals];
            
            dispatch_semaphore_signal(_lockForTraversals);
        }
        
    }
    
}

#pragma -mark  纹理加载的代理

-(NSString *)textureUniformNameAtIndex:(NSInteger)index{

    return UNIFORM_INPUTTEXTURE;

}

-(NSString *)textureCoordAttributeNameAtIndex:(NSInteger)index{

    return ATTRIBUTE_TEXTURE_COORDINATE;

}

#pragma  -mark 清理资源

-(void)destory{

    dispatch_semaphore_wait(_lockForNodeStatus, DISPATCH_TIME_FOREVER);
    
    [self.dependency removeAllObjects];
    
    [self.nextOperations removeAllObjects];
    
    [self.programOperations removeAllObjects];
    
    dispatch_semaphore_signal(_lockForNodeStatus);
    
    self.completionBlock=nil;
}

-(void)dealloc{

    NSLog(@"节点销毁了:%@",self);
    
    [self activeGLContext:^{
       
        [self cleanUpTexture];
        
        glDeleteFramebuffers(1, &_frameBuffer);
    }];
    
    _frameBuffer=0;
    
    [_beforePerformDrawOperations removeAllObjects];
    
    [_beforePerformTraversalsOperations removeAllObjects];
    
    [_programOperations removeAllObjects];
    
    CVOpenGLESTextureCacheFlush(_coreVideoTextureCache, 0);
    
    CFRelease(_coreVideoTextureCache);
    
    _coreVideoTextureCache=NULL;
    

}

-(void)cleanUpTexture{
    
    if (_cvTextureRef) {
        
        CVPixelBufferRelease(_cvTextureRef);
        
        _cvTextureRef=NULL;
    }
    
    if (_pixelBuffer_out!=NULL) {
        
        CVPixelBufferRelease(_pixelBuffer_out);
        
        _pixelBuffer_out=NULL;
    }
    
    _renderTexture_out=0;
    
}

#pragma -mark 对外接口

-(void)setFloat:(GLfloat)newFloat forUniformName:(NSString *)uniformName{
    
    dispatch_block_t operation=^{
        
        GLint location=glGetUniformLocation(_drawModel.program, [uniformName UTF8String]);

        glUniform1f(location, newFloat);
        
    };
    
    
    [self lockNodeFor:^{
        
        [self.programOperations addObject:operation];
    }];
    
}

- (void)setInt:(GLint)newInt forUniformName:(NSString *_Nonnull)uniformName{

    dispatch_block_t operation=^{
        
        GLint location=glGetUniformLocation(_drawModel.program, [uniformName UTF8String]);
        
        glUniform1i(location, newInt);
        
    };
    
    
    [self lockNodeFor:^{
        
        [self.programOperations addObject:operation];
        
    }];
    

}

- (void)setBool:(GLboolean)newBool forUniformName:(NSString *_Nonnull)uniformName{

    dispatch_block_t operation=^{
        
        GLint location=glGetUniformLocation(_drawModel.program, [uniformName UTF8String]);
            
        glUniform1i(location, newBool==true);
        
    };
    
    [self lockNodeFor:^{
        
        [self.programOperations addObject:operation];
        
    }];

}



-(void)rotateAtZ:(RotateOption)option{
    
    int localAngle=[self calculateAngleFromRotateOption:option];

    dispatch_block_t rotateLayoutOperation=^{
        
        self.angle=localAngle;
        
    };
    
    [self.beforePerformTraversalsOperations addObject:rotateLayoutOperation];
    
    dispatch_block_t rotateDrawOperation=^{
        
        _modelViewMatrix=GLKMatrix4Rotate(_modelViewMatrix, GLKMathDegreesToRadians(self.angle), 0.0, 0.0, 1.0);
    
    };
    
    [self lockNodeFor:^{
    
        [self.beforePerformDrawOperations addObject:rotateDrawOperation];
        
    }];
    
}

-(void)rotateAtY:(RotateOption)option{
    
    int localAngle=[self calculateAngleFromRotateOption:option];

    dispatch_block_t rotateDrawOperation=^{
                
        _modelViewMatrix=GLKMatrix4Rotate(_modelViewMatrix, GLKMathDegreesToRadians(localAngle), 0.0, 1.0, 0.0);
        
    };
    
    [self lockNodeFor:^{
        
        [self.beforePerformDrawOperations addObject:rotateDrawOperation];
        
    }];

}

-(int)calculateAngleFromRotateOption:(RotateOption)option{
    
    int localOption=option%4;
    
    switch (localOption) {
        case RotateOption_DEFAULT:
        case RotateOption_TWO_M_PI:
            return 0;
            break;
        case RotateOption_HALF_M_PI:
            return 90;
            break;
        case RotateOption_ONE_M_PI:
            return 180;
            break;
        case RotateOption_ONE_HALF_M_PI:
            return 270;
            break;
            
        default:
            return 0;
            break;
    }
    
}

@end


//
//  GLOperation.h
//  LiveVideo
//
//  Created by 辉泽许 on 16/3/10.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationNode.h"

/**
 *  注意:UIKit和AVFoundationKit的坐标原点在左上角,
 *  openGL ES/CGContext 的坐标原点在左下角
 *  所以该类型的节点初始化的时候是旋转了180度的
 *
 *
 *
 */
@interface YDGLOperationSourceNode :YDGLOperationNode

-(instancetype _Nonnull)initWithUIImage:(UIImage*_Nonnull)image;

-(void)uploadCVPixelBuffer:(CVPixelBufferRef _Nonnull)pixelBufferRef;

-(void)uploadImage:(UIImage *_Nonnull)image;

-(void)start;

@end

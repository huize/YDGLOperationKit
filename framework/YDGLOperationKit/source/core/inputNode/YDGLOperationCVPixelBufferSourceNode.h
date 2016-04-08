//
//  YDGLOperationCVPixelBufferSourceNode.h
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/4/8.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import <YDGLOperationKit/YDGLOperationKit.h>

@interface YDGLOperationCVPixelBufferSourceNode : YDGLOperationSourceNode

-(void)uploadCVPixelBuffer:(CVPixelBufferRef _Nonnull)pixelBufferRef;

@end

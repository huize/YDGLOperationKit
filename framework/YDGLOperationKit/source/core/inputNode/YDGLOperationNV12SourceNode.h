//
//  YDGLOperationNV12SourceNode.h
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/4/5.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import <YDGLOperationKit/YDGLOperationKit.h>
/**
 *  @author 许辉泽, 16-04-05 14:43:31
 *
 *  上传NV12格式的图像数据
 *
 *  @since 1.0.0
 */
@interface YDGLOperationNV12SourceNode : YDGLOperationSourceNode

/**
 *  @author 许辉泽, 16-04-01 16:31:00
 *
 *  上传I420格式的图像数据
 *
 *  @param baseAddress 数据指针
 *  @param dataSize    数据大小
 *  @param imageSize   图像大小
 *
 *  @since 1.0.0
 */
-(void)uploadNV12Data:(uint8_t*)baseAddress andDataSize:(size_t)dataSize andImageSize:(CGSize)imageSize;

-(void)setFullRange:(BOOL)fullRange;

-(void)setBT709:(BOOL)yes;


@end

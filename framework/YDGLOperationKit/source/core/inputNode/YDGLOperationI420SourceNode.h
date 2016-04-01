//
//  YDGLOperationI420SourceNode.h
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/4/1.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationSourceNode.h"

/**
 *  @author 许辉泽, 16-04-01 16:59:14
 *
 *  支持上传I420数据格式的sourceNode
 *
 *  @since 1.0.0
 */
@interface YDGLOperationI420SourceNode : YDGLOperationSourceNode

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
-(void)uploadI420Data:(uint8_t*)baseAddress andDataSize:(size_t)dataSize andImageSize:(CGSize)imageSize;

@end

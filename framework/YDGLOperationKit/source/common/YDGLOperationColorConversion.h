//
//  YDGLOperationColorConversion.h
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/3/19.
//  Copyright © 2016年 yifan. All rights reserved.
//

@import Foundation;

@import OpenGLES.ES2;

#ifndef YDGLOperationColorConversion_h
#define YDGLOperationColorConversion_h

extern GLfloat *kColorConversion601;
extern GLfloat *kColorConversion601FullRange;
extern GLfloat *kColorConversion709;
extern NSString *const kGPUImageYUVVideoRangeConversionForRGFragmentShaderString;
extern NSString *const kGPUImageYUVFullRangeConversionForLAFragmentShaderString;
extern NSString *const kGPUImageYUVVideoRangeConversionForLAFragmentShaderString;


#endif /* YDGLOperationColorConversion_h */

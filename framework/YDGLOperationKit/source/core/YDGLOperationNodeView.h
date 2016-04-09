//
//  CustomGLView.h
//  test_openges
//
//  Created by 辉泽许 on 16/1/4.
//  Copyright © 2016年 yifan. All rights reserved.
//

@import UIKit;
#import "YDGLOperationNode.h"

typedef enum {
    kYDGLOperationImageFillModeFillModeStretch,                       // Stretch to fill the full view, which may distort the image outside of its normal aspect ratio
    kYDGLOperationImageFillModePreserveAspectRatio,           // Maintains the aspect ratio of the source image, adding bars of the specified background color
    kYDGLOperationImageFillModePreserveAspectRatioAndFill     // Maintains the aspect ratio of the source image, zooming in on its center to fill the view
} YDGLOperationImageFillModeType;


typedef enum { kYDGLOperationImageNoRotation, kYDGLOperationImageRotateLeft, kYDGLOperationImageRotateRight, kYDGLOperationImageFlipVertical, kYDGLOperationImageFlipHorizonal, kYDGLOperationImageRotateRightFlipVertical, kYDGLOperationImageRotateRightFlipHorizontal, kYDGLOperationImageRotate180 } YDGLOperationImageRotationMode;


/**
 *  @author 许辉泽, 16-03-18 16:22:15
 *
 *  用于显示 YDGLOperationNode 操作效果的view
 *
 *  @since 1.0.0
 */
@interface YDGLOperationNodeView : UIView<YDGLOperationNode>

@property(nonatomic,assign) YDGLOperationImageFillModeType fillMode;//

@end

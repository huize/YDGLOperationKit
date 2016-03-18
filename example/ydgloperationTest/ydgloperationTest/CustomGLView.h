//
//  CustomGLView.h
//  test_openges
//
//  Created by 辉泽许 on 16/1/4.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <YDGLOperationKit/YDGLOperationKit.h>


typedef enum {
    kYDGLOperationImageFillModeFillModeStretch,                       // Stretch to fill the full view, which may distort the image outside of its normal aspect ratio
    kYDGLOperationImageFillModePreserveAspectRatio,           // Maintains the aspect ratio of the source image, adding bars of the specified background color
    kYDGLOperationImageFillModePreserveAspectRatioAndFill     // Maintains the aspect ratio of the source image, zooming in on its center to fill the view
} YDGLOperationImageFillModeType;


@interface CustomGLView : UIView<YDGLOperationNode>

@property(nonatomic,assign) BOOL cube;//

@property(nonatomic,assign) YDGLOperationImageFillModeType fillMode;//

@end

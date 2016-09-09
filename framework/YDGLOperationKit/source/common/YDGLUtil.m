//
//  YDGLUtil.m
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/9/9.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLUtil.h"

//static CGSize _ASSizeFillWithAspectRatio(CGFloat sizeToScaleAspectRatio, CGSize destinationSize);
//static CGSize _ASSizeFitWithAspectRatio(CGFloat aspectRatio, CGSize constraints);


@implementation YDGLUtil

CGSize _ASSizeFillWithAspectRatio(CGFloat sizeToScaleAspectRatio, CGSize destinationSize)
{
    CGFloat destinationAspectRatio = destinationSize.width / destinationSize.height;
    if (sizeToScaleAspectRatio > destinationAspectRatio) {
        return CGSizeMake(destinationSize.height * sizeToScaleAspectRatio, destinationSize.height);
    } else {
        return CGSizeMake(destinationSize.width, round(destinationSize.width / sizeToScaleAspectRatio));
    }
}

CGSize _ASSizeFitWithAspectRatio(CGFloat aspectRatio, CGSize constraints)
{
    CGFloat constraintAspectRatio = constraints.width / constraints.height;
    if (aspectRatio > constraintAspectRatio) {
        return CGSizeMake(constraints.width, constraints.width / aspectRatio);
    } else {
        return CGSizeMake(constraints.height * aspectRatio, constraints.height);
    }
}


@end

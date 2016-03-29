//
//  YDGLTransformUtil.m
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/3/29.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLTransformUtil.h"

@implementation YDGLTransformUtil

+(CATransform3D)Frustum:(CGFloat)left andRight:(CGFloat)right andBottom:(CGFloat)bottom andTop:(CGFloat)top andNearZ:(CGFloat)nearZ andFarZ:(CGFloat)farZ{
    
    CATransform3D identity=CATransform3DIdentity;
    
    float       deltaX = right - left;
    float       deltaY = top - bottom;
    float       deltaZ = farZ - nearZ;
    
    if ( ( nearZ <= 0.0f ) || ( farZ <= 0.0f ) ||
        ( deltaX <= 0.0f ) || ( deltaY <= 0.0f ) || ( deltaZ <= 0.0f ) )
    {
        return CATransform3DIdentity;
    }
    
    identity.m11 = 2.0f * nearZ / deltaX;
    identity.m12 = identity.m13 = identity.m14 = 0.0f;
    
    identity.m22 = 2.0f * nearZ / deltaY;
    identity.m21 = identity.m23 = identity.m24 = 0.0f;
    
    identity.m31 = ( right + left ) / deltaX;
    identity.m32 = ( top + bottom ) / deltaY;
    identity.m33 = - ( nearZ + farZ ) / deltaZ;
    identity.m34 = -1.0f;
    
    identity.m43 = -2.0f * nearZ * farZ / deltaZ;
    identity.m41 = identity.m42 = identity.m44 = 0.0f;
    
    return identity;
}


+(CATransform3D)Perspective:(CGFloat)fovy andAspect:(CGFloat)aspect andNearZ:(CGFloat)nearZ andFarZ:(CGFloat)farZ{
    
    CGFloat frustumW, frustumH;
    
    frustumH = tanf ( fovy / 360.0f * M_PI ) * nearZ;
    frustumW = frustumH * aspect;
    
    return [YDGLTransformUtil Frustum:-frustumW andRight:frustumW andBottom:-frustumH andTop:frustumH andNearZ:nearZ andFarZ:farZ];
    
}


@end

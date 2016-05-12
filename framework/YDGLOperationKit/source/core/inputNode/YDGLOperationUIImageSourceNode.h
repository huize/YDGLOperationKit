//
//  YDGLOperationUIImageSourceNode.h
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/4/8.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationSourceNode.h"

@interface YDGLOperationUIImageSourceNode : YDGLOperationSourceNode

-(void)uploadImage:(UIImage *_Nonnull)image;
/**
 *  @author 9527, 16-05-06 14:56:13
 *
 *  upload key animation images
 *
 *  @param images frame images
 *
 *  @since 1.0.0
 */
-(void)uploadAnimationableImages:(NSArray<UIImage*>* _Nonnull)images;

@end

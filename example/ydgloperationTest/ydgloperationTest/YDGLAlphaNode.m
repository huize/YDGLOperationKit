//
//  YDGLAlphaNode.m
//  ydgloperationTest
//
//  Created by 辉泽许 on 16/4/13.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLAlphaNode.h"
 NSString *_Nonnull const fAlphaShaderStr=SHADER_STRING(
                                                         precision mediump float;
                                                         
                                                         varying highp vec2 textureCoordinate;
                                                         
                                                         uniform sampler2D inputImageTexture;
                                                         
                                                         void main()
                                                         {
                                                             
                                                             vec4 color=texture2D(inputImageTexture, textureCoordinate.xy);
                                                             gl_FragColor =vec4(color.rgb,0.8);
                                                             
                                                         }
                                                         );

@implementation YDGLAlphaNode

- (instancetype)init
{
    self = [super initWithFragmentShader:fAlphaShaderStr];
    if (self) {
        
    }
    return self;
}

@end

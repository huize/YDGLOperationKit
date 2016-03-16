//
//  GLOperationTwoInputLayer.m
//  test_openges
//
//  Created by 辉泽许 on 16/3/12.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationTwoInputNode.h"

static  NSString  *_Nonnull const vTwoInputShaderStr=SHADER_STRING(
                                                          attribute vec3 position;
                                                          attribute vec2 inputTextureCoordinate_0;
                                                          attribute vec2 inputTextureCoordinate_1;
                                                          varying   vec2 textureCoordinate_0;
                                                          varying   vec2 textureCoordinate_1;
                                                          uniform  mat4 u_mvpMatrix;
                                                          void main()
                                                          {
                                                              gl_Position =u_mvpMatrix*vec4(position,1.0);
                                                              
                                                              textureCoordinate_0 = inputTextureCoordinate_0.xy;
                                                              textureCoordinate_1 = inputTextureCoordinate_1.xy;
                                                          }
                                                          
                                                          );


static  NSString *_Nonnull const fTwoInputShaderStr=SHADER_STRING(
                                                         precision mediump float;
                                                         
                                                         varying highp vec2 textureCoordinate_0;
                                                         
                                                         varying highp vec2 textureCoordinate_1;
                                                                 
                                                         uniform sampler2D inputImageTexture_0;
                                                         
                                                         uniform sampler2D inputImageTexture_1;
                                                         
                                                         uniform lowp float mixturePercent;
                                                                 
                                                         void main()
                                                         {
                                                             
                                                             lowp vec4 textureColor = texture2D(inputImageTexture_0, textureCoordinate_0);
                                                             lowp vec4 textureColor2 = texture2D(inputImageTexture_1, textureCoordinate_1);
                                                             
                                                             //gl_FragColor = vec4(mix(textureColor.rgb, textureColor2.rgb, textureColor2.a * mixturePercent), textureColor.a);
                                                             mediump float destAlpha=textureColor2.a*mixturePercent;
                                                             
                                                             mediump float r;
                                                             r=textureColor2.r*mixturePercent+textureColor.r*(1.-destAlpha);
                                                             mediump float g;
                                                             g=textureColor2.g*mixturePercent+textureColor.g*(1.-destAlpha);
                                                             mediump float b;
                                                             b=textureColor2.b*mixturePercent+textureColor.b*(1.-destAlpha);
                                                             
                                                             mediump float a = destAlpha+textureColor.a*(1.-destAlpha);
                                                             
                                                             gl_FragColor = vec4(r, g, b,a);
                                                             

                                                         }
                                                         );


@implementation YDGLOperationTwoInputNode

-(instancetype)init{

    return  [super initWithVertexShader:vTwoInputShaderStr andFragmentShader:fTwoInputShaderStr];

}

-(void)setMix:(float)mix{
    
    [self setFloat:mix forUniformName:@"mixturePercent"];

}

-(NSString *)textureCoordUniformNameAtIndex:(NSInteger)index{


    return [NSString stringWithFormat:@"inputTextureCoordinate_%i",index];
}

-(NSString *)textureUniformNameAtIndex:(NSInteger)index{

    return [NSString stringWithFormat:@"inputImageTexture_%i",index];

}


@end

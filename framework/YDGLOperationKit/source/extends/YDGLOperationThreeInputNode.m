//
//  GLOperationThreeInputLayer.m
//  test_openges
//
//  Created by 辉泽许 on 16/3/14.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationThreeInputNode.h"

@implementation YDGLOperationThreeInputNode


NSString *const kGPUImageThreeInputTextureVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 attribute vec4 inputTextureCoordinate2;
 attribute vec4 inputTextureCoordinate3;
 
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 varying vec2 textureCoordinate3;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
     textureCoordinate2 = inputTextureCoordinate2.xy;
     textureCoordinate3 = inputTextureCoordinate3.xy;
 }
 );


- (instancetype)initWithFragmentShader:(NSString *)fragmentShaderString
{
    self = [super initWithVertexShader:kGPUImageThreeInputTextureVertexShaderString andFragmentShader:fragmentShaderString];
    
    return self;
}

-(NSString *)textureCoordUniformNameAtIndex:(NSInteger)index{

    NSString *name=nil;
    
    switch (index) {
        case 0:
            
            name= @"inputTextureCoordinate";
            break;
        case 1:
            name= @"inputTextureCoordinate2";
            break;
            
        case 2:
            name= @"inputTextureCoordinate3";
            break;
        default:
            break;
    }
    
    return  name;

}


@end

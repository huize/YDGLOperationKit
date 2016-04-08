//
//  GLOperation.m
//  LiveVideo
//
//  Created by 辉泽许 on 16/3/10.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationSourceNode.h"

@implementation YDGLOperationSourceNode
 
-(void)start{
    
    //RunInNodeProcessQueue(^{
    
    [self activeGLContext:^{
        
        [self prepareForRender];
        
    }];
    
    [self renderIfCanWhenDependencyDone:self];
    
    self.textureAvailable=NO;
    
    //});
    
}

-(BOOL)canPerformTraversals{

    return self.textureAvailable;//纹理准备好之后才可以遍历
}

-(void)prepareForRender{
    
    
}

#pragma -mark 对外接口


@end

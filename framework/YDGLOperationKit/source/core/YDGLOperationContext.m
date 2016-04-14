//
//  YDGLOperationContext.m
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/4/14.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import "YDGLOperationContext.h"

#import "YDGLOperationNode.h"

@implementation YDGLOperationContext

NSMutableOrderedSet<EAGLContext*>* contexts;

+(void)initialize{

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        contexts=[NSMutableOrderedSet orderedSet];
        
        
        
    });

}

+(void)pushContext{
    
    EAGLContext *instance=[[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    [contexts addObject:instance];
    
}

+(void)popContext{

    [contexts removeObjectAtIndex:contexts.count-1];

}

+(EAGLContext *)currentGLContext{

    return [YDGLOperationNode getGLContext];

}

@end

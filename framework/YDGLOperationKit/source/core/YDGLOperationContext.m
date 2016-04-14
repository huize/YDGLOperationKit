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
    
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    static dispatch_semaphore_t locker;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        locker=dispatch_semaphore_create(1);
        
    });
    
    EAGLContext *instance;
    
    dispatch_semaphore_wait(locker,DISPATCH_TIME_FOREVER);
    
    instance=[[EAGLContext alloc]initWithAPI:api];
    
    dispatch_semaphore_signal(locker);
    
    
    [contexts addObject:instance];
    
}

+(void)popContext{

    [contexts removeObjectAtIndex:contexts.count-1];

}

+(EAGLContext *)currentGLContext{

    return [contexts lastObject];//使用instance的话,需要调用glFlush()
    
}

@end

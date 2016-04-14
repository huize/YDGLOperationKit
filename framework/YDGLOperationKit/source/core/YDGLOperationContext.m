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

static NSMutableOrderedSet<EAGLContext*>* contexts;

static dispatch_semaphore_t s_lock;


+(void)initialize{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        contexts=[NSMutableOrderedSet orderedSet];
        
        s_lock=dispatch_semaphore_create(1);
        
    });
    
}

+(void)pushContext{
    
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    
    EAGLContext *instance;
    
    instance=[[EAGLContext alloc]initWithAPI:api];
    
    dispatch_semaphore_wait(s_lock,DISPATCH_TIME_FOREVER);
    
    [contexts addObject:instance];
    
    [EAGLContext setCurrentContext:instance];
    
    dispatch_semaphore_signal(s_lock);
    
    
}

+(void)popContext{
    
    dispatch_semaphore_wait(s_lock, DISPATCH_TIME_FOREVER);
    
    [contexts removeObjectAtIndex:contexts.count-1];
    
    EAGLContext *instance=[contexts lastObject];
    
    [EAGLContext setCurrentContext:instance];
    
    dispatch_semaphore_signal(s_lock);
    
}

+(EAGLContext *)currentGLContext{
    
    EAGLContext *instance;
    
    dispatch_semaphore_wait(s_lock,DISPATCH_TIME_FOREVER);
    
    instance=[contexts lastObject];
    
    dispatch_semaphore_signal(s_lock);
    
    return instance;
    
}

@end

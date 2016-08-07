//
//  YDGLOperationLogger.h
//  YDGLOperationKit
//
//  Created by 辉泽许 on 16/8/7.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 *  @author 9527, 16-08-07 14:39:46
 *
 *  util for log to file in documents
 *
 *  @since 1.0.0
 */
@interface YDGLOperationLogger : NSObject

+(instancetype)shareInstance;

@property(nonatomic,assign)BOOL enable;

-(void)log:(NSString *)formatStr,...NS_FORMAT_FUNCTION(1,2);

@end

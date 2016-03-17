//
//  LVECatpureSessionHelper.h
//  LiveVideo
//
//  Created by 辉泽许 on 16/3/10.
//  Copyright © 2016年 yifan. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AVCaptureVideoDataOutputSampleBufferDelegate;
/**
 *  @author 许辉泽, 16-03-10 16:48:46
 *
 *  视频拍摄工具类
 *
 *  @since 1.0.0
 */
@interface LVECatpureSessionHelper : NSObject

/**
 *  @author 许辉泽, 16-03-10 16:17:30
 *
 *  开始拍摄
 *
 *  @since 1.0.0
 */
-(void)startRunning;

/**
 *  @author 许辉泽, 16-03-10 16:19:17
 *
 *  设置视频画面的代理
 *
 *  @param bufferDelegate
 *  @param queue
 *
 *  @since 1.0.0
 */
-(void)setSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)bufferDelegate queue:(dispatch_queue_t) queue;
/**
 *  @author 许辉泽, 16-03-10 16:20:58
 *
 *  停止拍摄
 *
 *  @since 1.0.0
 */
-(void)stopRunning;

/**
 *  @author 许辉泽, 16-03-10 16:26:31
 *
 *  切换摄像头,一开始默认是前置摄像头的
 *
 *  @since 1.0.0
 */
-(void)swatchCamera;

@end

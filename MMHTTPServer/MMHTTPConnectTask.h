//
//  MMHTTPConnectTask.h
//  Demo
//
//  Created by Tank on 08/06/2017.
//  Copyright © 2017 konka. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMHTTPRequestHandler.h"
#import "MMHTTPConfig.h"
#import "GCDAsyncSocket.h"

@class MMHTTPConnectTask;

typedef void(^ZGHTTPTaskCompleteBlock)(MMHTTPConnectTask *task);
/**
 * 用于处理每一个连接任务，通过TCP连接完成数据的收发
 */
@interface MMHTTPConnectTask : NSObject

+ (instancetype)initWithConfig:(MMHTTPConfig *)config
                        socket:(GCDAsyncSocket *)socket
                      complete:(ZGHTTPTaskCompleteBlock)completeBlock;

- (instancetype)initWithConfig:(MMHTTPConfig *)config
                        socket:(GCDAsyncSocket *)socket
                      complete:(ZGHTTPTaskCompleteBlock)completeBlock;

- (void)execute;

@end

@interface MMHTTPConfig (ZGHTTPPrivateAPI)

@property(nonatomic, strong) dispatch_queue_t taskQueue;

@end

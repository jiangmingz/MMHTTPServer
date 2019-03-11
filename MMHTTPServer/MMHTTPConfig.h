//
//  MMHTTPConfig.h
//  Demo
//
//  Created by Tank on 08/06/2017.
//  Copyright © 2017 Tank. All rights reserved.
// 用于配置一些HTTP服务的初始化信息如端口、根目录、委托源等

#import <Foundation/Foundation.h>

@class ZGHTTPRequestHead;

/**
 该协议用于请求权限控制，以及POST、PUT等方法修改本地资源时的控制，若不实现这些委托方法，将按默认方式处理
 */
@protocol ZGHTTPRequestDelegate <NSObject>
@optional
/**
 请求头解析完成

 @param head 请求头信息
 */
- (void)requestHeadFinish:(ZGHTTPRequestHead *)head;


/**
  请求体读取完成

 @param head 请求头信息
 */
- (void)requestBodyFinish:(ZGHTTPRequestHead *)head;

/**
 请求权限控制

 @param head 请求头信息
 @return 是否拒绝该请求
 */
- (BOOL)requestRefuse:(ZGHTTPRequestHead *)head;


/**
 请求体写入路径重定向，POST，PUT使用

 @param path 将要写入的本地路径
 @param head 请求头信息
 @return 重定向的本地路径
 */
- (NSString *)requestBodyDataWritePath:(NSString *)path head:(ZGHTTPRequestHead *)head;

/**
 写数据
 */
- (void)requestBodyData:(NSData *)data
               atOffset:(u_int64_t)offset
               filePath:(NSString *)path
                   head:(ZGHTTPRequestHead *)head;


/**
 出现错误
 */
- (void)requestBodyDataError:(NSError *)error
                        head:(ZGHTTPRequestHead *)head;


@end


@class ZGHTTPResourceInfo;

@protocol ZGHTTPResponseDelegate <NSObject>

@optional
- (void)startLoadResource:(ZGHTTPRequestHead *)head;

- (void)finishLoadResource:(ZGHTTPRequestHead *)head;

- (BOOL)shouldUsedDelegate:(ZGHTTPRequestHead *)head;

- (NSString *)redirect:(ZGHTTPRequestHead *)head;

- (NSString *)resourceRelativePath:(ZGHTTPRequestHead *)head;

- (BOOL)isDirectory:(ZGHTTPRequestHead *)head;

- (BOOL)isResourceExist:(ZGHTTPRequestHead *)head;

- (NSArray<ZGHTTPResourceInfo *> *)dirItemInfoList:(ZGHTTPRequestHead *)head;

- (u_int64_t)resourceLength:(ZGHTTPRequestHead *)head;

- (NSData *)readResource:(NSString *)path
                atOffset:(u_int64_t)offset
                  length:(u_int64_t)length
                    head:(ZGHTTPRequestHead *)head;
@end


@interface ZGHTTPRequestHead : NSObject

@property(nonatomic, readonly) NSString *method;
@property(nonatomic, readonly) NSString *path;
@property(nonatomic, readonly) NSString *protocol;
@property(nonatomic, readonly) NSString *version;
@property(nonatomic, readonly) NSString *host;
@property(nonatomic, readonly) NSDictionary *headDic;

@end


@interface ZGHTTPResponseHead : NSObject

@property(nonatomic, readonly) NSString *protocol;
@property(nonatomic, readonly) NSString *version;
@property(nonatomic, readonly) NSInteger stateCode;
@property(nonatomic, readonly) NSString *stateDesc;
@property(nonatomic, readonly) NSDictionary *headDic;

@end

@interface ZGHTTPResourceInfo : NSObject

@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) BOOL isDirectory;
@property(nonatomic, copy) NSString *relativeUrl;
@property(nonatomic, copy) NSString *modifyTime;
@property(nonatomic, assign) u_int64_t size;

@end


@interface MMHTTPConfig : NSObject

@property(nonatomic, assign) uint16_t port;
@property(nonatomic, copy) NSString *rootDirectory;
@property(nonatomic, weak) id <ZGHTTPRequestDelegate> requestDelegate;
@property(nonatomic, weak) id <ZGHTTPResponseDelegate> responseDelegate;

@end

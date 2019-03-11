//
//  MMHTTPRequestHandler.h
//  Demo
//
//  Created by Tank on 08/06/2017.
//  Copyright © 2017 Tank. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMHTTPConfig.h"


@interface MMHTTPRequestHandler : NSObject

@property(nonatomic, readonly) ZGHTTPRequestHead *requestHead;
@property(nonatomic, readonly) u_int64_t bodyDataLength;
@property(nonatomic, readonly) u_int64_t bodyDataOffset;


+ (instancetype)initWithHeadData:(NSData *)data
                        delegate:(id <ZGHTTPRequestDelegate>)delegate
                         rootDir:(NSString *)dir;

- (instancetype)initWithHeadData:(NSData *)data
                        delegate:(id <ZGHTTPRequestDelegate>)delegate
                         rootDir:(NSString *)dir;

//- (NSError *)refuseError;
- (NSError *)invalidError;

- (BOOL)isRequestFinish;

- (void)writeBodyData:(NSData *)data;

- (void)writeBodyDataError:(NSError *)error;

@end


@interface ZGHTTPRequestHead (ZGHTTPPrivateAPI)

+ (instancetype)initWithData:(NSData *)data;

- (instancetype)initWithData:(NSData *)data;

- (void)setMethod:(NSString *)method;

- (void)setPath:(NSString *)path;

- (void)setProtocol:(NSString *)protocol;

- (void)setVersion:(NSString *)version;

- (void)setHost:(NSString *)host;

- (void)setHeadDic:(NSDictionary *)headDic;

- (BOOL)hasRangeHead;

- (NSRange)range;

@end

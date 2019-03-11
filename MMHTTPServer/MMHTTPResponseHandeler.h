//
//  MMHTTPResponseHandeler.h
//  Demo
//
//  Created by Tank on 08/06/2017.
//  Copyright © 2017 Tank. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMHTTPConfig.h"

@interface MMHTTPResponseHandeler : NSObject

@property(nonatomic, readonly) ZGHTTPResponseHead *responseHead;
@property(nonatomic, readonly) ZGHTTPRequestHead *requestHead;
@property(nonatomic, readonly) NSError *error;
@property(nonatomic, readonly) u_int64_t bodyDataOffset;
@property(nonatomic, readonly) u_int64_t bodyDataLength;


+ (instancetype)initWithError:(NSError *)error requestHead:(ZGHTTPRequestHead *)head;

+ (instancetype)initWithRequestHead:(ZGHTTPRequestHead *)head
                           delegate:(id <ZGHTTPResponseDelegate>)delegate
                            rootDir:(NSString *)dir;

- (instancetype)initWithError:(NSError *)error requestHead:(ZGHTTPRequestHead *)head;

- (instancetype)initWithRequestHead:(ZGHTTPRequestHead *)head
                           delegate:(id <ZGHTTPResponseDelegate>)delegate
                            rootDir:(NSString *)dir;


- (BOOL)shouldConnectKeepLive;

- (BOOL)bodyEnd;

- (NSData *)readAllHeadData;

- (NSData *)readBodyData;

@end


@interface ZGHTTPResponseHead (ZGHTTPPrivateAPI)

+ (instancetype)initWithError:(NSError *)error requestHead:(ZGHTTPRequestHead *)head;

+ (instancetype)initWithRequestHead:(ZGHTTPRequestHead *)head;

- (instancetype)initWithError:(NSError *)error requestHead:(ZGHTTPRequestHead *)head;

- (instancetype)initWithRequestHead:(ZGHTTPRequestHead *)head;

- (void)setHeadValue:(NSString *)value WithField:(NSString *)field;

- (NSData *)dataOfHead;

- (void)setProtocol:(NSString *)protocol;

- (void)setVersion:(NSString *)version;

- (void)setStateCode:(NSInteger)stateCode;

- (void)setStateDesc:(NSString *)stateDesc;

- (void)setHeadDic:(NSDictionary *)headDic;

@end

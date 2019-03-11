//
//  MMHTTPServer.h
//  Demo
//
//  Created by Tank on 08/06/2017.
//  Copyright © 2017 Tank. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMHTTPConfig.h"

@interface MMHTTPServer : NSObject

@property(nonatomic, readonly) MMHTTPConfig *config;

+ (instancetype)initWithConfig:(void (^)(MMHTTPConfig *config))configBlock;

- (instancetype)initWithConfig:(void (^)(MMHTTPConfig *config))configBlock;

- (NSError *)start;

- (void)stop;

- (uint16_t)port;

- (void)setPort:(uint16_t)port;

- (NSString *)IP;

- (NSString *)urlString;

@end


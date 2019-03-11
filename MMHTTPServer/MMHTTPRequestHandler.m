//
//  MMHTTPRequestHandler.m
//  Demo
//
//  Created by Tank on 08/06/2017.
//  Copyright © 2017 Tank. All rights reserved.
//

#import "MMHTTPRequestHandler.h"


@interface MMHTTPRequestHandler ()

@property(nonatomic, strong) NSFileHandle *fileInput;
@property(nonatomic, weak) id <ZGHTTPRequestDelegate> delegate;
@property(nonatomic, copy) NSString *rootDir;
@property(nonatomic, copy) NSString *filePath;
@property(nonatomic, copy) NSString *queryStr;

@end

@implementation MMHTTPRequestHandler

+ (instancetype)initWithHeadData:(NSData *)data
                        delegate:(id <ZGHTTPRequestDelegate>)delegate
                         rootDir:(NSString *)dir {
    return [[self alloc] initWithHeadData:data delegate:delegate rootDir:dir];
}

- (instancetype)initWithHeadData:(NSData *)data
                        delegate:(id <ZGHTTPRequestDelegate>)delegate
                         rootDir:(NSString *)dir {
    if (self = [self init]) {
        _delegate = delegate;
        _rootDir = dir;
        _requestHead = [ZGHTTPRequestHead initWithData:data];
        _bodyDataOffset = 0;
        NSString *length = [_requestHead headDic][@"Content-Length"];
        if (length != nil) _bodyDataLength = strtoull([length UTF8String], NULL, 0);
        if ([_delegate respondsToSelector:@selector(requestHeadFinish:)]) {
            [_delegate requestHeadFinish:_requestHead];
        }
    }
    return self;
}

- (NSString *)filePath {
    if (!_filePath) {
        NSString *path = [_rootDir stringByAppendingPathComponent:_requestHead.path];
        if ([_delegate respondsToSelector:@selector(requestBodyDataWritePath:head:)]) {
            _filePath = [[_delegate requestBodyDataWritePath:path head:_requestHead] copy];
        } else {
            NSRange range = [path rangeOfString:@"?"];
            if (range.location == NSNotFound) _filePath = path;
            else _filePath = [path substringToIndex:range.location - 1];
        }
    }
    return _filePath;
}

- (NSString *)queryStr {
    return _queryStr;
}

- (NSError *)refuseError {
    NSError *error;
    if ([_delegate respondsToSelector:@selector(requestRefuse:)]) {
        if ([_delegate requestRefuse:_requestHead]) {
            error = [NSError errorWithDomain:@"服务器拒绝访问❌" code:404 userInfo:nil];
            return error;
        }
    }
    if ([[NSHomeDirectory() stringByDeletingLastPathComponent] rangeOfString:[self filePath]].location != NSNotFound) {
        error = [NSError errorWithDomain:@"服务器系统目录无法访问❌" code:404 userInfo:nil];
        return error;
    }
    return nil;
}


- (NSError *)invalidError {
    if (![_requestHead.protocol isEqualToString:@"HTTP"])
        return [NSError errorWithDomain:[NSString stringWithFormat:@"服务器不支持%@协议❌", _requestHead.protocol]
                                   code:501
                               userInfo:nil];
    if (![_requestHead.version isEqualToString:@"1.1"])
        return [NSError errorWithDomain:[NSString stringWithFormat:@"服务器不支持%@协议版本❌", _requestHead.version]
                                   code:501
                               userInfo:nil];
    NSError *error = [self refuseError];
    if (error) return error;
    if ([_requestHead.method isEqualToString:@"POST"] || [_requestHead.method isEqualToString:@"POST"]) {
        if (_bodyDataLength == 0)
            return [NSError errorWithDomain:[NSString stringWithFormat:@"请求参数出错，%@方法需要指定body长度❌", _requestHead.method]
                                       code:411
                                   userInfo:nil];

    }


    return nil;
}

- (BOOL)isMethodSupport {
    if ([_requestHead.method isEqualToString:@"GET"])return YES;
    if ([_requestHead.method isEqualToString:@"POST"])return YES;
    if ([_requestHead.method isEqualToString:@"PUT"])return YES;
    if ([_requestHead.method isEqualToString:@"DELETE"])return YES;
    return NO;
}


- (BOOL)isRequestFinish {
    return _bodyDataLength <= _bodyDataOffset + 1;
}

- (void)writeBodyData:(NSData *)data {
    if ([self refuseError] != nil)return;
    if ([_delegate respondsToSelector:@selector(requestBodyData:atOffset:filePath:head:)]) {
        [_delegate requestBodyData:data atOffset:_bodyDataOffset filePath:[self filePath] head:_requestHead];
    } else {
        if (_fileInput == nil) self.fileInput = [NSFileHandle fileHandleForWritingAtPath:[self filePath]];
        [self.fileInput writeData:data];
    }
    _bodyDataOffset += data.length;
    if ([self isRequestFinish]) {
        if ([_delegate respondsToSelector:@selector(requestBodyFinish:)]) [_delegate requestBodyFinish:_requestHead];
        if (self.fileInput) [self.fileInput closeFile];
    }
}

- (void)writeBodyDataError:(NSError *)error {
    if ([_delegate respondsToSelector:@selector(requestBodyFinish:)]) [_delegate requestBodyFinish:_requestHead];
    if (self.fileInput) [self.fileInput closeFile];
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation ZGHTTPRequestHead (ZGHTTPPrivateAPI)

+ (instancetype)initWithData:(NSData *)data {
    return [[self alloc] initWithData:data];
}

- (instancetype)initWithData:(NSData *)data {
    if (self = [self init]) {
        if (![self loadData:data])return nil;
    }
    return self;
}

- (BOOL)loadData:(NSData *)data {
    NSString *headStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray<NSString *> *headArray = [headStr componentsSeparatedByString:@"\r\n"];
    NSMutableDictionary *head = @{}.mutableCopy;
    __block BOOL res = YES;
    [headArray enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if (obj.length == 0)return;
        if (idx == 0) {
            NSArray *lineItems = [obj componentsSeparatedByString:@" "];
            if (lineItems.count != 3) {
                *stop = YES;
                res = NO;
                return;
            }
            self.method = lineItems[0];
            self.path = [lineItems[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSArray *array = [lineItems[2] componentsSeparatedByString:@"/"];
            if (array.count != 2) {
                *stop = YES;
                res = NO;
            }
            self.protocol = array[0];
            self.version = array[1];
            return;
        }

        NSArray *headItems = [obj componentsSeparatedByString:@": "];
        if (headItems.count != 2)return;
        head[headItems[0]] = [headItems[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }];

    self.host = head[@"Host"];
    self.headDic = head;
    return res;
}

- (BOOL)hasRangeHead {
    return [self.headDic[@"Range"] hasPrefix:@"bytes="];
}

- (NSRange)range {
    if ([self hasRangeHead]) {
        NSString *rangeStr = [self.headDic[@"Range"] stringByReplacingOccurrencesOfString:@"bytes=" withString:@""];
        NSArray *strs = [rangeStr componentsSeparatedByString:@"-"];
        NSUInteger start = [strs.firstObject unsignedIntegerValue];
        NSUInteger end = [strs.lastObject unsignedIntegerValue];
        NSUInteger length = end - start;
        length = length != 0 ? length + 1 : NSUIntegerMax;
        return NSMakeRange(start, length);
    }
    return NSMakeRange(0, 0);
}

@end

#pragma clang diagnostic pop


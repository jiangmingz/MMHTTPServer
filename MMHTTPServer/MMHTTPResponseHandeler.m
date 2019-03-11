//
//  MMHTTPResponseHandeler.m
//  Demo
//
//  Created by Tank on 08/06/2017.
//  Copyright © 2017 Tank. All rights reserved.
//

#import "MMHTTPResponseHandeler.h"
#import "MMHTTPRequestHandler.h"

@interface ZGHTTPHTMLDirectory : NSObject

@property(nonatomic, readonly) NSData *htmlData;
@property(nonatomic, readonly) NSArray<ZGHTTPResourceInfo *> *infos;

- (instancetype)initWithResources:(NSArray<ZGHTTPResourceInfo *> *)infos
                          dirName:(NSString *)name;
@end

static NSString *const ZGHTTPHTMLSortKey = @"sortType";
static NSString *const ZGHTTPHTMLNameAscending = @"name-ascending";
static NSString *const ZGHTTPHTMLNameDescending = @"name-descending";
static NSString *const ZGHTTPHTMLDateAscending = @"date-ascending";
static NSString *const ZGHTTPHTMLDateDescending = @"date-descending";
static NSString *const ZGHTTPHTMLSizeAscending = @"size-ascending";
static NSString *const ZGHTTPHTMLSizeDescending = @"size-descending";

@implementation ZGHTTPHTMLDirectory

+ (instancetype)initWithResources:(NSArray<ZGHTTPResourceInfo *> *)resources
                          dirName:(NSString *)name {
    return [[self alloc] initWithResources:resources dirName:name];
}

- (instancetype)initWithResources:(NSArray<ZGHTTPResourceInfo *> *)resources
                          dirName:(NSString *)dirPath {
    if (self = [self init]) {
        _infos = [self sortData:resources withPath:dirPath];
        NSArray *array = [dirPath componentsSeparatedByString:@"?"];
        NSString *name = array.firstObject;
        NSString *sortValue = [self getSortTypeWithPath:dirPath];
        NSString *sort = sortValue ? [NSString stringWithFormat:@"?%@=%@", ZGHTTPHTMLSortKey, sortValue] : @"";

        NSMutableString *htmlStr = @"<html>".mutableCopy;
        NSString *stylePath =
//        @"/Users/egova/Desktop/headstyle.css";
                [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"headstyle"];
        NSString *style = [NSString stringWithContentsOfFile:stylePath
                                                    encoding:NSUTF8StringEncoding
                                                       error:nil];
        NSString *title = [name lastPathComponent];
        if (title.length == 0 || [title isEqualToString:@"/"]) {
            title = @"Home";
        }
        [htmlStr appendFormat:@"<head>"
                              "<title>%@</title>"
                              "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />"
                              "<meta name=\"viewport\" content=\"initial-scale=1, maximum-scale=1, user-scalable=no, width=device-width\">"
                              "<link rel=\"shortcut icon\" href=\"/favicon.ico\"/>"
                              "%@"
                              "</head>", title, style];

        [htmlStr appendFormat:@"<body>"
                              "<h1>当前路径：%@</h1>", [self getDirWithPath:name sortStr:sort]];
        NSString *nameSort = [sortValue isEqualToString:ZGHTTPHTMLNameDescending] ? ZGHTTPHTMLNameAscending : ZGHTTPHTMLNameDescending;
        NSString *dateSort = [sortValue isEqualToString:ZGHTTPHTMLDateDescending] ? ZGHTTPHTMLDateAscending : ZGHTTPHTMLDateDescending;
        NSString *sizeSort = [sortValue isEqualToString:ZGHTTPHTMLSizeDescending] ? ZGHTTPHTMLSizeAscending : ZGHTTPHTMLSizeDescending;

        [htmlStr appendString:@"<table>"
                              "<tr>"];
        [htmlStr appendFormat:@"<th><a href=\"./.?%@=%@\">文件名</a></th>", ZGHTTPHTMLSortKey, nameSort];
        [htmlStr appendFormat:@"<th><a href=\"./.?%@=%@\">修改日期</a></th>", ZGHTTPHTMLSortKey, dateSort];
        [htmlStr appendFormat:@"<th><a href=\"./.?%@=%@\">文件大小</a></th>", ZGHTTPHTMLSortKey, sizeSort];
        [htmlStr appendString:@"</tr>"];

//        [htmlStr appendString:@"<tr>"
//                                 "<td colspan=\"3\">"
//                                     "<hr />"
//                                 "</td>"
//                             "</tr>"];

        [htmlStr appendFormat:@"<tr>"
                              "<td><a href=\"./..%@\">上一级</a></td>"
                              "<td>&nbsp;-</td>"
                              "<td>&nbsp;&nbsp;-</td>"
                              "</tr>", sort];
        [_infos enumerateObjectsUsingBlock:^(ZGHTTPResourceInfo *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            NSString *url = obj.relativeUrl, *size = [self formmatSize:obj.size];
            NSString *symble = @"📄";
            if (obj.isDirectory) {
                url = [obj.relativeUrl stringByAppendingString:@"/"];
                if (sortValue) {
                    url = [url stringByAppendingString:sort];
                }
                size = @"[DIR]";
                symble = @"📔";
            }
            [htmlStr appendFormat:@"<tr>"
                                  "<td>%@<a href=\"%@\"> %@</a></td>"
                                  "<td>&nbsp;%@</td>"
                                  "<td>&nbsp;&nbsp;%@</td>"
                                  "</tr>", symble, url, obj.name, obj.modifyTime, size];

        }];


        [htmlStr appendString:@"</table>"
                              "</pre>"
                              "</body>"
                              "</html>"];

        _htmlData = [htmlStr dataUsingEncoding:NSUTF8StringEncoding];
    }
    return self;
}

- (NSString *)formmatSize:(u_int64_t)size {
    if (size < 1024) {
        return [NSString stringWithFormat:@"%llu", size];
    } else if (size < 1024 * 1024) {
        return [NSString stringWithFormat:@"%lluK", size / 1024];
    } else if (size < 1024 * 1024 * 1024) {
        return [NSString stringWithFormat:@"%lluM", size / (1024 * 1024)];
    } else {
        return [NSString stringWithFormat:@"%lluG", size / (1024 * 1024 / 1024)];
    }
}

- (NSString *)getSortTypeWithPath:(NSString *)path {
    __block NSString *sortType;
    NSArray<NSURLQueryItem *> *items = [self getQueryItemsWithPath:path];
    [items enumerateObjectsUsingBlock:^(NSURLQueryItem *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        if ([obj.name isEqualToString:ZGHTTPHTMLSortKey]) {
            sortType = obj.value;
            *stop = YES;
        }
    }];
    return sortType;
}

- (NSArray *)sortData:(NSArray<ZGHTTPResourceInfo *> *)array withPath:(NSString *)path {
    NSString *sortType = [self getSortTypeWithPath:path];
    NSArray<ZGHTTPResourceInfo *> *resArray = [array sortedArrayUsingComparator:^NSComparisonResult(ZGHTTPResourceInfo *obj1, ZGHTTPResourceInfo *obj2) {
        NSComparisonResult res;
        if ([sortType isEqualToString:ZGHTTPHTMLNameAscending]) {
            res = [obj1.name compare:obj2.name options:NSCaseInsensitiveSearch];
        } else if ([sortType isEqualToString:ZGHTTPHTMLNameDescending]) {
            res = [obj2.name compare:obj1.name options:NSCaseInsensitiveSearch];
        } else if ([sortType isEqualToString:ZGHTTPHTMLDateAscending]) {
            res = [obj1.modifyTime compare:obj2.modifyTime options:NSCaseInsensitiveSearch];
        } else if ([sortType isEqualToString:ZGHTTPHTMLDateDescending]) {
            res = [obj2.modifyTime compare:obj1.modifyTime options:NSCaseInsensitiveSearch];
        } else if ([sortType isEqualToString:ZGHTTPHTMLSizeAscending]) {
            if (obj1.size < obj2.size) {
                res = NSOrderedAscending;
            } else if (obj1.size == obj2.size) {
                res = NSOrderedSame;
            } else {
                res = NSOrderedDescending;
            }
        } else if ([sortType isEqualToString:ZGHTTPHTMLSizeDescending]) {
            if (obj1.size > obj2.size) {
                res = NSOrderedAscending;
            } else if (obj1.size == obj2.size) {
                res = NSOrderedSame;
            } else {
                res = NSOrderedDescending;
            }
        } else {
            if (obj1.isDirectory && !obj1.isDirectory) {
                res = NSOrderedAscending;
            } else if (!obj1.isDirectory && obj1.isDirectory) {
                res = NSOrderedDescending;
            } else {
                res = NSOrderedSame;
            }
        }
        return res;
    }];
//    for (int i = 0; i < array.count; i++) {
//        NSString *str = [NSString stringWithFormat:@"%d: %@    %@\n",i,array[i].name, resArray[i].name];
//        printf([str cStringUsingEncoding:NSUTF8StringEncoding]);
//    }
    return resArray;
}

- (NSArray<NSURLQueryItem *> *)getQueryItemsWithPath:(NSString *)path {
    NSURLComponents *comp = [NSURLComponents componentsWithString:path];
    return [comp queryItems];
}

- (NSString *)getDirWithPath:(NSString *)absPath sortStr:(NSString *)sort {
    NSMutableString *htmlStr = @"".mutableCopy;
    NSString *path = [absPath hasPrefix:@"/"] ? absPath : [@"/" stringByAppendingString:absPath];
    while (![path isEqualToString:@"/"] && path.length > 0) {
        path = [path hasSuffix:@"/"] ? path : [path stringByAppendingString:@"/"];
        NSString *str = [NSString stringWithFormat:@"‣<a href=\"%@%@\">%@</a>", path, sort, [path lastPathComponent]];
        [htmlStr insertString:str atIndex:0];
        path = [path stringByDeletingLastPathComponent];
    }
    [htmlStr insertString:[NSString stringWithFormat:@"‣<a href=\"/%@\">Home</a>", sort] atIndex:0];
    return htmlStr.copy;
}
@end


@interface MMHTTPResponseHandeler ()

@property(nonatomic, weak) id <ZGHTTPResponseDelegate> delegate;
@property(nonatomic, copy) NSString *rootDir;
@property(nonatomic, copy) NSString *filePath;
@property(nonatomic, copy) NSString *queryStr;
@property(nonatomic, strong) NSData *data;
@property(nonatomic, assign) BOOL delegateEnabled;
@property(nonatomic, strong) NSFileHandle *fileOutput;

@end

@implementation MMHTTPResponseHandeler

NSUInteger const kZGHTTPDataReadMax = HUGE_VALL;


+ (instancetype)initWithError:(NSError *)error requestHead:(ZGHTTPRequestHead *)head {
    return [[self alloc] initWithError:error requestHead:head];
}

+ (instancetype)initWithRequestHead:(ZGHTTPRequestHead *)head
                           delegate:(id <ZGHTTPResponseDelegate>)delegate
                            rootDir:(NSString *)dir {
    return [[self alloc] initWithRequestHead:head delegate:delegate rootDir:dir];
}

- (instancetype)initWithError:(NSError *)error requestHead:(ZGHTTPRequestHead *)head {
    if (self = [self init]) {
        _requestHead = head;
        _error = error;
        _responseHead = [ZGHTTPResponseHead initWithError:error requestHead:head];
    }
    return self;
}

- (instancetype)initWithRequestHead:(ZGHTTPRequestHead *)head
                           delegate:(id <ZGHTTPResponseDelegate>)delegate
                            rootDir:(NSString *)dir {
    NSLog(@"%@", head.path);
//    NSLog(@"%@",head.headDic);
    if (self = [self init]) {
        _requestHead = head;
        _responseHead = [ZGHTTPResponseHead initWithRequestHead:head];
        _rootDir = [dir copy];
        _delegate = delegate;
        if (_delegateEnabled && [_delegate respondsToSelector:@selector(startLoadResource:)]) [_delegate startLoadResource:_requestHead];
        if ([self delegateCheck]) {
            [self loadData];
            if (![self redirectUrl]) {
                [self loadBodyData];
            }
        } else {
            _responseHead.stateCode = 404;
            _responseHead.stateDesc = [@"服务器非法操作❌" stringByRemovingPercentEncoding];
        }
    }
    return self;
}

- (void)loadData {
    NSRange range = [_requestHead.path rangeOfString:@"?"];
    if (range.location == NSNotFound) {
        self.filePath = [_rootDir stringByAppendingString:_requestHead.path];
    } else {
        self.filePath = [_rootDir stringByAppendingString:[_requestHead.path substringToIndex:range.location]];
        self.queryStr = [_requestHead.path substringFromIndex:range.location + range.length];
    }
    NSString *redirectUrl = [self redirectUrl];
    if (redirectUrl) {
        [_responseHead setHeadValue:redirectUrl WithField:@"Location"];
        _responseHead.stateCode = 303;
        return;
    }
}

- (void)loadBodyData {
    BOOL isResourceExist = YES;
    if (_delegateEnabled) {
        isResourceExist = [_delegate respondsToSelector:@selector(isResourceExist:)] && ![_delegate isResourceExist:_requestHead];
    } else {
        isResourceExist = [[NSFileManager defaultManager] fileExistsAtPath:_filePath];
    }
    if (!isResourceExist) {
        if ([self isFavicon]) {
            self.filePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"favicon.ico"];
//            self.filePath = @"/Users/egova/Downloads/favicon.ico";
        } else {
            _responseHead.stateCode = 404;
            _responseHead.stateDesc = [@"访问资源不存在❌" stringByRemovingPercentEncoding];
            return;
        }
    }

    if ([self isDir]) {
        [self loadDir];
    } else {
        [self loadFileData];
    }

    if ([self bodyEnd]) {
        return;
    }
}

- (void)loadFileData {
    if (_delegateEnabled && [_delegate respondsToSelector:@selector(resourceLength:)]) {
        NSRange range = [_requestHead range];
        u_int64_t length = [_delegate resourceLength:_requestHead];
        if (range.location < length && range.length < length && range.length > 0) {
            _bodyDataLength = length - range.location > range.length ? range.length : length - range.location;
            _bodyDataOffset = range.location;
        } else {
            _bodyDataLength = length;
        }
    } else {
        BOOL isDir;
        BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:_filePath isDirectory:&isDir];
        if (!isDir && isExist) {
            self.fileOutput = [NSFileHandle fileHandleForReadingAtPath:_filePath];

            NSRange range = [_requestHead range];
            u_int64_t length = [_fileOutput seekToEndOfFile];
            if (range.location < length && range.length < length && range.length > 0) {
                _bodyDataLength = length - range.location > range.length ? range.length : length - range.location;
                _bodyDataOffset = range.location;
                NSString *contentRange = [NSString stringWithFormat:@"bytes %llu-%llu/%llu", _bodyDataOffset, _bodyDataOffset + _bodyDataLength - 1, length];
                [_responseHead setHeadValue:contentRange WithField:@"Content-Range"];
            } else {
                _bodyDataLength = length;
            }
        }
    }
}

- (void)loadDir {
    NSMutableArray *array = @[].mutableCopy;
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"YYYY.MM.dd - HH:mm:ss"]; // YYYY.MM.dd
    }

    for (NSString *path in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_filePath error:nil]) {
        ZGHTTPResourceInfo *info = [ZGHTTPResourceInfo new];
        NSError *error;
        NSDictionary<NSFileAttributeKey, id> *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[_filePath stringByAppendingPathComponent:path] error:&error];
        info.isDirectory = [fileAttributes.fileType isEqualToString:NSFileTypeDirectory];
        u_int64_t length = fileAttributes.fileSize;
        if (info.isDirectory) length = 0;
        info.size = length;
        NSDate *date = fileAttributes[NSFileModificationDate];
        NSString *dateStr = [dateFormatter stringFromDate:date];

        info.name = [path lastPathComponent];
        info.modifyTime = dateStr;
        info.relativeUrl = [path stringByReplacingOccurrencesOfString:_rootDir withString:@""];
        [array addObject:info];
    }
    _data = [ZGHTTPHTMLDirectory initWithResources:array dirName:_requestHead.path].htmlData;
    NSRange range = [_requestHead range];
    u_int64_t length = _data.length;
    if (range.location < length && range.length < length && range.length > 0) {
        _bodyDataLength = length - range.location > range.length ? range.length : length - range.location;
        _bodyDataOffset = range.location;
        NSString *contentRange = [NSString stringWithFormat:@"bytes %llu-%llu/%llu", _bodyDataOffset, _bodyDataOffset + _bodyDataLength - 1, length];
        [_responseHead setHeadValue:contentRange WithField:@"Content-Range"];
    } else {
        _bodyDataLength = _data.length;
        _bodyDataOffset = 0;
    }
    [_responseHead setHeadValue:@"close" WithField:@"Connection"];
    [_responseHead setHeadValue:@"text/html; charset=utf-8" WithField:@"Content-Type"];
}

- (BOOL)delegateCheck {
    if ([_delegate respondsToSelector:@selector(shouldUsedDelegate:)]) self.delegateEnabled = [_delegate shouldUsedDelegate:_requestHead];
//    BOOL wilLoadD = [_delegate respondsToSelector:@selector(willLoadResource:)];
    BOOL resourcePathD = [_delegate respondsToSelector:@selector(resourceRelativePath:)];
    BOOL isDirD = [_delegate respondsToSelector:@selector(isDirectory:)];
    BOOL isExistD = [_delegate respondsToSelector:@selector(isResourceExist:)];
    BOOL dirItemInfoD = [_delegate respondsToSelector:@selector(dirItemInfoList:)];
    BOOL resourceLengthD = [_delegate respondsToSelector:@selector(resourceLength:)];
    BOOL readResourceD = [_delegate respondsToSelector:@selector(readResource:atOffset:length:head:)];

    BOOL delegateLegal = (resourcePathD || isDirD || isExistD || dirItemInfoD || resourceLengthD || readResourceD)
            == (resourcePathD && isDirD && isExistD && dirItemInfoD && resourceLengthD && readResourceD);

    if (!_delegateEnabled) return YES;
    if (delegateLegal) return YES;
    return NO;
}

- (BOOL)isDir {
    if (_delegateEnabled && [_delegate respondsToSelector:@selector(isDirectory:)]) return [_delegate isDirectory:_requestHead];
    return [[_filePath substringFromIndex:_filePath.length - 1] isEqualToString:@"/"];
}

- (BOOL)isFavicon {
    return [_requestHead.path isEqualToString:@"/favicon.ico"];
}

- (NSString *)redirectUrl {
//    return @"http://www.baidu.com";
    if (_delegateEnabled && [_delegate respondsToSelector:@selector(redirect:)]) return [_delegate redirect:_requestHead];
    if (![self isDir] && ![_delegate respondsToSelector:@selector(isDirectory:)]) {
        BOOL isDir;
        BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:_filePath isDirectory:&isDir];
        NSString *path = [_requestHead.host stringByAppendingPathComponent:_requestHead.path];
        if (isDir && isExist) return [NSString stringWithFormat:@"http://%@/", path];
    }
    return nil;
}

- (BOOL)shouldConnectKeepLive {
    if (_error) return NO;
    if ([self bodyEnd]) return NO;
    return [_requestHead.headDic[@"Connection"] isEqualToString:@"keep-alive"];
}

- (BOOL)bodyEnd {
    if (_error) return YES;
    return _bodyDataLength < _bodyDataOffset + 1;
}

- (NSData *)readAllHeadData {
    [_responseHead setHeadValue:@(_bodyDataLength).stringValue WithField:@"Content-Length"];
//    NSLog(@"%@",_responseHead.headDic);
    return [_responseHead dataOfHead];
}

- (NSData *)readBodyData {
    NSData *data;
    if ([self isDir]) {
        _bodyDataOffset = _data.length;
        data = _data;
    } else {
        NSUInteger length = kZGHTTPDataReadMax;
        if (_bodyDataOffset >= _bodyDataLength) return nil;
        if (_bodyDataOffset + kZGHTTPDataReadMax >= _bodyDataLength) length = _bodyDataLength - _bodyDataOffset;

        if (_delegateEnabled && [_delegate respondsToSelector:@selector(readResource:atOffset:length:head:)]) {
            data = [_delegate readResource:_filePath atOffset:_bodyDataOffset length:length head:_requestHead];
            _bodyDataOffset += length;
            if ([self bodyEnd]) {
                if ([_delegate respondsToSelector:@selector(finishLoadResource:)]) [_delegate finishLoadResource:_requestHead];
            }
        } else {
            [_fileOutput seekToFileOffset:_bodyDataOffset];
            data = [_fileOutput readDataOfLength:length];
            _bodyDataOffset += length;
            if ([self bodyEnd]) [_fileOutput closeFile];
        }
    }
    return data;
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation ZGHTTPResponseHead (ZGHTTPPrivateAPI)

+ (instancetype)initWithRequestHead:(ZGHTTPRequestHead *)head {
    return [[self alloc] initWithRequestHead:head];
}

+ (instancetype)initWithError:(NSError *)error requestHead:(ZGHTTPRequestHead *)head {
    return [[self alloc] initWithError:error requestHead:head];
}

- (instancetype)initWithError:(NSError *)error requestHead:(ZGHTTPRequestHead *)head {
    if (self = [self initWithRequestHead:head]) {
        self.stateCode = error.code;
        self.stateDesc = [error.domain stringByRemovingPercentEncoding];
        if (error) [self setHeadValue:@"close" WithField:@"Connection"];
    }
    return self;
}

- (instancetype)initWithRequestHead:(ZGHTTPRequestHead *)head {
    if (self = [self init]) {
        NSDate *date = [NSDate date];
        NSString *dataStr = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterFullStyle];
        NSDictionary *dic = @{
                @"Date": dataStr,
                @"Server": @"MMHTTPServer",
                @"Accept-Ranges": @"bytes"
        };
        self.headDic = dic;
        self.protocol = head.protocol;
        self.version = head.version;
        self.stateCode = [head hasRangeHead] ? 206 : 200;
        self.stateDesc = @"OK";
    }
    return self;
}

- (void)setHeadValue:(NSString *)value WithField:(NSString *)field {
    if (value == nil || field == nil)return;
    NSMutableDictionary *dic = self.headDic.mutableCopy;
    dic[field] = value;
    self.headDic = dic;
}

- (NSData *)dataOfHead {
    NSMutableString *headStr = @"".mutableCopy;
    [headStr appendFormat:@"%@/%@ %zd %@\r\n", self.protocol, self.version, self.stateCode, self.stateDesc];
    [self.headDic enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
        [headStr appendFormat:@"%@:%@\r\n", key, obj];
    }];
    [headStr appendString:@"\r\n"];
    return [headStr dataUsingEncoding:NSUTF8StringEncoding];
}

@end

#pragma clang diagnostic pop

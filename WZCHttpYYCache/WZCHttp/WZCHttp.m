//
//  WZCHttp.m
//  WZCHttpYYCache
//
//  Created by 王子臣 on 2017/4/27.
//  Copyright © 2017年 winsion. All rights reserved.
//

#import "WZCHttp.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "WZCYYCache.h"
#import <CommonCrypto/CommonDigest.h>

#define NET_ERROR_IMFORMATION @"网络出现错误，请检查网络连接"

#define NET_ERROR [NSError errorWithDomain:@"com.caixindong.XDNetworking.ErrorDomain" code:-999 userInfo:@{ NSLocalizedDescriptionKey:NET_ERROR_IMFORMATION}]

@implementation WZCHttp
/**  超时时间 */
static NSTimeInterval   requestTimeout = 3.f;
/**  网络状态 */
static NetworkStatus   _netStatus;
/**  请求任务 */
static NSMutableArray   *requestTasks;

static NSDictionary     *headers;

#pragma mark - 初始化manager

/**
 初始化manager

 @return AFHTTPSessionManager
 */
+ (AFHTTPSessionManager *)manager{
    
    //设置是否显示小菊花
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    //默认解析模式
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    //配置请求序列化
    AFJSONResponseSerializer *serializer = [AFJSONResponseSerializer serializer];
    
    [serializer setRemovesKeysWithNullValues:YES];
    
    manager.requestSerializer.stringEncoding = NSUTF8StringEncoding;
    
    //设置请求超时时间
    manager.requestSerializer.timeoutInterval = requestTimeout;
    
    for (NSString *key in headers.allKeys) {
        if (headers[key] != nil) {
            [manager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
        }
    }
    
    //配置响应序列化
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json",
                                                                              @"text/html",
                                                                              @"text/json",
                                                                              @"text/plain",
                                                                              @"text/javascript",
                                                                              @"text/xml",
                                                                              @"image/*",
                                                                              @"application/octet-stream",
                                                                    @"application/zip"]];
    [self MonitorNetwork];
    return manager;
}

/**
 网络监听
 */
+ (void)MonitorNetwork{
    
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager startMonitoring];
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case -1:
            _netStatus = NetworkStatusUnknown;
            break;
            case 0:
            _netStatus = NetworkStatusNotReachable;
            break;
            case 1:
            _netStatus = NetworkStatusReachableViaWWAN;
            break;
            case 2:
            _netStatus = NetworkStatusReachableViaWiFi;
            break;
        }
    }];
    
    
}

#pragma mark  请求

+ (URLSessionTask *)getRequestUrl:(NSString *)url params:(NSDictionary *)params cache:(BOOL)cache target:(UIViewController *)target indicator:(BOOL)indicator progressBlock:(RequestProgress)progressBlock successBlock:(RequestSuccess)successBlock failBlock:(RequestFail)failBlock{
    
    URLSessionTask *session = nil;
    AFHTTPSessionManager *manager = [self manager];
    NSString *keyUrl = [[self alloc] urlDictToStringWithUrlStr:url WithDict:params];
    //判断是否有缓存,有缓存的话,直接返回缓存,然后再进行网络请求
    id  responseObj = [WZCYYCache getResponseCacheForKey:keyUrl];
    if (responseObj && cache) {
        if (successBlock) {
            successBlock(responseObj);
        }
    }
    //判断网络状态
    if (_netStatus == NetworkStatusNotReachable ) {
        if (failBlock) {
            failBlock(NET_ERROR);
        }
        return session;
    }

   session = [manager GET:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
       //返回进度
       if(progressBlock){
           progressBlock(downloadProgress);
       }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (successBlock) {
            successBlock(responseObject);
        }
        //缓存数据
        if (cache) {
            [WZCYYCache saveResponseCache:responseObject forKey:keyUrl];
        }
        [[self allTasks] removeObject:session];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failBlock) {
            failBlock(error);
            [[self allTasks] removeObject:session];
        }
    }];
    //任务继续
    [session resume];
    if (session) {
        [[self allTasks] addObject:session];
    }
    return session;
}

+ (URLSessionTask *)postRequestUrl:(NSString *)url params:(NSDictionary *)params cache:(BOOL)cache target:(UIViewController *)target indicator:(BOOL)indicator progressBlock:(RequestProgress)progressBlock successBlock:(RequestSuccess)successBlock failBlock:(RequestFail)failBlock{
    
    URLSessionTask *session = nil;
    AFHTTPSessionManager *manager = [self manager];
    NSString *keyUrl = [[self alloc] urlDictToStringWithUrlStr:url WithDict:params];

    //判断是否有缓存,有缓存的话,直接返回缓存,然后再进行网络请求
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        //2.把任务添加到队列中执行
        dispatch_async(queue, ^{
            id  responseObj = [WZCYYCache getResponseCacheForKey:keyUrl];
            if (responseObj && cache) {
                if (successBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        successBlock(responseObj);
                    });
                    
                }
            }
        });
    
    if (_netStatus == NetworkStatusNotReachable) {
        if (failBlock) {
            failBlock(NET_ERROR);
        }
        return session;
    }
    
    session = [manager POST:url parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progressBlock) {
            progressBlock(uploadProgress);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (successBlock) {
            successBlock(responseObject);
        }
        //缓存数据
        if (cache) {
            [WZCYYCache saveResponseCache:responseObject forKey:keyUrl];
        }
        [[self allTasks] removeObject:session];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failBlock) {
            failBlock(error);
            [[self allTasks] removeObject:session];
        }
    }];
    //任务继续
    [session resume];
    if (session) {
        [[self allTasks] addObject:session];
    }
    return session;

    
}


#pragma mark 文件上传
+ (URLSessionTask *)uploadFileWithUrl:(NSString *)url params:(NSDictionary *)params fileData:(NSData *)data type:(NSString *)type name:(NSString *)name mimeType:(NSString *)mimeType target:(UIViewController *)target indicator:(BOOL)indicator progressBlock:(RequestProgress)progressBlock successBlock:(RequestSuccess)successBlock failBlock:(RequestFail)failBlock{
    URLSessionTask *session = nil;
    AFHTTPSessionManager *manager = [self manager];
    //判断网络状态
    if (_netStatus == NetworkStatusNotReachable) {
        if (failBlock) {
            failBlock(NET_ERROR);
        }
        return session;
    }

    session = [manager POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        NSString *fileName = nil;
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMddHHmmss";
        
        NSString *day = [formatter stringFromDate:[NSDate date]];
        fileName = [NSString stringWithFormat:@"%@.%@",day,type];
        
        [formData appendPartWithFileData:data name:name fileName:fileName mimeType:mimeType];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if (progressBlock) {
            progressBlock(uploadProgress);
        }
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (successBlock) {
            successBlock(responseObject);
        }
        [[self allTasks] removeObject:session];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failBlock) {
            failBlock(error);
            [[self allTasks] removeObject:session];
            
        }
    }];
    [session resume];
    if (session) {
        [[self allTasks] addObject:session];
    }
    return session;
}



+ (URLSessionTask *)uploadMultiFileWithUrl:(NSString *)url params:(NSDictionary *)params fileData:(NSArray *)datas type:(NSString *)type name:(NSString *)name mimeType:(NSString *)mimeType target:(UIViewController *)target indicator:(BOOL)indicator progressBlock:(RequestProgress)progressBlock successBlock:(RequestSuccess)successBlock failBlock:(RequestFail)failBlock
{
    
    //判断网络状态
    if (_netStatus == NetworkStatusNotReachable) {
        
        if (failBlock) {
            failBlock(NET_ERROR);
        }
        
        return nil;
    }
   
    __block NSMutableArray *sessions = [NSMutableArray array];
    __block NSMutableArray *responses = [NSMutableArray array];
    __block NSMutableArray *failResponse = [NSMutableArray array];
    
    dispatch_group_t uploadGroup = dispatch_group_create();
    
    NSInteger count = datas.count;
    
    
    for (int i = 0; i < count; i++) {
        URLSessionTask *session = nil;
        
        dispatch_group_enter(uploadGroup);
        
        
        session = [self uploadFileWithUrl:url params:params fileData:datas[i] type:type name:name mimeType:mimeType target:target indicator:indicator progressBlock:^(NSProgress *progress) {
            if(progressBlock){
                progressBlock(progress);
            }
        } successBlock:^(id requestDic) {
            //成功返回数据
            if (successBlock) {
                successBlock(requestDic);
            }
        } failBlock:^(NSError *error) {
            NSError *Error = [NSError errorWithDomain:url code:-999 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"第%d次上传失败",i]}];
            
            [failResponse addObject:Error];
            
            dispatch_group_leave(uploadGroup);
            
            [sessions removeObject:session];
        }];
        
        
        [session resume];
        
        if (session) [sessions addObject:session];
    }
    
    [[self allTasks] addObjectsFromArray:sessions];
    
    dispatch_group_notify(uploadGroup, dispatch_get_main_queue(), ^{
        if (responses.count > 0) {
            if (successBlock) {
                successBlock([responses copy]);
                if (sessions.count > 0) {
                    [[self allTasks] removeObjectsInArray:sessions];
                }
            }
        }
        if (failResponse.count > 0) {
            if (failBlock) {
                failBlock([failResponse copy]);
                if (sessions.count > 0) {
                    [[self allTasks] removeObjectsInArray:sessions];
                }
            }
        }
        
    });
    return [sessions copy];
}

#pragma mark 文件下载
+ (URLSessionTask *)downloadWithUrl:(NSString *)url progressBlock:(RequestProgress)progressBlock successBlock:(RequestSuccess)successBlock failBlock:(RequestFail)failBlock{
    URLSessionTask *session = nil;
    //判断是否有缓存
    id  responseObj = [WZCYYCache getFileWithKey:[self md5:url]];
    if (responseObj) {
        
        if (successBlock) {
            
        
            successBlock([WZCYYCache getFilePath]);
        }
        return session;
    }
    
    //判断是否有后缀
    NSString *fileName = nil;
    NSString *type = nil;
    NSArray *strArray = nil;
    
    strArray = [url componentsSeparatedByString:@"."];
    if (strArray.count > 0) {
        type = strArray[strArray.count - 1];
    }
    
    if (type) {
        fileName = [NSString stringWithFormat:@"%@.%@",[self md5:url],type];
    }else {
        fileName = [NSString stringWithFormat:@"%@",[self md5:url]];
    }
    
    
    AFHTTPSessionManager *manager = [self manager];
    //响应内容序列化为二进制
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    session = [manager GET:url
                parameters:nil
                  progress:^(NSProgress * _Nonnull downloadProgress) {
                      if (progressBlock)
                      {
                          progressBlock(downloadProgress);
                      }
                      
                  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      if (successBlock) {
                          NSData *dataObj = (NSData *)responseObject;
                  
                          NSString *path =  [WZCYYCache saveFileWithKey:url file:dataObj fileName:fileName];
                          successBlock(path);
                      }
                      
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      if (failBlock) {
                          failBlock (error);
                      }
                  }];
    
    [session resume];
    
    if (session) [[self allTasks] addObject:session];
    
    return session;
    
    
}


#pragma mark other
//初始化任务
+ (NSMutableArray *)allTasks {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (requestTasks == nil) requestTasks = [NSMutableArray array];
    });
    return requestTasks;
}

//拼接完整的URL
-(NSString *)urlDictToStringWithUrlStr:(NSString *)urlStr WithDict:(NSDictionary *)parameters
{
    if (!parameters) {
        return urlStr;
    }
    NSMutableArray *parts = [NSMutableArray array];
    
    [parameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        //接收key
        NSString *finalKey = [key stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        //接收值
        NSString *finalValue = [obj stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        
        
        NSString *part =[NSString stringWithFormat:@"%@=%@",finalKey,finalValue];
        
        [parts addObject:part];
        
    }];
    
    NSString *queryString = [parts componentsJoinedByString:@"&"];
    
    queryString = queryString ? [NSString stringWithFormat:@"?%@",queryString] : @"";
    
    NSString *pathStr = [NSString stringWithFormat:@"%@%@",urlStr,queryString];
    
    return pathStr;

}



+ (void)cancleAllRequest{
    
    @synchronized (self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[URLSessionTask class]]) {
                [obj cancel];
            }

        }];
    }
    
}


+ (void)configHttpHeader:(NSDictionary *)httpHeader {
    headers = httpHeader;
}

+ (void)cancelRequestWithURL:(NSString *)url {
    if (!url) return;
    @synchronized (self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(URLSessionTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[URLSessionTask class]]) {
                if ([obj.currentRequest.URL.absoluteString hasSuffix:url]) {
                    [obj cancel];
                    *stop = YES;
                }
            }
        }];
    }
}



+ (void)setupTimeout:(NSTimeInterval)timeout {
    requestTimeout = timeout;
}
#pragma mark - 散列值
+ (NSString *)md5:(NSString *)string {
    if (string == nil || string.length == 0) {
        return nil;
    }
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH],i;
    
    CC_MD5([string UTF8String],(int)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding],digest);
    
    NSMutableString *ms = [NSMutableString string];
    
    for (i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [ms appendFormat:@"%02x",(int)(digest[i])];
    }
    
    return [ms copy];
}



@end

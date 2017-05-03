//
//  WZCYYCache.m
//  WZCHttpYYCache
//
//  Created by 王子臣 on 2017/4/27.
//  Copyright © 2017年 winsion. All rights reserved.
//

#import "WZCYYCache.h"
#import "YYCache.h"
#import "YYKVStorage.h"

@implementation WZCYYCache
static NSString *const NetworkResponseCache = @"NetworkResponseCache";
static YYCache *_dataCache;
static YYKVStorage *_diskCache;

+ (void)initialize
{
    _dataCache = [YYCache cacheWithName:NetworkResponseCache];
    NSString *downloadDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    _diskCache = [[YYKVStorage alloc] initWithPath:downloadDir type:YYKVStorageTypeFile];
}



#pragma mark 查找数据
+ (id)getResponseCacheForKey:(NSString *)key{
    
    return [_dataCache objectForKey:key] ;
}


+ (id)getFileWithKey:(NSString *)key
{
    return  [_diskCache getItemForKey:key];
}

+ (id)getFilePath

{
    return _diskCache.path;
}


#pragma mark 缓存数据
+ (void)saveResponseCache:(id)responseCache forKey:(NSString *)key{
    //异步缓存,不会阻塞主线程
    [_dataCache setObject:responseCache forKey:key withBlock:nil];
}


+ (NSString *)saveFileWithKey:(NSString *)key file:(id)file fileName:(NSString *)fileName{
    
    [_diskCache saveItemWithKey:key value:file filename:fileName extendedData:nil];
    return _diskCache.path;
}



@end

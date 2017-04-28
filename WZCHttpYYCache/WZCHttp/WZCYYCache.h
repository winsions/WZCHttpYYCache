//
//  WZCYYCache.h
//  WZCHttpYYCache
//
//  Created by 王子臣 on 2017/4/27.
//  Copyright © 2017年 winsion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WZCYYCache : NSObject

/**
 *  取出缓存的数据
 *
 *  @param key 根据存入时候填入的key值来取出对应的数据
 *
 *  @return 缓存的数据
 */
+(id)getResponseCacheForKey:(NSString *)key;


/**
 存储文件
 
 @param key      缓存数据对应的key值
 @param file     文件
 @param fileName 文件名称
 
 @return 存储的位置
 */
+(NSString *)saveFileWithKey:(NSString *)key file:(id)file fileName:(NSString *)fileName;

/**
 *  缓存网络数据
 *
 *  @param responseCache 服务器返回的数据
 *  @param key           缓存数据对应的key值,推荐填入请求的URL
 */
+(void)saveResponseCache:(id)responseCache forKey:(NSString *)key;


/**
 得到存储的文件
 
 @param key 存储的key
 
 @return 返回文件
 */
+(id)getFileWithKey:(NSString *)key;


/**
 disk缓存路径
 @return <#return value description#>
 */
+(id)getFilePath;

@end

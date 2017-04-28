//
//  AppDelegate.h
//  WZCHttpYYCache
//
//  Created by 王子臣 on 2017/4/27.
//  Copyright © 2017年 winsion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end


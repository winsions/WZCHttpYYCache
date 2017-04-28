//
//  ViewController.m
//  WZCHttpYYCache
//
//  Created by 王子臣 on 2017/4/27.
//  Copyright © 2017年 winsion. All rights reserved.
//

#import "ViewController.h"
#import "WZCHttp.h"
#define url "http://119.23.248.224:9090/item/list?page=1&rows=1"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [WZCHttp postRequestUrl:@url params:nil cache:YES target:nil indicator:YES progressBlock:^(NSProgress *progress) {
        NSLog(@"%@",progress);
    } successBlock:^(id requestDic) {
        NSLog(@"%@",requestDic);
    } failBlock:^(NSError *error) {
        NSLog(@"%@",error);
    }];
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

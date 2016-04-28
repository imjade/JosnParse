//
//  ViewController.m
//  JsonParseModel
//
//  Created by Jade on 16/4/23.
//  Copyright © 2016年 Jade. All rights reserved.
//

#import "ViewController.h"
#import "JsonModel.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSDictionary *dict = @{@"name":@"jade"
                           ,@"age":@"10"
                           ,@"haslogin":@"1"
                           ,@"informations":@[@{@"name":@"haha"},@{@"name":@"meide"}]
                           ,@"parseModel":@{@"name":@"joke"}};
    NSError *error;
    JsonModel *jsonModel = [[JsonModel alloc] initWithDict:dict error:&error];
    NSLog(@"jsonModel:%@..description:%@",jsonModel,error.description);
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

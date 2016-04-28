//
//  JsonModel.h
//  JsonParseModel
//
//  Created by Jade on 16/4/23.
//  Copyright © 2016年 Jade. All rights reserved.
//

#import "JsonParse.h"
#import "ParseModel.h"
@interface JsonModel : JsonParse
@property (nonatomic,copy) NSString *optional;
@property (nonatomic,copy) NSString *name;
@property (nonatomic,assign) int age;
@property (nonatomic,assign) BOOL haslogin;
@property (nonatomic,strong) NSArray<ParseModel> *informations;
@property (nonatomic,strong) ParseModel *parseModel;
@end

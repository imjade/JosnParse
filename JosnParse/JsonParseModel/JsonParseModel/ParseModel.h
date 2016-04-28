//
//  ParseModel.h
//  JsonParseModel
//
//  Created by Jade on 16/4/25.
//  Copyright © 2016年 Jade. All rights reserved.
//

#import "JsonParse.h"
@protocol Optional <NSObject>
@end

@interface ParseModel : JsonParse
@property (nonatomic,copy) NSString *name;
@property (nonatomic,copy) NSString<Optional> *sss;
@end
@protocol ParseModel <NSObject>
@end

//
//  JsonParseError.m
//  JsonParseModel
//
//  Created by Jade on 16/4/23.
//  Copyright © 2016年 Jade. All rights reserved.
//

#import "JsonParseError.h"
NSString * const kJsonParseErrorDomain = @"kJsonParseErrorDomain";

@implementation JsonParseError

+ (JsonParseError *)errorModelInvalidWithMessage:(NSString *)message
{
    message = [NSString stringWithFormat:@"JsonParseError: %@",message];
    return [JsonParseError errorWithDomain:kJsonParseErrorDomain
                                      code:JsonParseErrorInvalidData
                                  userInfo:@{NSLocalizedDescriptionKey:message}];
}
@end

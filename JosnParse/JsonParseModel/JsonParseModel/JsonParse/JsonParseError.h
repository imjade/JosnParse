//
//  JsonParseError.h
//  JsonParseModel
//
//  Created by Jade on 16/4/23.
//  Copyright © 2016年 Jade. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger,JsonParseErrorType) {
    JsonParseErrorInvalidData = 1,
    JsonParseErrorBadResponse = 2,
    JsonParseErrorBadJSON = 3,
    JsonParseErrorModelIsInvalid = 4,
    JsonParseErrorNilInput = 5
};

@interface JsonParseError : NSError
+ (JsonParseError *)errorModelInvalidWithMessage:(NSString *)message;
@end

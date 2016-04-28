//
//  JsonParse.h
//  JsonParseModel
//
//  Created by Jade on 16/4/23.
//  Copyright © 2016年 Jade. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JsonParse : NSObject
/**
 *  init model
 *
 *  @param dict  json Dictionary
 *  @param error error
 *
 *  @return model
 */
- (instancetype)initWithDict:(NSDictionary *)dict error:(NSError **)error;
/**
 *  json array package ParseModel
 *
 *  @param array json Array
 *  @param error error
 *
 *  @return packaged <Array>ParseModel
 */
+ (NSMutableArray *)arrayOfModelsFromDictionarties:(NSArray *)array error:(NSError**)error;
/**
 *  json dictionaty package ParseModel
 *
 *  @param dictionary json Dictionary
 *  @param error      error
 *
 *  @return packaged <Dictionary>ParseModel
 */
+ (NSMutableDictionary *)dictionaryOfModelFromDictionary:(NSDictionary *)dictionary error:(NSError **)error;

/**
 *  subClass  update isOptional
 */
+(BOOL)propertyIsOptional:(NSString*)propertyName;
/**
 *  subClass  update Ignored
 */
+(BOOL)propertyIsIgnored:(NSString*)propertyName;
/**
 *  subClass  update protocol
 */
+(NSString*)protocolForArrayProperty:(NSString *)propertyName;


@end

//
//  JsonParseClassProperty.h
//  JsonParseModel
//
//  Created by Jade on 16/4/23.
//  Copyright © 2016年 Jade. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JsonParseClassProperty : NSObject
/**
 *  Model Property name
 */
@property (nonatomic,copy) NSString *name;
/**
 *  Model Property type
 */
@property (nonatomic,assign) Class type;
/**
 *  protocol maybe <Array>ParseModel || <Dictionary>ParseModel
 */
@property (nonatomic,copy) NSString *protocol;
/**
 *  Model Property isOptional
 */
@property (nonatomic,assign) BOOL isOptional;
/**
 *  Model Property Mutable
 */
@property (assign, nonatomic) BOOL isMutable;
@end

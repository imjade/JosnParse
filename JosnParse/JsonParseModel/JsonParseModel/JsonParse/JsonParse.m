//
//  JsonParse.m
//  JsonParseModel
//
//  Created by Jade on 16/4/23.
//  Copyright © 2016年 Jade. All rights reserved.
//

#import "JsonParse.h"
#import <objc/runtime.h>
#import "JsonParseClassProperty.h"
#import "JsonParseError.h"
#if TARGET_IPHONE_SIMULATOR
#define DLog( s, ... ) NSLog( @"[%@:%d] %@", [[NSString stringWithUTF8String:__FILE__] \
lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DLog( s, ... )
#endif

static const char *kClassPropertiesKey;
static Class JsonParseClass = NULL;
//model allowed types
static NSArray* allowedJSONTypes = nil;

@implementation JsonParse
- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

+(void)load
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // initialize all class static objects,
        // which are common for ALL JSONModel subclasses
        
        @autoreleasepool {
            allowedJSONTypes = @[
                                 [NSString class], [NSNumber class], [NSDecimalNumber class], [NSArray class], [NSDictionary class], [NSNull class], //immutable JSON classes
                                 [NSMutableString class], [NSMutableArray class], [NSMutableDictionary class] //mutable JSON classes
                                 ];
            
            JsonParseClass = NSClassFromString(NSStringFromClass(self));
        }
    });
}


#pragma mark - init
/**
 *  init model
 *
 *  @param dict  json Dictionary
 *  @param error error
 *
 *  @return model
 */
- (instancetype)initWithDict:(NSDictionary *)dict error:(NSError **)error
{
    if (!dict) {
        if (error) *error = [JsonParseError errorModelInvalidWithMessage:@"dict is nil"];
        return nil;
    }
    
    if (![dict isKindOfClass:[NSDictionary class]]) {
        if (error) *error = [JsonParseError errorModelInvalidWithMessage:@"inpur not NSDictionary"];
        return nil;
    }
    
    self = [super init];
    if (!self) {
        if (error) *error = [JsonParseError errorModelInvalidWithMessage:@"super self invalid"];
        return nil;
    }
    
    if (![self importDictionary:dict error:error]) {
        return nil;
    }
    
    return self;
}

#pragma mark - setUp
- (void)setUp
{
    if (!objc_getAssociatedObject(self.class, &kClassPropertiesKey)) {
        [self inspectProperties];
    }
}

/**
 *  properties
 *
 *  @return All Model properties
 */
- (NSArray *)properties
{
    NSDictionary *classProperties = objc_getAssociatedObject(self.class, &kClassPropertiesKey);
    if (classProperties) {
        return [classProperties allValues];
    }
    [self setUp];
    classProperties = objc_getAssociatedObject(self.class, &kClassPropertiesKey);
    return [classProperties allValues];
}

/**
 *  init model property
 */
- (void)inspectProperties
{
    NSMutableDictionary* propertyIndex = [NSMutableDictionary dictionary];
    Class class = [self class];
    NSString *propertyType;//class type
    NSScanner *scanner;
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList(class, &propertyCount);
    for (unsigned int i = 0; i < propertyCount; i ++) {
        JsonParseClassProperty *classProperty = [[JsonParseClassProperty alloc] init];
        
        //get property name
        objc_property_t property = properties[i];
        const char *propertyName = property_getName(property);
        classProperty.name = @(propertyName);
        
        const char *propertyAttrs = property_getAttributes(property);
        NSString *propertyAttributes = @(propertyAttrs);
        NSArray* attributeItems = [propertyAttributes componentsSeparatedByString:@","];
        
        //ignore read-only properties
        if ([attributeItems containsObject:@"R"]) {
            continue; //to next property
        }
        
        scanner = [[NSScanner alloc] initWithString:propertyAttributes];
        [scanner scanUpToString:@"T" intoString:nil];
        [scanner scanString:@"T" intoString:nil];
        
        if ([scanner scanString:@"@\"" intoString:&propertyType]) {
            [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"<"]
                                    intoString:&propertyType];
            classProperty.type = NSClassFromString(propertyType);
            classProperty.isMutable = ([propertyType rangeOfString:@"Mutable"].location != NSNotFound);
            
            
            //read through the property protocols
            while ([scanner scanString:@"<" intoString:NULL]) {
                
                NSString* protocolName = nil;
                
                [scanner scanUpToString:@">" intoString: &protocolName];
                
                if ([protocolName isEqualToString:@"Optional"]) {
                    classProperty.isOptional = YES;
                } else if([protocolName isEqualToString:@"Ignore"]) {
                    classProperty = nil;
                } else {
                    classProperty.protocol = protocolName;
                }
                
                [scanner scanString:@">" intoString:NULL];
            }
            
        }
 
        //subClass update isOptional
        NSString *nsPropertyName = @(propertyName);
        if([[self class] propertyIsOptional:nsPropertyName]){
            classProperty.isOptional = YES;
        }
        //subClass update isIgnore
        if([[self class] propertyIsIgnored:nsPropertyName]){
            classProperty = nil;
        }
        //subClass update protocol
        NSString* customProtocol = [[self class] protocolForArrayProperty:nsPropertyName];
        if (customProtocol) {
            classProperty.protocol = customProtocol;
        }
        
        
        if (classProperty && ![propertyIndex objectForKey:classProperty.name]) {
            [propertyIndex setObject:classProperty forKey:classProperty.name];
        }
        
    }
    
    free(properties);
    class = [super class];
    objc_setAssociatedObject(class
                             , &kClassPropertiesKey
                             , propertyIndex,
                             OBJC_ASSOCIATION_RETAIN);
}


/**
 *  package ParseModel
 *
 *  @param dict  json Dict
 *  @param error error
 *
 *  @return is success
 */
- (BOOL)importDictionary:(NSDictionary *)dict error:(NSError **)error
{
    for (JsonParseClassProperty *property in [self properties]) {
        id jsonValue;
        NSString *jsonKeyPath = property.name;
        @try {
            jsonValue = [dict objectForKey:jsonKeyPath];
        } @catch (NSException *exception) {
            jsonValue = dict[jsonKeyPath];
        }
        
        if (isNull(jsonValue)) {
            if (property.isOptional) continue;
            if (error) *error = [JsonParseError errorModelInvalidWithMessage:@"importDictionary:jsonValue is null"];
            return NO;
        }
        
        Class jsonValueClass = [jsonValue class];
        BOOL isValueOfAllowedType = NO;
        
        for (Class allowedType in allowedJSONTypes) {
            if ( [jsonValueClass isSubclassOfClass: allowedType] ) {
                isValueOfAllowedType = YES;
                break;
            }
        }
        
        if (isValueOfAllowedType==NO) {
            //type not allowed
            DLog(@"Type %@ is not allowed in JSON.", NSStringFromClass(jsonValueClass));
            NSString* msg = [NSString stringWithFormat:@"importDictionary->isValueOfAllowedType:Type %@ is not allowed in JSON.", NSStringFromClass(jsonValueClass)];
            if (error) *error = [JsonParseError errorModelInvalidWithMessage:msg];
            return NO;
        }
        
        
        if (property) {
            //1.check if property is itself a JsonParse
            if ([self isJsonParseSubClass:property.type]) {
                JsonParseError *jsonParseError = nil;
                id value = [[property.type alloc] initWithDict:jsonValue error:&jsonParseError];
                if (!value) {
                    if (property.isOptional) continue;
                    if (error && jsonParseError) *error = [JsonParseError errorModelInvalidWithMessage:@"importDictionary->JsonParseSubClass: value is nil"];
                    return NO;
                }
                if (![value isEqual:[self valueForKey:property.name]]) {
                    [self setValue:value forKey:property.name];
                }
                continue;
            }//check if property is protocol ->Array
            else if (property.protocol) {
                JsonParseError *protocolErr = nil;
                id value = [self transfromProtocol:jsonValue property:property error:&protocolErr];
                if (!value) {
                    if (property.isOptional) continue;
                    if (error && protocolErr) *error = [JsonParseError errorModelInvalidWithMessage:@"importDictionary->protocol: value is nil"];
                    return NO;
                }
                if (![value isEqual:[self valueForKey:property.name]]) {
                    [self setValue:value forKey:property.name];
                }
                continue;
            }//3.handle matching standard JSON types
            else{
                // value is Mutable
                if (property.isMutable) {
                    jsonValue = [jsonValue mutableCopy];
                }
                //set the property value
                if (![jsonValue isEqual:[self valueForKey:property.name]]) {
                    [self setValue:jsonValue forKey: property.name];
                }
                continue;
            }
        }
    }
    return YES;
}

/**
 *  if protocol not nil maybe <JsonParse>Array || <JsonParse>Dictionary
 *
 *  @param value    protocol ==>value
 *  @param property value ==>property
 *  @param error    error
 *
 *  @return change value ==> <JsonParse>Array || <JsonParse>Dictionary
 */
- (id)transfromProtocol:(id)value property:(JsonParseClassProperty *)property error:(NSError **)error
{
    Class class = NSClassFromString(property.protocol);
    if (!class) {
        *error = [JsonParseError errorModelInvalidWithMessage:@"transfromProtocol: class is nil"];
        return value;
    }
    if ([self isJsonParseSubClass:class]) {
        if ([property.type isSubclassOfClass:[NSArray class]]) {
            if (![[value class] isSubclassOfClass:[NSArray class]]) {
                if (error) *error = [JsonParseError errorModelInvalidWithMessage:@"transfromProtocol: value clas not array"];
                return nil;
            }
            JsonParseError *arrayErr  = nil;
            value = [[class class] arrayOfModelsFromDictionarties:value error:&arrayErr];
            if (!value) {
                if (error && arrayErr) *error = [JsonParseError errorModelInvalidWithMessage:@"transfromProtocol: value is nil"];
                return nil;
            }
        }else if ([property.type isSubclassOfClass:[NSDictionary class]]) {
            if (![[value class] isSubclassOfClass:[NSDictionary class]]) {
                if (error) *error = [JsonParseError errorModelInvalidWithMessage:@"transfromProtocol: value clas not NSDictionary"];
                return nil;
            }
            NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
            for (NSString *key in [value allKeys]) {
                NSDictionary *dict = [value objectForKey:key];
                JsonParseError *dictErr  = nil;
                id obj = [[class class] dictionaryOfModelFromDictionary:dict error:&dictErr];
                if (!obj) {
                    if (dictErr && error) *error = [JsonParseError errorModelInvalidWithMessage:@"transfromProtocol: obj is nil"];
                    return nil;
                }
                [dictionary setObject:obj forKey:key];
            }
            value = [NSDictionary dictionaryWithDictionary:dictionary];
        }
    }
    return value;
}

/**
 *  json array package ParseModel
 *
 *  @param array json Array
 *  @param error error
 *
 *  @return packaged <Array>ParseModel
 */
+ (NSMutableArray *)arrayOfModelsFromDictionarties:(NSArray *)array error:(NSError**)error
{
    if (isNull(array)) return nil;
    NSMutableArray *list = [[NSMutableArray alloc] initWithCapacity:array.count];
    for (id obj in array) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            
            JsonParseError *initErr = nil;
            id value = [[self alloc] initWithDict:obj error:&initErr];
            if (!value) {
                if (!error && !initErr) {
                    *error = [JsonParseError errorModelInvalidWithMessage:@"arrayOfModelsFromDictionary: value is nil"];
                }
                return nil;
            }
            [list addObject:value];
        }else if ([obj isKindOfClass:[NSArray class]]) {
            list = [self arrayOfModelsFromDictionarties:obj error:error];
        }else {
            return nil;
        }
    }
    return list;
}

/**
 *  json dictionaty package ParseModel
 *
 *  @param dictionary json Dictionary
 *  @param error      error
 *
 *  @return packaged <Dictionary>ParseModel
 */
+ (NSMutableDictionary *)dictionaryOfModelFromDictionary:(NSDictionary *)dictionary error:(NSError **)error
{
    NSMutableDictionary *output = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];
    
    for (NSString *key in dictionary.allKeys)
    {
        id object = dictionary[key];
        
        if ([object isKindOfClass:NSDictionary.class])
        {
            id obj = [[self alloc] initWithDict:dictionary error:error];
            if (obj == nil) return nil;
            output[key] = obj;
        }
        else if ([object isKindOfClass:NSArray.class])
        {
            id obj = [self arrayOfModelsFromDictionarties:object error:error];
            if (obj == nil) return nil;
            output[key] = obj;
        }
        else
        {
            *error = [JsonParseError errorModelInvalidWithMessage:@"dictionaryOfModelFromDictionary:Only dictionaries and arrays are supported"];
            return nil;
        }
    }
    
    return output;
}



#pragma mark - Private

extern BOOL isNull(id value)
{
    if (!value) return YES;
    if ([value isKindOfClass:[NSNull class]]) return YES;
    
    return NO;
}
/**
 *  check json type is PaeseModel subClass
 *
 *  @param class <#class description#>
 *
 *  @return <#return value description#>
 */
-(BOOL)isJsonParseSubClass:(Class)class
{
#ifdef UNIT_TESTING
    return [@"JsonParse" isEqualToString: NSStringFromClass([class superclass])];
#else
    return [class isSubclassOfClass:JsonParseClass];
#endif
}


#pragma mark - sub class Method
/**
 *  subClass  update isOptional
 */
+(BOOL)propertyIsOptional:(NSString*)propertyName
{
    return NO;
}

/**
 *  subClass  update Ignored
 */
+(BOOL)propertyIsIgnored:(NSString*)propertyName
{
    return NO;
}
/**
 *  subClass  update protocol
 */
+(NSString*)protocolForArrayProperty:(NSString *)propertyName
{
    return nil;
}
@end

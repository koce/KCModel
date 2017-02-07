//
//  KCModel.m
//  KCModel
//
//  Created by Koce on 16/11/25.
//  Copyright © 2016年 赵嘉诚. All rights reserved.
//

#import "KCModel.h"
#import <objc/runtime.h>

typedef NS_ENUM(NSInteger, KCModelPropertyType) {
    KCModelPropertyTypeInt = 0,
    KCModelPropertyTypeFloat,
    KCModelPropertyTypeDouble,
    KCModelPropertyTypeBool,
    KCModelPropertyTypeChar,
    
    KCModelPropertyTypeString,
    KCModelPropertyTypeNumber,
    KCModelPropertyTypeData,
    KCModelPropertyTypeDate,
    KCModelPropertyTypeAny,
    
    KCModelPropertyTypeArray,
    KCModelPropertyTypeMutableArray,
    KCModelPropertyTypeDictionary,
    KCModelPropertyTypeMutableDictionary,
    KCModelPropertyTypeObject,
    KCModelPropertyTypeModel
};

static id KCTransformNormalValueForClass(id val, NSString *className) {
    id ret = val;
    
    Class valClass = [val class];
    Class cls = nil;
    if (className.length > 0) {
        cls = NSClassFromString(className);
    }
    
    if (!cls || !valClass) {
        ret = nil;
    } else if (![cls isSubclassOfClass:[val class]] && ![valClass isSubclassOfClass:cls]) {
        ret = nil;
    }
    
    return ret;
}

@interface KCModelProperty : NSObject

@property (nonatomic, strong) NSString*   propertyClassName;
@property (nonatomic, strong) NSString*   propertyName;
@property (nonatomic, assign) KCModelPropertyType propertyType;

- (instancetype)initWithPropertyName:(NSString *)propertyName objcProperty:(objc_property_t)objcProperty;

@end

@interface NSDictionary (KCModel)

- (id)kc_valueForKeyPath:(NSString *)keyPath;

@end

@implementation KCModel

#pragma mark -- KCItemAutoBinding
+ (id<KCModelAutoBinding>)modelWithDictionary:(NSDictionary *)dictionary
{
    id<KCModelAutoBinding> model = [[self class] new];
    [model autoBindingWithDictionary:dictionary];

    return model;
}

+ (NSArray *)modelsWithArray:(NSArray *)array
{
    NSMutableArray *models = @[].mutableCopy;
    for (NSDictionary *dict in array) {
        if (![dict isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        [models addObject:[self modelWithDictionary:dict]];
    }
    
    return [NSArray arrayWithArray:models];
}

- (void)autoBindingWithDictionary:(NSDictionary *)dictionary
{
    NSDictionary *properties = [self.class propertyInfos]; //所有属性信息
    NSDictionary *dictionaryKeyPathByPropertyKey = [self.class dictionaryKeyPathByPropertyKey]; //属性对应的路径
    
    for (KCModelProperty *property in [properties allValues]) {
        KCModelPropertyType propertyType = property.propertyType;
        NSString *propertyName = property.propertyName;
        NSString *propertyClassName = property.propertyClassName; //属性类名，有则为自定义的类，无则为系统自带类型
        NSString *propertyKeyPath = propertyName;
        
        //获取属性映射的dictionary内容位置
        if ([dictionaryKeyPathByPropertyKey objectForKey:propertyName]) {
            propertyKeyPath = [dictionaryKeyPathByPropertyKey objectForKey:propertyName];
        }
        
        id value = [dictionary kc_valueForKeyPath:propertyKeyPath]; //从dictionary中得到映射的值
        
        if (value == nil || value == [NSNull null]) {
            continue;
        }
        
        Class propertyClass = nil;
        if (propertyClassName.length > 0) {  //非系统自带对象
            propertyClass = NSClassFromString(propertyClassName);
        }
        
        //转换value
        switch (propertyType) {
            /**************************系统自带类型******************************/
            //基本数据类型
            case KCModelPropertyTypeInt:
            case KCModelPropertyTypeFloat:
            case KCModelPropertyTypeDouble:
            case KCModelPropertyTypeBool:
            case KCModelPropertyTypeNumber:{
                if ([value isKindOfClass:[NSString class]]) {
                    NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
                    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
                    value = [numberFormatter numberFromString:value];
                }else{
                    value = KCTransformNormalValueForClass(value, NSStringFromClass([NSNumber class]));
                }
            }
                break;
            case KCModelPropertyTypeChar:{
                if ([value isKindOfClass:[NSString class]]) {
                    char firstCharacter = [value characterAtIndex:0];
                    value = [NSNumber numberWithChar:firstCharacter];
                } else {
                    value = KCTransformNormalValueForClass(value, NSStringFromClass([NSNumber class]));
                }
            }
                break;
            case KCModelPropertyTypeString:{
                if ([value isKindOfClass:[NSNumber class]]) {
                    value = [value stringValue];
                } else {
                    value = KCTransformNormalValueForClass(value, NSStringFromClass([NSString class]));
                }
            }
                break;
            case KCModelPropertyTypeData:{
                value = KCTransformNormalValueForClass(value, NSStringFromClass([NSData class]));
            }
                break;
            case KCModelPropertyTypeDate:{
                value = KCTransformNormalValueForClass(value, NSStringFromClass([NSDate class]));
            }
                break;
            case KCModelPropertyTypeAny:
                break;
            case KCModelPropertyTypeDictionary:{
                value = KCTransformNormalValueForClass(value, NSStringFromClass([NSDictionary class]));
            }
                break;
            case KCModelPropertyTypeMutableDictionary:{
                value = KCTransformNormalValueForClass(value, NSStringFromClass([NSDictionary class]));
                value = [value mutableCopy];
            }
                break;
            case KCModelPropertyTypeArray:{
                if (propertyClass && [propertyClass conformsToProtocol:@protocol(KCModelAutoBinding)]) {  //数组内元素为实现了KCModelAutoBinding协议的对象
                    value = [propertyClass modelsWithArray:value];
                }else{
                    value = KCTransformNormalValueForClass(value, NSStringFromClass([NSArray class]));
                }
            }
                break;
            case KCModelPropertyTypeMutableArray:{
                value = KCTransformNormalValueForClass(value, NSStringFromClass([NSArray class]));
                value = [value mutableCopy];
            }
                break;
            /**************************自定义类型******************************/
            case KCModelPropertyTypeObject:
            case KCModelPropertyTypeModel:{
                if (propertyClass) {
                    if ([propertyClass conformsToProtocol:@protocol(KCModelAutoBinding)]
                        && [value isKindOfClass:[NSDictionary class]]) {  //属性为实现了KCModelAutoBinding协议的对象
                        NSDictionary *oldValue = value;
                        value = [[propertyClass alloc] init];
                        [value autoBindingWithDictionary:oldValue];
                    }else{
                        value = KCTransformNormalValueForClass(value, propertyClassName);
                    }
                }
            }
                break;
        }
        
        //KVC
        if (value && value != [NSNull null]) {
            [self setValue:value forKey:propertyName];
        }
    }
}

#pragma mark -- NSCoding
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        for (NSString *propertyName in [[self class] propertyNames]) {
            id value = [aDecoder decodeObjectForKey:propertyName];
            [self setValue:value forKey:propertyName];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    for (NSString *propertyName in [[self class] propertyNames]) {
        id value = [self valueForKey:propertyName];
        [aCoder encodeObject:value forKey:propertyName];
    }
}

#pragma mark -- Class method
/**
 类的属性信息

 @return NSDictionary，key为属性名，value为KCModelProperty
 */
+ (NSDictionary *)propertyInfos
{
    //获取缓存数据
    NSDictionary *cachedInfos = objc_getAssociatedObject(self, _cmd);
    if (cachedInfos != nil) {
        return cachedInfos;
    }
    
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList(self, &propertyCount); //获取类的所有属性
    Class superClass = class_getSuperclass(self);  //父类名
    
    //获取父类的所有属性，直到没有父类或者父类为KCModel为止
    if (superClass && ![NSStringFromClass(superClass) isEqualToString:@"KCModel"]) {
        //递归
        NSDictionary *superProperties = [superClass propertyInfos];
        [ret addEntriesFromDictionary:superProperties];
    }
    
    for (int i = 0; i < propertyCount; i++) {
        objc_property_t property = properties[i];   //获取第i个属性
        const char *propertyCharName = property_getName(property);  //获取属性的名称
        NSString *propertyName = @(propertyCharName);
        
        KCModelProperty *propertyInfo = [[KCModelProperty alloc] initWithPropertyName:propertyName objcProperty:property];
        [ret setValue:propertyInfo forKey:propertyName];
    }
    
    free(properties);
    
    //设置缓存数据
    objc_setAssociatedObject(self, @selector(propertyInfos), ret, OBJC_ASSOCIATION_COPY);
    
    return ret;
}

+ (NSDictionary *)dictionaryKeyPathByPropertyKey
{
    return [NSDictionary dictionaryWithObjects:[self propertyNames] forKeys:[self propertyNames]];
}

+ (NSArray *)propertyNames
{
    NSDictionary *ret = [self propertyInfos];
    return [ret allKeys];
}

@end


@implementation KCModelProperty

- (instancetype)initWithPropertyName:(NSString *)propertyName objcProperty:(objc_property_t)objcProperty
{
    if (self = [super init]) {
        _propertyName = propertyName;
        
        const char *attr = property_getAttributes(objcProperty);
        NSString *propertyAttributes = @(attr); //使用","隔开的属性描述字符串
        propertyAttributes = [propertyAttributes substringFromIndex:1]; //移除"T"
        
        NSArray *attributes = [propertyAttributes componentsSeparatedByString:@","]; //属性描述数组
        
        NSString *typeAttr = attributes[0];  //属性类型名称
        const char *typeCharAttr = [typeAttr UTF8String];
        
        NSString *encodeCodeStr = [typeAttr substringToIndex:1];  //属性类型
        const char *encodeCode = [encodeCodeStr UTF8String];
        const char typeEncoding = *encodeCode;
        
        //判断类型
        switch (typeEncoding) {
            case 'i': // int
            case 's': // short
            case 'l': // long
            case 'q': // long long
            case 'I': // unsigned int
            case 'S': // unsigned short
            case 'L': // unsigned long
            case 'Q': // unsigned long long
                _propertyType = KCModelPropertyTypeInt;
                break;
            case 'f': // float
                _propertyType = KCModelPropertyTypeFloat;
                break;
            case 'd': // double
                _propertyType = KCModelPropertyTypeDouble;
                break;
            case 'B': // BOOL
                _propertyType = KCModelPropertyTypeBool;
                break;
            case 'c': // char
            case 'C': // unsigned char
                _propertyType = KCModelPropertyTypeChar;
                break;
            case '@':{ //object
                
                
                static const char arrayPrefix[] = "@\"NSArray<";  //NSArray,且遵循某个协议
                static const int arrayPrefixLen = sizeof(arrayPrefix) - 1;
                
                if (typeCharAttr[1] == '\0') {
                    // string is "@"
                    _propertyType = KCModelPropertyTypeAny;
                } else if (strncmp(typeCharAttr, arrayPrefix, arrayPrefixLen) == 0) {
                    /*******************
                     因为只有NSArray遵循某个协议才能被property_getAttributes()函数识别出来，
                     以此为标记表示这个数组存储着以协议名为类名的Model对象
                     *******************/
                    _propertyType = KCModelPropertyTypeArray;
                    NSString *className = [[NSString alloc] initWithBytes:typeCharAttr + arrayPrefixLen
                                                                   length:strlen(typeCharAttr + arrayPrefixLen) - 2
                                                                 encoding:NSUTF8StringEncoding];
                    
                    Class propertyClass = NSClassFromString(className);
                    if (propertyClass) {
                        _propertyClassName = NSStringFromClass(propertyClass);
                    }
                } else if (strcmp(typeCharAttr, "@\"NSString\"") == 0) {
                    _propertyType = KCModelPropertyTypeString;
                } else if (strcmp(typeCharAttr, "@\"NSNumber\"") == 0) {
                    _propertyType = KCModelPropertyTypeNumber;
                } else if (strcmp(typeCharAttr, "@\"NSDate\"") == 0) {
                    _propertyType = KCModelPropertyTypeDate;
                } else if (strcmp(typeCharAttr, "@\"NSData\"") == 0) {
                    _propertyType = KCModelPropertyTypeData;
                } else if (strcmp(typeCharAttr, "@\"NSDictionary\"") == 0) {
                    _propertyType = KCModelPropertyTypeDictionary;
                } else if (strcmp(typeCharAttr, "@\"NSArray\"") == 0) {
                    _propertyType = KCModelPropertyTypeArray;
                } else if (strcmp(typeCharAttr, "@\"NSMutableArray\"") == 0){
                    _propertyType = KCModelPropertyTypeMutableArray;
                } else if (strcmp(typeCharAttr, "@\"NSMutableDictionary\"") == 0){
                    _propertyType = KCModelPropertyTypeMutableDictionary;
                }else {
                    _propertyType = KCModelPropertyTypeObject;
                    
                    Class propertyClass = nil;
                    if (typeAttr.length >= 3) {
                        NSString* className = [typeAttr substringWithRange:NSMakeRange(2, typeAttr.length-3)];
                        propertyClass = NSClassFromString(className);
                    }
                    
                    if (propertyClass) {
                        if ([propertyClass isSubclassOfClass:[KCModel class]]) {
                            _propertyType = KCModelPropertyTypeModel;
                        }
                        _propertyClassName = NSStringFromClass(propertyClass);
                    }
                    
                }
            }
                break;
            default:
                break;
        }
    }
    return self;
}

@end

@implementation NSDictionary (KCModel)

- (id)kc_valueForKeyPath:(NSString *)keyPath
{
    NSArray *components = [keyPath componentsSeparatedByString:@"."];
    
    id ret = self;
    for (NSString *component in components) {
        if (ret == nil || ret == [NSNull null] || ![ret isKindOfClass:[NSDictionary class]]) {
            break;
        }
        ret = ret[component];
    }
    return ret;
}

@end

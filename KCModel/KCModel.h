//
//  KCModel.h
//  KCModel
//
//  Created by Koce on 16/11/25.
//  Copyright © 2016年 Koce. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//快速定义与类相同名称的协议（数组元素类型标记）
#define KC_ARRAY_TYPE(VAL) \
        @protocol VAL <NSObject> \
        @end

@protocol KCModelAutoBinding <NSObject>

+ (id<KCModelAutoBinding>)modelWithDictionary:(NSDictionary *)dictionary;
+ (NSArray *)modelsWithArray:(NSArray *)array;
- (void)autoBindingWithDictionary:(NSDictionary *)dictionary;

@end

@interface KCModel : NSObject <KCModelAutoBinding, NSCoding>
/**
 子类复写，属性对应于字典的路径

 @return NSDictionary，key为属性名，value为路径
 */
+ (NSDictionary *)dictionaryKeyPathByPropertyKey;

@end

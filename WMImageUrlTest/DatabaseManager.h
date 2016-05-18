//
//  DatabaseManager.h
//  WMImageUrlTest
//
//  Created by wangwendong on 16/5/18.
//  Copyright © 2016年 sunricher. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, DatabaseSelectType) {
    DatabaseSelectTypeImage,
    DatabaseSelectTypeImageUrl,
    DatabaseSelectTypeImageUrlId
};

@interface DatabaseManager : NSObject

+ (instancetype)sharedDatabaseManager;

- (BOOL)insertImage:(UIImage *)image;

- (BOOL)updateImage:(UIImage *)image imageUrl:(NSString *)imageUrl;

- (BOOL)deleteImageByImageUrlId:(NSInteger)imageUrlId;

- (BOOL)deleteImageByImageUrl:(NSString *)imageUrl;

- (NSString *)imageUrlWithImageUrlId:(NSInteger)imageUrlId;

- (UIImage *)imageWithImageUrlId:(NSInteger)imageUrlId;

- (UIImage *)imageWithImageUrl:(NSString *)imageUrl;

- (NSArray *)imagesArrayWithType:(DatabaseSelectType)type;

@end

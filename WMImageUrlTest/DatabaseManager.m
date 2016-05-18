
//
//  DatabaseManager.m
//  WMImageUrlTest
//
//  Created by wangwendong on 16/5/18.
//  Copyright © 2016年 sunricher. All rights reserved.
//

#import "DatabaseManager.h"
#import <sqlite3.h>

static NSString *const DatabaseName = @"db_image_url";

@interface DatabaseManager ()

@property (nonatomic) sqlite3 *database;

@end

@implementation DatabaseManager

+ (instancetype)sharedDatabaseManager {
    static id instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^ {
        instance = [[DatabaseManager alloc] init];
    });
    
    return instance;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        [self setupImagePath];
        
        [self setupDatabase];
    }
    
    return self;
}

- (BOOL)insertImage:(UIImage *)image {
    if (!image) {
        NSLog(@"insert image failure, image is nil");
        
        return false;
    }
    
    NSString *newImageUrl = [self newImageUrl];
    
    NSString *saveImageUrl = [NSHomeDirectory() stringByAppendingString:newImageUrl];
    
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:saveImageUrl];
    
    if (isExists) {
        NSLog(@"insert image failure, image url is exist");
        
        return false;
    }
    
    BOOL insertResult = [UIImageJPEGRepresentation(image, 1.0) writeToFile:saveImageUrl atomically:YES];
    
    if (!insertResult) {
        return false;
    }
    
    sqlite3_open([self databasePath], &_database);
    
    BOOL isImageUrlExistInDB = [self isImageUrlExistInDB:newImageUrl];
    
    if (!isImageUrlExistInDB) {
        const char *insertSQL = "insert into tb_image_url values(null, ?)";
        sqlite3_stmt *stmt;
        int result = sqlite3_prepare_v2(_database, insertSQL, -1, &stmt, NULL);
        
        if (result == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, newImageUrl.UTF8String, -1, NULL);
            
            sqlite3_step(stmt);
            
            sqlite3_finalize(stmt);
        }
    }
    
    sqlite3_close(_database);
    
    return true;
}

- (BOOL)updateImage:(UIImage *)image imageUrl:(NSString *)imageUrl {
    
    if (!imageUrl) {
        NSLog(@"update image failure, image url is nil");
        
        return false;
    }
    
    if (!image) {
        NSLog(@"update image failure, image is nil");
        
        return false;
    }
    
    NSString *saveImageUrl = [NSHomeDirectory() stringByAppendingString:imageUrl];
    
    [[NSFileManager defaultManager] removeItemAtPath:saveImageUrl error:nil];
    
    sqlite3_open([self databasePath], &_database);
    
    BOOL isImageUrlExistInDB = [self isImageUrlExistInDB:imageUrl];
    
    if (!isImageUrlExistInDB) {
        const char *insertSQL = "insert into tb_image_url values(null, ?)";
        sqlite3_stmt *stmt;
        int result = sqlite3_prepare_v2(_database, insertSQL, -1, &stmt, NULL);
        
        if (result == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, imageUrl.UTF8String, -1, NULL);
            
            sqlite3_step(stmt);
            
            sqlite3_finalize(stmt);
        }
    }
    
    sqlite3_close(_database);
    
    return [UIImageJPEGRepresentation(image, 1.0) writeToFile:saveImageUrl atomically:YES];
}

- (BOOL)deleteImageByImageUrlId:(NSInteger)imageUrlId {
    NSString *imageUrl = [self imageUrlWithImageUrlId:imageUrlId];

    return [self deleteImageByImageUrl:imageUrl];
}

- (BOOL)deleteImageByImageUrl:(NSString *)imageUrl {
    if (!imageUrl) {
        NSLog(@"delete failure, image url is nil");
        
        return false;
    }
    
    sqlite3_open([self databasePath], &_database);
    
    const char *deleteSQL = "delete from tb_image_url where url=?";
    sqlite3_stmt *deleteStmt;
    int deleteResult = sqlite3_prepare_v2(_database, deleteSQL, -1, &deleteStmt, NULL);
    
    if (deleteResult == SQLITE_OK) {
        sqlite3_bind_text(deleteStmt, 1, imageUrl.UTF8String, -1, NULL);
        
        sqlite3_step(deleteStmt);
        
        sqlite3_finalize(deleteStmt);
    }
    
    sqlite3_close(_database);

    
    BOOL isImageUrlExist = [[NSFileManager defaultManager] fileExistsAtPath:[NSHomeDirectory() stringByAppendingString:imageUrl]];
    
    if (isImageUrlExist) {
        
        return [[NSFileManager defaultManager] removeItemAtPath:[NSHomeDirectory() stringByAppendingString:imageUrl] error:nil];
    } else {
        NSLog(@"delete failure, image url %@ is not exist", imageUrl);
    }
    
    return false;
}

- (NSString *)imageUrlWithImageUrlId:(NSInteger)imageUrlId {

    NSString *imageUrl = nil;
    
    sqlite3_open([self databasePath], &_database);
    
    const char *selectImageUrlSQL = "select url from tb_image_url where image_url_id=?";
    sqlite3_stmt *stmt;
    int selectResult = sqlite3_prepare_v2(_database, selectImageUrlSQL, -1, &stmt, NULL);
    
    if (selectResult == SQLITE_OK) {
        sqlite3_bind_int(stmt, 1, (int)imageUrlId);
        
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            const void *url = sqlite3_column_text(stmt, 0);
            
            imageUrl = [NSString stringWithUTF8String:(const char *)url];
            
            break;
        }
        
        sqlite3_finalize(stmt);
    }
    
    sqlite3_close(_database);
    
    return imageUrl;
}

- (UIImage *)imageWithImageUrlId:(NSInteger)imageUrlId {

    NSString *imageUrl = [self imageUrlWithImageUrlId:imageUrlId];
    
    return [self imageWithImageUrl:imageUrl];
}

- (UIImage *)imageWithImageUrl:(NSString *)imageUrl {
    
    if (!imageUrl) {
        return nil;
    }
    
    UIImage *image = [UIImage imageWithContentsOfFile:[NSHomeDirectory() stringByAppendingString:imageUrl]];

    return image;
}

- (NSArray *)imagesArrayWithType:(DatabaseSelectType)type {
    NSMutableArray *imagesMutableArray = [NSMutableArray array];
    
    sqlite3_open([self databasePath], &_database);
    
    char *temp;
    
    switch (type) {
        case DatabaseSelectTypeImage:
            temp = "select url from tb_image_url order by image_url_id";
            
            break;
        case DatabaseSelectTypeImageUrl:
            temp = "select url from tb_image_url order by image_url_id";
            
            break;
        case DatabaseSelectTypeImageUrlId:
            temp = "select image_url_id from tb_image_url order by image_url_id";
            
            break;
    }
    
    const char *selectSQL = temp;
    sqlite3_stmt *selectStmt;
    int selectResult = sqlite3_prepare_v2(_database, selectSQL, -1, &selectStmt, NULL);
    
    if (selectResult == SQLITE_OK) {
        while (sqlite3_step(selectStmt) == SQLITE_ROW) {
            
            switch (type) {
                case DatabaseSelectTypeImage: {
                    const void *imageUrl = sqlite3_column_text(selectStmt, 0);
                    
                    NSString *imageUrlString = [NSString stringWithUTF8String:(const char *)imageUrl];
                    
                    UIImage *image = [self imageWithImageUrl:imageUrlString];
                    
                    if (image) {
                        [imagesMutableArray addObject:image];
                    }
                    
                    break;
                }
                case DatabaseSelectTypeImageUrl: {
                    const void *imageUrl = sqlite3_column_text(selectStmt, 0);
                    NSString *imageUrlString = imageUrl ? [NSString stringWithUTF8String:(const char *)imageUrl] : nil;
                    
                    if (imageUrlString) {
//                        NSArray *comps = [imageUrlString componentsSeparatedByString:@"/"];
//                        
//                        [imagesMutableArray addObject:comps.lastObject];
                        
                        [imagesMutableArray addObject:imageUrlString];
                    }
                    
                    break;
                }
                case DatabaseSelectTypeImageUrlId: {
                    int imageUrlId = sqlite3_column_int(selectStmt, 0);
                    
                    [imagesMutableArray addObject:@(imageUrlId)];
                    
                    break;
                }
            }
        }
        
        sqlite3_finalize(selectStmt);
    }
    
    sqlite3_close(_database);
    
    return [NSArray arrayWithArray:imagesMutableArray];
}

#pragma mark - Private

#pragma mark - Setup

- (void)setupDatabase {
    sqlite3_open([self databasePath], &_database);
    
    char *errMsg;
    
    const char *createImageUrlTableSQL = "create table if not exists tb_image_url (image_url_id integer primary key autoincrement, url)";
    
    int createResult = sqlite3_exec(_database, createImageUrlTableSQL, NULL, NULL, &errMsg);
    
    if (createResult != SQLITE_OK) {
        NSLog(@"create image url table err %s", errMsg);
    } else {
        NSLog(@"create image url table success");
    }
    
    sqlite3_close(_database);
}

#pragma mark - Database path

- (const char *)databasePath {
    NSString *databasePath = @"";
    
    NSString *documentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    databasePath = [documentsPath stringByAppendingPathComponent:DatabaseName];
    
    return databasePath.UTF8String;
}

- (NSString *)newImageUrl {
    NSString *newImageUrl = @"/Documents/Images";
    
    int maxId = 1;
    
    sqlite3_open([self databasePath], &_database);
    
    const char *selectMaxId = "select max(image_url_id) from tb_image_url";
    sqlite3_stmt *stmt;
    int selectResult = sqlite3_prepare_v2(_database, selectMaxId, -1, &stmt, NULL);
    
    if (selectResult == SQLITE_OK) {
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            maxId = sqlite3_column_int(stmt, 0) + 1;
            
            break;
        }
        
        sqlite3_finalize(stmt);
    }
    
    sqlite3_close(_database);
    
    newImageUrl = [NSString stringWithFormat:@"%@/%d.jpg",newImageUrl, (int)maxId];
    
    return newImageUrl;
}

- (BOOL)isImageUrlExistInDB:(NSString *)imageUrl {
    if (!imageUrl) {
        return false;
    }
    
    BOOL isImageUrlExistInDB = false;
    
    const char *selectSQL = "select * from tb_image_url where url=?";
    sqlite3_stmt *selectStmt;
    int selectResult = sqlite3_prepare_v2(_database, selectSQL, -1, &selectStmt, NULL);
    
    if (selectResult == SQLITE_OK) {
        sqlite3_bind_text(selectStmt, 1, imageUrl.UTF8String, -1, NULL);
        
        while (sqlite3_step(selectStmt) == SQLITE_ROW) {
            isImageUrlExistInDB = true;
            
            break;
        }
        
        sqlite3_finalize(selectStmt);
    }

    return isImageUrlExistInDB;
}

- (void)setupImagePath {
    NSString *newImageUrl = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    newImageUrl = [newImageUrl stringByAppendingPathComponent:@"Images"];
    
    BOOL isImagePathExist = [[NSFileManager defaultManager] fileExistsAtPath:newImageUrl];
    
    if (isImagePathExist) {
        return;
    }
    
    [[NSFileManager defaultManager] createDirectoryAtPath:newImageUrl withIntermediateDirectories:YES attributes:nil error:nil];
}

@end

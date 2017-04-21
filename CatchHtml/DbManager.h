//
//  DbManager.h
//  XiaoYa
//
//  Created by commet on 17/1/16.
//  Copyright © 2017年 commet. All rights reserved.
// 数据库方法封装。单例

#import <Foundation/Foundation.h>
#import <sqlite3.h>
//#import "DbSingleton.h"

@interface DbManager : NSObject
@property (nonatomic,assign) sqlite3 *database;

+(instancetype) shareInstance ;

#pragma mark - 共有方法
/**
 *  打开数据库
 *
 *  @param dbname 数据库名称
 */
-(void)openDb:(NSString *)dbname;

/**
 *  执行无返回值的sql
 *
 *  @param sql sql语句
 */
-(void)executeNonQuery:(NSString *)sql;

/**
 *  执行有返回值的sql
 *
 *  @param sql sql语句
 *
 *  @return 查询结果
 */
-(NSArray *)executeQuery:(NSString *)sql;

//开始事务
- (void)beginTransaction;

//提交事务
- (void)commitTransaction;
@end

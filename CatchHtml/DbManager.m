//
//  DbManager.m
//  XiaoYa
//
//  Created by commet on 17/1/16.
//  Copyright © 2017年 commet. All rights reserved.
//

#import "DbManager.h"
@interface DbManager()<NSCopying,NSMutableCopying>
@end

@implementation DbManager
static DbManager* _instance = nil;

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL] init] ;
    }) ;
    
    return _instance ;
}

+ (id)allocWithZone:(struct _NSZone *)zone
{
    return [DbManager shareInstance] ;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [DbManager shareInstance] ;//return _instance;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [DbManager shareInstance] ;
}



-(void)openDb:(NSString *)dbname{
    //取得数据库保存路径，通常保存沙盒Documents目录
    NSString *directory=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
    NSLog(@"%@",directory);
    NSString *filePath=[directory stringByAppendingPathComponent:dbname];
    //如果有数据库则直接打开，否则创建并打开（注意filePath是ObjC中的字符串，需要转化为C语言字符串类型）
    if (SQLITE_OK == sqlite3_open(filePath.UTF8String, &_database)) {
        NSLog(@"数据库打开成功!");
    }else{
        NSLog(@"数据库打开失败!");
        sqlite3_close(_database);
    }
}

-(void)executeNonQuery:(NSString *)sql{
    char *error;
    //单步执行sql语句，用于插入、修改、删除
    if (SQLITE_OK != sqlite3_exec(_database, sql.UTF8String, NULL, NULL,&error)) {
        NSLog(@"执行SQL语句过程中发生错误！错误信息：%s,%@",error,sql);
    }
}

////执行 insert,update,delete 等非查询SQL语句
//- (int)executeNonQuery:(NSString *)sql error:(NSError **)error {
//    int rc;
//    char *errmsg;
//    rc = [self open];
//    if (rc) {
//        //错误处理
//        if (error != NULL) {
//            NSDictionary *eDict = [NSDictionary dictionaryWithObject:@"open database failed"
//                                        forKey:NSLocalizedDescriptionKey];
//            *error = [NSError errorWithDomain:kSqliteErrorDomain code:rc userInfo:eDict];
//        }
//        return rc;
//    }
//    rc = sqlite3_exec(database, [sql UTF8String], NULL, NULL, &amp;errmsg);
//    if (rc != SQLITE_OK) {
//        if (error != NULL) {
//            NSDictionary *eDict = [NSDictionary dictionaryWithObject:@"exec sql error"
//                                        forKey:NSLocalizedDescriptionKey];
//            *error = [NSError errorWithDomain:kSqliteErrorDomain code:rc userInfo:eDict];
//        }
//        NSLog(@"%s", errmsg);
//        sqlite3_free(errmsg);
//    }
//    [self close];
//    return rc;
//}

-(NSArray *)executeQuery:(NSString *)sql{
    NSMutableArray *rows=[NSMutableArray array];//数据行
    
    //评估语法正确性
    sqlite3_stmt *stmt;
    //检查语法正确性
    if (SQLITE_OK==sqlite3_prepare_v2(_database, sql.UTF8String, -1, &stmt, NULL)) {
        //单步执行sql语句
        while (SQLITE_ROW==sqlite3_step(stmt)) {
            int columnCount= sqlite3_column_count(stmt);
            NSMutableDictionary *dic=[NSMutableDictionary dictionary];
            for (int i=0; i<columnCount; i++) {
                const char *name= sqlite3_column_name(stmt, i);//取得列名
                const unsigned char *value= sqlite3_column_text(stmt, i);//取得某列的值
                dic[[NSString stringWithUTF8String:name]]=[NSString stringWithUTF8String:(const char *)value];
            }
            [rows addObject:dic];
        }
    }
    
    //释放句柄
    sqlite3_finalize(stmt);
    
    return rows;
}

//关闭数据库
- (void) close{
    if (_database != NULL) {
        sqlite3_close(_database);
    }
}

//开始事务
- (void)beginTransaction{
    char *errmsg;
    if (SQLITE_OK != sqlite3_exec(_database, "BEGIN TRANSACTION", NULL, NULL, &errmsg)){
        NSLog(@"开始事务过程中发生错误！错误信息：%s",errmsg);
    }
}

//提交事务
- (void)commitTransaction{
    char *errmsg;
    if (SQLITE_OK != sqlite3_exec(_database, "COMMIT TRANSACTION", NULL, NULL, &errmsg)){
        NSLog(@"提交事务过程中发生错误！错误信息：%s",errmsg);
    }
}
@end

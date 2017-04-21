//
//  ViewController.m
//  CatchHtml
//
//  Created by commet on 17/3/21.
//  Copyright © 2017年 commet. All rights reserved.
//

#import "ViewController.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import "TFHpple.h"
#import "DbManager.h"
@interface ViewController ()<NSURLSessionDataDelegate,NSURLSessionTaskDelegate>
@property (nonatomic ,strong)EKEventStore *eventStore;
@property (nonatomic ,strong)EKCalendar *cal;

@property (nonatomic ,strong)NSURLSession *session;
@property (nonatomic ,strong)NSURLSessionDataTask *task;
@property (nonatomic ,strong)NSString *mainUrl;

@property (nonatomic ,copy)NSString *viewState;
@property (nonatomic ,copy)NSString *randomStr;
@property (nonatomic ,copy)NSString *httpHost;
@property (nonatomic ,copy)NSString *name;
@property (nonatomic ,strong)NSMutableData *httpData;
@property (nonatomic ,strong)DbManager *dbManager;

@property (weak, nonatomic) IBOutlet UIImageView *img;
@property (weak, nonatomic) IBOutlet UITextField *txf;

@end

@implementation ViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.dbManager = [DbManager shareInstance];
    [self.dbManager openDb:@"eventData.sqlite"];
    [self.dbManager executeNonQuery:@"drop table if exists course_table"];
    NSString *sql2 = [NSString stringWithFormat:@"create table IF NOT EXISTS  course_table(                                                                                                                id integer primary key autoincrement,                                                                       courseName text not null,                                                                                                                                        weeks text not null,                                                                                                                                                            weekday text not null,                                                                                                                                                              time text not null,                                                                                                                                                               place text not null);"];
    [self.dbManager executeNonQuery:sql2];
    
    self.mainUrl = @"http://jw2005.scuteo.com/";
}

- (NSMutableData *)httpData{
    if (_httpData == nil) {
        _httpData = [NSMutableData data];
    }
    return _httpData;
}

- (IBAction)viewStateAndRandomStrGetting:(id)sender {
    NSURL *url = [NSURL URLWithString:self.mainUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    [request addValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    [request addValue:@"jw2005.scuteo.com" forHTTPHeaderField:@"Host"];
    self.task = [self.session dataTaskWithRequest:request];
    self.task.taskDescription = @"getViewStateAndRandomStr";
    [self.task resume];
}

-(void)shuaXinYanZhengMa{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/%@/CheckCode.aspx",self.httpHost,self.randomStr]];
    NSMutableURLRequest *UrlRequest = [NSMutableURLRequest requestWithURL:url];
//    UrlRequest.HTTPShouldHandleCookies = YES;
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSHTTPCookie *cookie = [[cookieJar cookiesForURL:[NSURL URLWithString:self.mainUrl]]firstObject];
    [UrlRequest setValue:[NSString stringWithFormat:@"%@=%@", [cookie name], [cookie value]] forHTTPHeaderField:@"Cookie"];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:UrlRequest];
    task.taskDescription = @"getCheckCode";
    [task resume];
}

- (IBAction)a:(id)sender {
    [self shuaXinYanZhengMa];
}

- (IBAction)login:(id)sender {
    NSString *paraStr = [NSString stringWithFormat:@"__VIEWSTATE=%@&txtUserName=201430252193&TextBox2=bmelhf2807301&txtSecretCode=%@&RadioButtonList1=学生&Button1=&lbLanguage=&hidPdrs=&hidsc=",self.viewState,self.txf.text];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/%@/default2.aspx",self.httpHost,self.randomStr]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding (kCFStringEncodingGB_18030_2000);
    request.HTTPBody = [paraStr dataUsingEncoding:enc];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
    task.taskDescription = @"login";
    [task resume];
}

- (IBAction)courseGetting:(id)sender {
    NSString *urlstr = [NSString stringWithFormat:@"http://%@/%@/xskbcx.aspx?xh=201430252193&xm=%@&gnmkdm=N121603",self.httpHost,self.randomStr,self.name];
    urlstr = [urlstr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    NSURL *url = [NSURL URLWithString:urlstr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod= @"GET";
    [request addValue:[NSString stringWithFormat:@"http://%@/%@/xs_main.aspx?xh=201430252193",self.httpHost,self.randomStr] forHTTPHeaderField:@"Referer"];//这句一定不能漏
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
    task.taskDescription = @"courseget";
    [task resume];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    completionHandler(NSURLSessionResponseAllow);
    if ([dataTask.taskDescription isEqualToString:@"getViewStateAndRandomStr"]) {
        NSLog(@"getCookies---response:\n%@",response);
        NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *cookie in [cookieJar cookies]) {
            NSLog(@"cookie%@", cookie);
        }
        //这里要用正则表达式提取比较好
        self.httpHost = response.URL.host;
//        NSLog(@"httpHost:%@",self.httpHost);
//        NSLog(@"response.URL.path:%@",response.URL.path);
        self.randomStr = [response.URL.absoluteString substringWithRange:NSMakeRange(21, 26)];
        NSLog(@"%@",self.randomStr);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    [data enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
        [self.httpData appendBytes:bytes length:byteRange.length];
    }];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if (error) {
        NSLog(@"error:%@",error);
        return;
    }
    if ([task.taskDescription isEqualToString:@"getViewStateAndRandomStr"]) {
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding (kCFStringEncodingGB_18030_2000);
        NSString *transtr = [[NSString alloc]initWithData:self.httpData encoding:enc];
        NSString *htmlUTF8Str = [transtr stringByReplacingOccurrencesOfString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=gb2312\">" withString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"];
        NSData *htmlDataUTF8 = [htmlUTF8Str dataUsingEncoding:NSUTF8StringEncoding];
        TFHpple *xpathParser = [[TFHpple alloc]initWithHTMLData:htmlDataUTF8];
        NSArray *elements  = [xpathParser searchWithXPathQuery:@"//input[@name='__VIEWSTATE']"];
        for (int i=0; i<[elements count]; i++) {
            TFHppleElement *element = [elements objectAtIndex:i];
            self.viewState=[element objectForKey:@"value"];
            NSLog(@"提取到得viewstate为%@",self.viewState);
            self.viewState = [self.viewState stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
            self.viewState = [self.viewState stringByReplacingOccurrencesOfString:@"=" withString:@"%3D"];
        }
        self.httpData = nil;
    }
    if ([task.taskDescription isEqualToString:@"getCheckCode"]){
        dispatch_async(dispatch_get_main_queue(), ^{
            self.img.image = [[UIImage alloc]initWithData:self.httpData];
            self.httpData = nil;
        });
    }
    if ([task.taskDescription isEqualToString:@"login"]) {
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding (kCFStringEncodingGB_18030_2000);
        NSString *transtr = [[NSString alloc]initWithData:self.httpData encoding:enc];
        NSString *utf8HtmlStr = [transtr stringByReplacingOccurrencesOfString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=gb2312\">" withString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"];
        NSData *htmlDataUTF8 = [utf8HtmlStr dataUsingEncoding:NSUTF8StringEncoding];
        TFHpple *xpathParser = [[TFHpple alloc]initWithHTMLData:htmlDataUTF8];
        NSArray *elements  = [xpathParser searchWithXPathQuery:@"//span[@id='xhxm']"];
        if (elements.count > 0) {
            for (int i=0; i<[elements count]; i++) {
                TFHppleElement *element = [elements objectAtIndex:i];
                NSString *content = [element text];
                self.name=[content substringToIndex:[content length]-2];
                NSLog(@"姓名为%@",self.name);
            }
        }
        else{
            NSArray *errElement = [xpathParser searchWithXPathQuery:@"//script[@language='javascript']"];
            TFHppleElement *scriptNode = errElement.lastObject;//验证码不正确
            NSString *alertMessage = [[scriptNode.content componentsSeparatedByString:@";"]firstObject];
            alertMessage = [[alertMessage componentsSeparatedByString:@"("]lastObject];
            alertMessage = [[alertMessage componentsSeparatedByString:@")"]firstObject];
            UIAlertController *alert ;
            if ([alertMessage isEqualToString:@"'用户名不存在或未按要求参加教学活动！！'"]) {
                alert = [UIAlertController alertControllerWithTitle:@"警告" message:@"用户名不存在或未按要求参加教学活动！！" preferredStyle:UIAlertControllerStyleAlert];
            }else if ([alertMessage isEqualToString:@"'密码错误！！'"]){
                alert = [UIAlertController alertControllerWithTitle:@"警告" message:@"密码错误！！" preferredStyle:UIAlertControllerStyleAlert];
            }else if ([alertMessage isEqualToString:@"'验证码不正确！！'"]){
                alert = [UIAlertController alertControllerWithTitle:@"警告" message:@"验证码不正确！！" preferredStyle:UIAlertControllerStyleAlert];
            }
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"重新输入" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            }];
            [alert addAction:action];
            [self presentViewController:alert animated:YES completion:nil];
            [self shuaXinYanZhengMa];
        }
        self.httpData = nil;//清空数据
    }
    if ([task.taskDescription isEqualToString:@"courseget"]){
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding (kCFStringEncodingGB_18030_2000);
        NSString *transtr = [[NSString alloc]initWithData:self.httpData encoding:enc];
        NSString *utf8HtmlStr = [transtr stringByReplacingOccurrencesOfString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=gb2312\">" withString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"];
        NSData *htmlDataUTF8 = [utf8HtmlStr dataUsingEncoding:NSUTF8StringEncoding];
        TFHpple *xpathParser = [[TFHpple alloc]initWithHTMLData:htmlDataUTF8];
//        NSArray *elements  = [xpathParser searchWithXPathQuery:@"//table[@id='Table1']/tr/td/child::text()"];

        NSArray *trNodesElements = [xpathParser searchWithXPathQuery:@"//table[@id='Table1']/tr"];
        for (TFHppleElement *trNode in trNodesElements) {
            NSArray *tdNodesElements = [trNode searchWithXPathQuery:@"//td"];
            BOOL isGetRowSpan = NO;//“第x节”文本之后的才是课程信息
            int sectionStartNumber = 0;//第几节开始，这个要做处理
            int weekDayNumber = 0;//星期几，这个不用处理，从0开始表示星期一
            for (TFHppleElement *tdNode in tdNodesElements) {
                if (isGetRowSpan) {
                    NSString *rowSpan = tdNode.attributes[@"rowspan"];
                    if (rowSpan == nil) {
                        weekDayNumber++;
                        continue;
                    }
                    NSLog(@"%@",rowSpan);
                    NSMutableArray *textcache = [NSMutableArray array];//文本数组
                    NSArray *textElements = [tdNode searchWithXPathQuery:@"//child::text()"];
                    NSMutableArray *weekIndexs = [NSMutableArray array];//把含有{}的文本（周数时间文本）的位置存储起来
                    for (int i = 0 ;i < textElements.count ;i++) {
                        NSLog(@"%@",[textElements[i] content]);
                        //把所有文本都存储起来
                        [textcache addObject:[textElements[i] content]];
                        //把含有{}的文本（周数时间文本）的位置存储起来
                        if ([[textElements[i] content] rangeOfString:@"{"].location != NSNotFound &&[[textElements[i] content] rangeOfString:@"}"].location != NSNotFound) {
                            [weekIndexs addObject:[NSString stringWithFormat:@"%@",[NSNumber numberWithInt:i]]];
                        }
                    }
                    
//------------------------补全文本（课程名称、周数必有，上课地点不一定有，教师名字不清楚是不是必有，假设可能没有），从后往前补全
                    //先补最后一个
                    int theLastIndex = [[weekIndexs lastObject]intValue];
                    int deltaLastOne = (int)(textcache.count - theLastIndex - 1);
                    for (int i = 0; i < 2-deltaLastOne; i++) {
                        [textcache addObject:@""];
//                        [textcache insertObject:@"" atIndex:textcache.count+i];
                    }
                    //从后往前补
                    if (weekIndexs.count > 1) {
                        for (int i = (int)weekIndexs.count-2; i >= 0; i--) {
                            int thePeriorIndex = [weekIndexs[i] intValue];
                            int delta = theLastIndex - thePeriorIndex;
                            for (int j = 0; j < 4-delta; j++) {
                                [textcache insertObject:@"" atIndex:theLastIndex-1+j];
                            }
                            theLastIndex = thePeriorIndex;
                        }
                    }
                    
                    //已经补全文本，4个一组表示一项课程，一次为课程名、周数、教师、地点
//-------------------------处理周数
                    int specialMark = 0;//单周、双周或其他
                    NSString *week = [NSString string];//周数：“n-m”
                    int startWeek = 0;//开始周
                    int endWeek = 0;//结束周
//                    NSArray *startWeekAndEndWeek = [NSArray array];//开始周和结束周
                    for (int i = 1; i < textcache.count - 1;i+=4) {
                        //截取{}内的周数信息
                        NSString * tempString = [[textcache[i] componentsSeparatedByString:@"{"]lastObject];
                        NSString *weekMessageStr = [[tempString componentsSeparatedByString:@"}"]firstObject];
                        if ([weekMessageStr rangeOfString:@"|"].location != NSNotFound) {//有单双周信息
                            NSArray *weekMessageArray = [weekMessageStr componentsSeparatedByString:@"|"];
                            if([[weekMessageArray lastObject]rangeOfString:@"单周"].location != NSNotFound){
                                specialMark = 1;
                            }else if ([[weekMessageArray lastObject]rangeOfString:@"双周"].location != NSNotFound){
                                specialMark = 2;
                            }
                            week = [[weekMessageArray firstObject]substringWithRange:NSMakeRange(1, [[weekMessageArray firstObject]length] - 2)];
                        }else{//没有单双周信息
                            specialMark = 0;
                            week = [weekMessageStr substringWithRange:NSMakeRange(1, weekMessageStr.length - 2)];
                        }
                        startWeek = [[[week componentsSeparatedByString:@"-"]firstObject]intValue];
                        endWeek = [[[week componentsSeparatedByString:@"-"]lastObject]intValue];
                        //拼接周数字符串，把每周枚举出来，用逗号分割
                        NSMutableString *str = [[NSMutableString alloc] initWithCapacity:2];
                        [str appendString:@","];
                        if (specialMark == 1||specialMark == 2) {
                            for (int j = 0; startWeek+j <= endWeek; j+=2) {
                                [str appendFormat:@"%@,",[NSNumber numberWithInt:startWeek+j]];
                            }
                        }else{
                            for (int j = 0; startWeek+j <= endWeek; j++) {
                                [str appendFormat:@"%@,",[NSNumber numberWithInt:startWeek+j]];
                            }
                        }
                        //用拼接后的周数字符串替换原来的周数信息
                        [textcache replaceObjectAtIndex:i withObject:str];
                    }
                    NSLog(@"%@",textcache);
                    
//-------------------------拼接节数字符串
                    NSMutableString *timeStr = [[NSMutableString alloc] initWithCapacity:2];
                    [timeStr appendString:@","];
                    if (sectionStartNumber > 4) {//后移一位，因为第四第五节中间有个"午间"
                        sectionStartNumber++;
                    }
                    for (int j = 0; j < rowSpan.intValue; j++) {
                        [timeStr appendFormat:@"%@,",[NSNumber numberWithInt:sectionStartNumber+j]];
                    }
                    
                    for (int i = 0; i < textcache.count;i+=4) {
                        NSString *sql = [NSString stringWithFormat:@"INSERT INTO course_table (courseName,weeks,weekday,time,place) VALUES ('%@','%@','%@','%@','%@');",textcache[i],textcache[i+1],[NSNumber numberWithInt:weekDayNumber],timeStr,textcache[i+3]];
                        [self.dbManager executeNonQuery:sql];
                    }
                    
                    weekDayNumber ++;
                }
                if ([tdNode.text hasPrefix:@"第"]&&[tdNode.text hasSuffix:@"节"]) {
                    isGetRowSpan = YES;
                    sectionStartNumber = [[tdNode.text substringWithRange:NSMakeRange(1, tdNode.text.length-2)]intValue];
                }
            }
        }
        self.httpData = nil;//清空数据
    }
}

- (NSURLSession *)session{
    static NSURLSession *shareSession = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];//如果用emp模式得不到cookie
        configuration.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
        NSDictionary *additionalHeaders = [NSDictionary dictionaryWithObjectsAndKeys:@"text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",@"Accept",                                                      @"gzip, deflate, sdch",@"Accept-Encoding",
                                           @"zh-CN,zh;q=0.8",@"Accept-Language",
                                           @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.95 Safari/537.36",@"User-Agent",@"1",@"Upgrade-Insecure-Requests", nil];
        configuration.HTTPAdditionalHeaders = additionalHeaders;
        shareSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    });
    return shareSession;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler{
    NSMutableURLRequest *newrequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https:www.baidu.com"]];
    newrequest.HTTPMethod = @"GET";
    completionHandler(request);
    NSLog(@"%s,",__func__);
}

@end

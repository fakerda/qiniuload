//
//  QiniuLoad.m
//  Yomika
//
//  Created by Administrator on 2017/5/25.
//  Copyright © 2017年 tion_Z. All rights reserved.
//

#import "QiniuLoad.h"
#import <QiniuSDK.h>
#include <CommonCrypto/CommonCrypto.h>
#import <AFNetworking.h>
#import <QN_GTM_Base64.h>
#import "ZLPhotoAssets.h"
#import <QNEtag.h>
#import <QNConfiguration.h>



static NSString *accessKey = @"官网获取";
static NSString *secretKey = @"官网获取";

@interface QiniuLoad ()

@end

@implementation QiniuLoad

//获取token

+ (NSString *)makeToken:(NSString *)accessKey secretKey:(NSString *)secretKey{
    
    const char *secretKeyStr = [secretKey UTF8String];
    NSString *policy = [QiniuLoad marshal];
    NSData *policyData = [policy dataUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedPolicy = [QN_GTM_Base64 stringByWebSafeEncodingData:policyData padded:TRUE];
    const char *encodedPolicyStr = [encodedPolicy cStringUsingEncoding:NSUTF8StringEncoding];
    char digestStr[CC_SHA1_DIGEST_LENGTH];
    bzero(digestStr, 0);
    CCHmac(kCCHmacAlgSHA1, secretKeyStr, strlen(secretKeyStr), encodedPolicyStr, strlen(encodedPolicyStr), digestStr);
    NSString *encodedDigest = [QN_GTM_Base64 stringByWebSafeEncodingBytes:digestStr length:CC_SHA1_DIGEST_LENGTH padded:TRUE];
    NSString *token = [NSString stringWithFormat:@"%@:%@:%@",  accessKey, encodedDigest, encodedPolicy];
    
    return token;//得到了token
}

+ (NSString *)marshal{
    
    NSInteger _expire = 0;
    time_t deadline;
    time(&deadline);//返回当前系统时间
    //@property (nonatomic , assign) int expires; 怎么定义随你...
    deadline += (_expire > 0) ? _expire : 3600; // +3600秒,即默认token保存1小时.
    NSNumber *deadlineNumber = [NSNumber numberWithLongLong:deadline];
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    
    [dic setObject:@"修改成七牛存储空间的名字" forKey:@"scope"];//根据
    [dic setObject:deadlineNumber forKey:@"deadline"];
    NSString *json = [QiniuLoad convertToJsonData:dic ];
    
    return json;
}


-(void)download{
    
    NSString *path = @"自己查看一下文档，这里填你需要下载的文件的url";
    NSURLRequest *request =[NSURLRequest requestWithURL:[NSURL URLWithString:path] cachePolicy:1 timeoutInterval:15.0f];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        NSLog(@"response = %@",response);
        
        //得到了JSON文件 解析就好了。
        id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        
        NSLog(@"%@", result);
        
    }];
}

+(void)uploadImageToQNFilePath:(NSArray *)photos success:(QNSuccessBlock)success failure:(QNFailureBlock)failure{
    
    NSMutableArray *imageAry =[NSMutableArray new];
    NSMutableArray *imageAdd = [NSMutableArray new];
    for (ZLPhotoAssets *status in photos) {
        
        [imageAry addObject:[status aspectRatioImage]];
    }
    //主要是把图片或者文件转成nsdata类型就可以了
    QNConfiguration *config = [QNConfiguration build:^(QNConfigurationBuilder *builder) {
        builder.zone = [QNZone zone0];
    }];
    QNUploadManager *upManager = [[QNUploadManager alloc] initWithConfiguration:config];
    QNUploadOption *uploadOption = [[QNUploadOption alloc] initWithMime:nil
                                                        progressHandler:^(NSString *key, float percent) {
                                                            NSLog(@"上传进度 %.2f", percent);
                                                        }
                                                                 params:nil
                                                               checkCrc:NO
                                                     cancellationSignal:nil];
    
    [imageAry enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"%ld",idx);
        NSData *data;
        if (UIImagePNGRepresentation(obj) == nil){
            data = UIImageJPEGRepresentation(obj, 1);
        } else {
            data = UIImagePNGRepresentation(obj);
        }
        
        [upManager putData:data key:[QiniuLoad qnImageFilePatName] token:[QiniuLoad makeToken:accessKey secretKey:secretKey] complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
            NSLog(@"%@",resp[@"key"]);
            if (info.isOK) {
                
                [imageAdd addObject:[NSString stringWithFormat:@"%@%@",kQNinterface,resp[@"key"]]];
            }else{
                [imageAdd addObject:[NSString stringWithFormat:@"%ld",idx]];
                
            }
            if (imageAdd.count == imageAry.count) {
                if (success) {
                    success([imageAdd componentsJoinedByString:@";"]);
                }
            }
        } option:uploadOption];
        
        
        
    }];
    
}


+(void)uploadVideoToQNFilePath:(NSURL *)url success:(QNSuccessBlock)success failure:(QNFailureBlock)failure{
    
    NSMutableArray *imageAdd = [NSMutableArray new];
    NSMutableArray *errors = [NSMutableArray new];
    
    QNConfiguration *config = [QNConfiguration build:^(QNConfigurationBuilder *builder) {
        builder.zone = [QNZone zone0];
    }];
    QNUploadManager *upManager = [[QNUploadManager alloc] initWithConfiguration:config];
    QNUploadOption *uploadOption = [[QNUploadOption alloc] initWithMime:nil
                                                        progressHandler:^(NSString *key, float percent) {
                                                            NSLog(@"上传进度 %.2f", percent);
                                                        }
                                                                 params:nil
                                                               checkCrc:NO
                                                     cancellationSignal:nil];
    
    NSData *myVideoData = [NSData dataWithContentsOfURL:url];
    [upManager putData:myVideoData key:[QiniuLoad qnVideoFilePatName] token:[QiniuLoad makeToken:accessKey secretKey:secretKey] complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
        
        if (info.isOK) {
            [imageAdd addObject:[NSString stringWithFormat:@"%@%@",kQNinterface,resp[@"key"]]];
            //                NSLog(@"%@",imageAdd);
        }else{
            [errors addObject:[NSString stringWithFormat:@"%@", @1]];
        }
        if (imageAdd.count == 1) {
            if (success) {
                success([imageAdd componentsJoinedByString:@";"]);
            }
        }else{
            if (failure) {
                failure([errors componentsJoinedByString:@","]);
            }
        }
        
    } option:uploadOption];
    
}

+(void)uploadAmrToQNFilePath:(NSString *)url success:(QNSuccessBlock)success failure:(QNFailureBlock)failure{
    
    NSMutableArray *imageAdd = [NSMutableArray new];
    NSMutableArray *errors = [NSMutableArray new];
    
    QNConfiguration *config = [QNConfiguration build:^(QNConfigurationBuilder *builder) {
        builder.zone = [QNZone zone0];
    }];
    QNUploadManager *upManager = [[QNUploadManager alloc] initWithConfiguration:config];
    QNUploadOption *uploadOption = [[QNUploadOption alloc] initWithMime:nil
                                                        progressHandler:^(NSString *key, float percent) {
                                                            NSLog(@"上传进度 %.2f", percent);
                                                        }
                                                                 params:nil
                                                               checkCrc:NO
                                                     cancellationSignal:nil];
    
    NSData *data = [NSData dataWithContentsOfFile:url];
    
    [upManager putData:data key:[QiniuLoad qnAmrFilePatName] token:reslut[@"data"] complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
        
        if (info.isOK) {
            [imageAdd addObject:[NSString stringWithFormat:@"%@%@",kQNinterface,resp[@"key"]]];
            //                NSLog(@"%@",imageAdd);
        }else{
            [errors addObject:[NSString stringWithFormat:@"%@", @1]];
        }
        if (imageAdd.count == 1) {
            if (success) {
                success([imageAdd componentsJoinedByString:@";"]);
            }
        }else{
            
            if (failure) {
                failure([errors componentsJoinedByString:@","]);
            }
        }
    } option:uploadOption];
    
    
}

+ (NSString *)qnImageFilePatName{
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyyMMdd"];
    NSString *nowe = [formatter stringFromDate:[NSDate date]];
    NSString *number = [QiniuLoad generateTradeNO];
    //当前时间
    NSInteger interval = (NSInteger)[[NSDate date]timeIntervalSince1970];
    NSString *name = [NSString stringWithFormat:@"Picture/%@/%ld%@.jpg",now,interval,number];
    NSLog(@"name__%@",name);
    
    return name;
}

+ (NSString *)qnVideoFilePatName{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyyMMdd"];
    NSString *now = [formatter stringFromDate:[NSDate date]];
    NSString *number = [QiniuLoad generateTradeNO];
    //当前时间
    NSInteger interval = (NSInteger)[[NSDate date]timeIntervalSince1970];
    NSString *name = [NSString stringWithFormat:@"Video/%@/%ld%@.mp4",now,interval,number];
    //    NSString *name = [NSString stringWithFormat:@"Video/%ld%@%@.mp4",interval,number,now];
    
    NSLog(@"%@",name);
    
    return name;
}

+ (NSString *)qnAmrFilePatName{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyyMMdd"];
    NSString *now = [formatter stringFromDate:[NSDate date]];
    NSString *number = [QiniuLoad generateTradeNO];
    //当前时间
    NSInteger interval = (NSInteger)[[NSDate date]timeIntervalSince1970];
    NSString *name = [NSString stringWithFormat:@"Voice/%@/%ld%@.amr",now,interval,number];
    
    return name;
}

+(NSString *)convertToJsonData:(NSDictionary *)dict{
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString;
    if (!jsonData) {
        NSLog(@"%@",error);
    }else{
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    NSRange range = {0,jsonString.length};
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    NSRange range2 = {0,mutStr.length};
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    
    return mutStr;
}

+ (NSString *)generateTradeNO {
    
    static int kNumber = 8;
    NSString *sourceStr = @"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSMutableString *resultStr = [[NSMutableString alloc] init];
    srand((unsigned)time(0));
    for (int i = 0; i < kNumber; i++) {
        unsigned index = rand() % [sourceStr length];
        NSString *oneStr = [sourceStr substringWithRange:NSMakeRange(index, 1)];
        [resultStr appendString:oneStr];
    }
    NSLog(@"%@",resultStr);
    return resultStr;
    
}
@end

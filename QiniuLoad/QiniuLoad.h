//
//  QiniuLoad.h
//  Yomika
//
//  Created by Administrator on 2017/5/25.
//  Copyright © 2017年 tion_Z. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^QNSuccessBlock)(NSString *reslut);
typedef void(^QNFailureBlock)(NSString *error);
@interface QiniuLoad : NSObject

/*
    上传图片。
    photos 为ZLPhotoAssets数组
 */
+(void)uploadImageToQNFilePath:(NSArray *)photos success:(QNSuccessBlock)success failure:(QNFailureBlock)failure;

/*
    上传视频
 */
+(void)uploadVideoToQNFilePath:(NSURL *)url success:(QNSuccessBlock)success failure:(QNFailureBlock)failure;

/*
    上传音频
 */
+(void)uploadAmrToQNFilePath:(NSString *)url success:(QNSuccessBlock)success failure:(QNFailureBlock)failure;
@end

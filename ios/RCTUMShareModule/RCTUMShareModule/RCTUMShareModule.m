//
//  RCTUMShareModule.m
//  RCTUMShareModule
//
//  Created by zhangzy on 2017/3/12.
//  Copyright © 2017年 zzy. All rights reserved.
//

#import "RCTUMShareModule.h"
#import <UShareUI/UShareUI.h>

@implementation RCTUMShareModule {
    NSDictionary *_sharePlatforms;
}

RCT_EXPORT_MODULE();


RCT_REMAP_METHOD(share,
                 Title: (NSString *) title
                 Desc:(NSString *) desc
                 Thumb:(NSString *) thumb
                 Link:(NSString *) link
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
    
        if(_sharePlatforms == nil) {
            
            reject(@-1, @"请先在AppDelegate.m中初始化分享设置", nil);
            return;
        }
        // 设置顺序
        NSMutableArray *sort = [[NSMutableArray alloc] init];
    
        [_sharePlatforms enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if([key rangeOfString:@"weixin"].location != NSNotFound) {
                [sort addObject:@(UMSocialPlatformType_WechatSession)];
                [sort addObject:@(UMSocialPlatformType_WechatTimeLine)];
            } else if([key rangeOfString:@"qq"].location != NSNotFound) {
                [sort addObject:@(UMSocialPlatformType_QQ)];
            } else if([key rangeOfString:@"sina"].location != NSNotFound) {
                [sort addObject:@(UMSocialPlatformType_Sina)];
            }
        }];
        
        [UMSocialUIManager setPreDefinePlatforms:sort];
        
        
        [UMSocialUIManager showShareMenuViewInWindowWithPlatformSelectionBlock:^(UMSocialPlatformType platformType, NSDictionary *userInfo) {
            
            //创建分享消息对象
            UMSocialMessageObject *messageObject = [UMSocialMessageObject messageObject];
            
            //创建网页内容对象
            NSString* thumbURL = thumb;
            UMShareWebpageObject *shareObject = [UMShareWebpageObject shareObjectWithTitle:title descr:desc thumImage:thumbURL];
            //设置网页地址
            shareObject.webpageUrl = link;
            
            //分享消息对象设置分享内容对象
            messageObject.shareObject = shareObject;
            
            
            //调用分享接口
            [[UMSocialManager defaultManager] shareToPlatform:platformType messageObject:messageObject currentViewController:nil completion:^(id data, NSError *error) {
                if (error) {
                    reject(@-1, @"分享失败", error);
                    UMSocialLogInfo(@"************Share fail with error %@*********",error);
                } else {
                    
                    resolve(data);
                }
            }];
            
        }];
        
    });
    
}

RCT_EXPORT_METHOD(initShare:(NSString *)umAppKey SharePlatforms:(NSDictionary *) sharePlatforms OpenLog:(BOOL)openLog)
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[UMSocialManager defaultManager] openLog:openLog];
        
        /* 设置友盟appkey */
        [[UMSocialManager defaultManager] setUmSocialAppkey:umAppKey];
        
        [sharePlatforms enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {

            if([key rangeOfString:@"weixin"].location != NSNotFound) {
                
                [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_WechatSession appKey:[obj objectForKey:@"appKey"] appSecret:[obj objectForKey:@"appSecret"] redirectURL:[obj objectForKey:@"redirectURL"]];
            } else if([key rangeOfString:@"qq"].location != NSNotFound) {
                [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_QQ appKey:[obj objectForKey:@"appKey"] appSecret:[obj objectForKey:@"appSecret"] redirectURL:[obj objectForKey:@"redirectURL"]];
            } else if([key rangeOfString:@"sina"].location != NSNotFound) {
                [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_Sina appKey:[obj objectForKey:@"appKey"] appSecret:[obj objectForKey:@"appSecret"] redirectURL:[obj objectForKey:@"redirectURL"]];
            }
        }];
        _sharePlatforms = sharePlatforms;
    });
    
}


RCT_REMAP_METHOD(login,
                 Platform:(NSString *)platform
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UMSocialPlatformType socialPlatformType = UMSocialPlatformType_QQ;
        if ([platform isEqualToString:@"weixin"]) {
            socialPlatformType = UMSocialPlatformType_WechatSession;
        }
        
        [[UMSocialManager defaultManager] getUserInfoWithPlatform:socialPlatformType currentViewController:nil completion:^(id result, NSError *error) {
            if (error) {
                reject(@-1, @"登录失败", error);
            } else {
                UMSocialUserInfoResponse *resp = result;
                
                NSDictionary *data = @{@"uid": resp.uid, @"openid": resp.openid, @"accessToken": resp.accessToken, @"expiration": resp.expiration, @"name": resp.name, @"iconurl": resp.iconurl, @"gender": resp.gender, @"originalResponse": resp.originalResponse};
                
                resolve(data);
            }
        }];
    });
}

@end
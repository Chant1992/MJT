//
//  FileOpenVC.m
//  MJT_APP
//
//  Created by Donny on 2017/9/11.
//  Copyright © 2017年 深圳奥联信息安全技术有限公司. All rights reserved.
//

#import "FileOpenVC.h"
#import <WebKit/WebKit.h>
#import "OLYMAESCrypt.h"
#import "VoiceConverter.h"
//#import <OGVKit/OGVKit.h>

@interface FileOpenVC () {
    UIWebView *uiWebview;
    WKWebView  *webview;
//    OGVPlayerView *playerView;
}

@property (nonatomic, strong) NSDictionary *mimeTypeDictionary;

@end

@implementation FileOpenVC

@synthesize urlPath;

- (void)viewDidLoad {
    [super viewDidLoad];
    
}


- (void)olym_addSubviews{
    //清楚缓存
    NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
    //// Date from
    NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
    //// Execute
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
        // Done
    }];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc]init];
    config.mediaTypesRequiringUserActionForPlayback = NO;
    
    webview = [[WKWebView alloc]initWithFrame:self.view.bounds configuration:config];
    [self.view addSubview:webview];
    WeakSelf(weakSelf);
    [webview mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.edges.mas_equalTo(weakSelf.view.safeAreaInsets);
        }else{
            make.edges.mas_equalTo(weakSelf.view);
        }
    }];
    
    uiWebview = [[UIWebView alloc]initWithFrame:self.view.bounds];
    uiWebview.scalesPageToFit = YES;
    [self.view addSubview:uiWebview];
    [uiWebview mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11, *)) {
            make.edges.mas_equalTo(weakSelf.view.safeAreaInsets);
        }else{
            make.edges.mas_equalTo(weakSelf.view);
        }
    }];
    uiWebview.hidden = YES;
    
}

- (void)olym_bindViewModel{
    
    /*
    @weakify(self);
    
    if (self.isFileAESEncrypt)
    {
        BOOL showOld = NO;
        NSString *fileExtension = [[urlPath componentsSeparatedByString:@"."]lastObject];
        
        //office文档用WKWebView打开乱码，UIWebview正常
        if ([fileExtension hasPrefix:@"doc"] || [fileExtension hasPrefix:@"ppt"] || [fileExtension hasPrefix:@"xls"] || [fileExtension hasPrefix:@"pages"]|| [fileExtension hasPrefix:@"numbers"] || [fileExtension isEqualToString:@"key"]) {
            webview.hidden = YES;
            uiWebview.hidden = NO;
            showOld = YES;
        }
        NSString *mimeType = [self.mimeTypeDictionary objectForKey:fileExtension];
        if (!mimeType) {
            mimeType = @"text/plain";
        }
        NSData *data = [OLYMAESCrypt decryptFile:urlPath];

        
        if (showOld)
        {
            [uiWebview loadData:data MIMEType:mimeType textEncodingName:@"UTF-8" baseURL:[[NSURL alloc]init]];
        }else
        {
            if ([fileExtension isEqualToString:@"txt"])
            {
                NSString *body = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                if (!body) {
                    //gbk
                    body = [[NSString alloc]initWithData:data encoding:0x80000632];
                }
                if (!body) {
                    //GB18030
                    body = [[NSString alloc]initWithData:data encoding:0x80000631];
                }
                NSString *html = [NSString stringWithFormat:@"<html><body><pre style=\"word-wrap: break-word; white-space: pre-wrap;\">%@</pre></body></html>",body];
                [webview loadHTMLString:html baseURL:nil];
            }else if ([fileExtension isEqualToString:@"amr"]||[fileExtension isEqualToString:@"wav"]||[fileExtension isEqualToString:@"m4a"])
            {
                if ([fileExtension isEqualToString:@"amr"])
                {
                    fileExtension = @"wav";
                    NSData *wavData = [VoiceConverter amrDataToWav:data];
                    data = wavData;
                }
                NSString *base64Str = [data base64EncodedStringWithOptions:0];
                if (![base64Str hasPrefix:@"data:audio"]) {
                    base64Str = [NSString stringWithFormat:@"data:audio/%@;base64,%@",fileExtension,base64Str];
                }
                NSString *body = @"<audio controls=\"controls\" autoplay=\"autoplay\" style=\"width:50%;height:70%;backgroundcolor:#000\" src=\"#@\"></audio>";
                body = [body stringByReplacingOccurrencesOfString:@"#@" withString:base64Str];
                NSString *html = [NSString stringWithFormat:@"<html><body>%@</body></html>",body];
                [webview loadHTMLString:html baseURL:nil];
            }
            else if([fileExtension isEqualToString:@"ogg"])
            {
                uiWebview.hidden = YES;
                webview.hidden = YES;
                playerView = [self createPlayerView];
                [self.view addSubview:playerView];
                WeakSelf(weakSelf);
                [playerView mas_makeConstraints:^(MASConstraintMaker *make) {
                    if (@available(iOS 11, *)) {
                        make.edges.mas_equalTo(weakSelf.view.safeAreaInsets);
                    }else{
                        make.edges.mas_equalTo(weakSelf.view);
                    }
                }];

                playerView.inputStream = [OGVInputStream inputStreamWithData:data];
                [playerView play];
            }
            else
            {
                [webview loadData:data MIMEType:mimeType characterEncodingName:@"UTF-8" baseURL:[[NSURL alloc]init]];
                }
        }
    }else
    {

        NSURL *url = [NSURL fileURLWithPath:urlPath];
        // 创建请求
        NSURLRequest *request = [NSURLRequest requestWithURL:url];

        // 通过url加载文件
        [webview loadFileURL:url allowingReadAccessToURL:url];
    }

     */
}

- (void)olym_layoutNavigation
{
    
}

- (void)closeViewController {
    
    [self.navigationController popViewControllerAnimated:YES];
}

//- (void)dealloc
//{
//    if(playerView)
//    {
//        [playerView pause];
//    }
//}

- (NSDictionary *)mimeTypeDictionary
{
    if (!_mimeTypeDictionary) {
        _mimeTypeDictionary = @{@"txt":@"text/plain",@"doc":@"application/msword",@"docx":@"application/vnd.openxmlformats-officedocument.wordprocessingml.document",@"pdf":@"application/pdf",@"ppt":@"application/vnd.ms-powerpoint",@"pptx":@"application/vnd.openxmlformats-officedocument.presentationml.presentation",@"xls":@"application/vnd.ms-excel",@"xlsx":@"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",@"log":@"text/plain",@"js":@"application/x-javascript",@"html":@"text/html",@"css":@"text/css",@"zip":@"application/zip",@"bmp":@"image/bmp",@"rtf":@"text/rtf",@"pages":@"application/x-iwork-pages-sffpages",@"key":@"application/x-iwork-keynote-sffkey",@"numbers":@"application/x-iwork-numbers-sffnumbers",@"jpg":@"image/jpeg",@"jpeg":@"image/jpeg",@"png":@"image/png",@"gif":@"image/gif",@"bmp":@"image/bmp"};
    }
    return _mimeTypeDictionary;
}


//- (OGVPlayerView *)createPlayerView
//{
//    OGVPlayerView *anPlayerView = [[OGVPlayerView alloc] initWithFrame:uiWebview.frame];
//    return anPlayerView;
//}


@end

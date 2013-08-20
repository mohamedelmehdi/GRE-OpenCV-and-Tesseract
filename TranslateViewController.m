//
//  TranslateViewController.m
//  GRE OpenCV
//
//  Created by BlueCocoa on 13-8-20.
//  Copyright (c) 2013年 Xu Ruomeng. All rights reserved.
//

#import "TranslateViewController.h"
#import <objc/runtime.h>
@interface TranslateViewController ()

@end

@implementation TranslateViewController
@synthesize translate;
@synthesize url;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)back:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *userAgent = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9) AppleWebKit/537.54.1 (KHTML, like Gecko) Version/7.0 Safari/537.54.1";
    id webDocumentView;
    id webView;
    webDocumentView = objc_msgSend((id)translate,@selector(_documentView));
    object_getInstanceVariable(webDocumentView, "_webView", (void**)&webView);
    objc_msgSend(webView, @selector(setCustomUserAgent:), userAgent);
    [translate loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.url]]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

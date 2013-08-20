//
//  TranslateViewController.h
//  GRE OpenCV
//
//  Created by BlueCocoa on 13-8-20.
//  Copyright (c) 2013年 Xu Ruomeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TranslateViewController : UIViewController{
}
@property (assign) NSString *url;
@property (strong, nonatomic) IBOutlet UIWebView *translate;
- (IBAction)back:(id)sender;
@end

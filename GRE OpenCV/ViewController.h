//
//  ViewController.h
//  GRE OpenCV
//
//  Created by BlueCocoa on 13-8-20.
//  Copyright (c) 2013年 Xu Ruomeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>
#import "GT_API.h"
using namespace cv;
@class UIProgressHUD;

namespace tesseract {
    class TessBaseAPI;
};
@interface ViewController : UIViewController<CvVideoCameraDelegate,UIAlertViewDelegate>{
    IBOutlet UIButton *scan;
    IBOutlet UIButton *stop;
    IBOutlet UIButton *boom;
    IBOutlet UIImageView *imageView;
    CvVideoCamera *videoCamera;
    cv::Mat myMat;
    uint32_t *pixels;
    NSInteger state;
    UIProgressHUD *myHUD;
    tesseract::TessBaseAPI *tesseract;
}
@property (nonatomic, strong) NSString *OCRresult;
@property (nonatomic, retain) CvVideoCamera *videoCamera;
@property (nonatomic, retain) UIProgressHUD *myHUD;
- (IBAction)doScan:(id)sender;
- (IBAction)doStop:(id)sender;
- (IBAction)doBoom:(id)sender;

@end

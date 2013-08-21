//
//  ViewController.m
//  GRE OpenCV
//
//  Created by BlueCocoa on 13-8-20.
//  Copyright (c) 2013年 Xu Ruomeng. All rights reserved.
//

#import "ViewController.h"
#import "TranslateViewController.h"
#include "baseapi.h"
#include "environ.h"
#import "pix.h"

@interface UIProgressHUD : NSObject
- (void) show: (BOOL) yesOrNo;
- (UIProgressHUD *) initWithWindow: (UIView *) window;
@end

@interface ViewController ()

@end

@implementation ViewController
@synthesize videoCamera = _videoCamera;
@synthesize myHUD = _myHUD;
@synthesize OCRresult;

- (NSString *)sqlQueryWithArray:(NSArray *)words{
    NSString *databasePath = [[NSBundle mainBundle] pathForResource:@"myDict" ofType:@"db"];
    NSMutableArray *explainArray = [[NSMutableArray alloc] init];
    int i = 0;
    NSMutableArray *wordsVaild = [[NSMutableArray alloc] init];
    NSStringEncoding enc =  CFStringConvertEncodingToNSStringEncoding (kCFStringEncodingUTF8);
    if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK)
    {
        sqlite3_stmt *statement;
        
        
        for (NSString *w in words){
            i++;
            if ([(NSString *)[words objectAtIndex:i-1] length] == 0) {
                continue;
            }
            [wordsVaild addObject:[words objectAtIndex:i-1]];
            if (sqlite3_prepare_v2(database, [[NSString stringWithFormat:@"SELECT explain from 'Words' where word='%@'",[words objectAtIndex:i-1]] UTF8String], -1, &statement, nil) == SQLITE_OK){
                while (sqlite3_step(statement) == SQLITE_ROW ){
                    NSString *query = [[NSString alloc] initWithCString:(char *)sqlite3_column_text(statement, 0) encoding:enc];
                    if([query length]>3){
                        [explainArray addObject:query];
                    }else{
                        [explainArray addObject:@"未找到"];
                    }
                }
            }else{
                [explainArray addObject:@"未找到"];
            }
        }
    }
    NSLog(@"%@",explainArray);
    NSString *explain = [[NSString alloc] init];
    for (int p = 0; p < [explainArray count]; p++) {
        explain = [explain stringByAppendingString:[wordsVaild objectAtIndex:p]];
        explain = [explain stringByAppendingFormat:@"\n%@\n\n",[explainArray objectAtIndex:p]];
    }
    return explain;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    state = 0;
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = YES;
    self.videoCamera.delegate = self;
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = ([documentPaths count] > 0) ? [documentPaths objectAtIndex:0] : nil;
    
    NSString *dataPath = [documentPath stringByAppendingPathComponent:@"tessdata"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:dataPath]) {
        NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
        NSString *tessdataPath = [bundlePath stringByAppendingPathComponent:@"tessdata"];
        if (tessdataPath) {
            [fileManager copyItemAtPath:tessdataPath toPath:dataPath error:NULL];
        }
    }
    setenv("TESSDATA_PREFIX", [[documentPath stringByAppendingString:@"/"] UTF8String], 1);
    tesseract = new tesseract::TessBaseAPI();
    tesseract->Init([dataPath cStringUsingEncoding:NSUTF8StringEncoding], "eng");
}

- (IBAction)doScan:(id)sender{
    if(state == 0){
        [self.videoCamera start];
        state = 1;
    }
}

- (IBAction)doStop:(id)sender{
    if (state == 1) {
        [self.videoCamera stop];
        state = 0;
    }
}

- (IBAction)doBoom:(id)sender{
    if (state == 1) {
        state = 0;
        UIImage *image;
        for (UIView *subView in [self.view subviews]) {
            if ([subView isKindOfClass:NSClassFromString(@"UIImageView")]) {
                if(UIGraphicsBeginImageContextWithOptions != NULL)
                {
                    UIGraphicsBeginImageContextWithOptions(subView.frame.size, NO, 0.0);
                } else {
                    UIGraphicsBeginImageContext(subView.frame.size);
                }
                [subView.layer renderInContext:UIGraphicsGetCurrentContext()];
                image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                [self doStop:nil];
            }
        }
        [imageView setImage:image];
        [self load:image];
    }
}

-(void)load:(UIImage*)image
{
    myHUD = [GT_API showProgressHUDWithText:@"OCR识别中..." View:self.view];
    [self processOcrAt:image];
}

- (void)processOcrAt:(UIImage *)image
{
    [self setTesseractImage:image];
    
    tesseract->Recognize(NULL);
    char* utf8Text = tesseract->GetUTF8Text();
    [self performSelectorOnMainThread:@selector(ocrProcessingFinished:)
                           withObject:[NSString stringWithUTF8String:utf8Text]
                        waitUntilDone:NO];
}

- (void)translateWithGoogle{
    NSArray *words = [self.OCRresult componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *s = @"http://translate.google.cn/#en/zh-CN/";
    BOOL is = NO;
    for(NSString *single in words){
        if (is == NO) {
            s = [s stringByAppendingFormat:@"%@",single];
            is = YES;
        }else{
            s = [s stringByAppendingFormat:@"%%0A%@",single];
        }
    }
    NSLog(@"%@",s);
    TranslateViewController *translate = [[TranslateViewController alloc] initWithNibName:@"TranslateViewController" bundle:nil];
    translate.url = s;
    [self presentViewController:translate animated:YES completion:^(void){
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        [self translateWithGoogle];
    }
}

- (NSString *)URLEncodedString:(NSString *)src
{
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)src, NULL,(CFStringRef)@"!*'();@&=+$,?[]",kCFStringEncodingUTF8));
    return result;
}

- (void)ocrProcessingFinished:(NSString *)result
{
    [myHUD show:NO];
    
    self.OCRresult = [NSString stringWithString:result];
    NSArray *words = [self.OCRresult componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSMutableArray *query = [[NSMutableArray alloc] init];
    for (NSString *w in words) {
        [w stringByReplacingOccurrencesOfString:@"'" withString:@""];
        [w stringByReplacingOccurrencesOfString:@";" withString:@""];
        [w stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        [w stringByReplacingOccurrencesOfString:@"." withString:@""];
        [w stringByReplacingOccurrencesOfString:@")" withString:@""];
        [w stringByReplacingOccurrencesOfString:@"(" withString:@""];
        [query addObject:w];
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Result" message:[NSString stringWithFormat:@"解析结果：\n%@", [self sqlQueryWithArray:query]] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Google Translate", nil];
    [alert setDelegate:self];
    [alert show];
}

- (void)setTesseractImage:(UIImage *)image
{
    free(pixels);
    
    CGSize size = [image size];
    int width = size.width;
    int height = size.height;
	
	if (width <= 0 || height <= 0)
		return;
	
    // the pixels will be painted to this array
    pixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
    // clear the pixels so any transparency is preserved
    memset(pixels, 0, width * height * sizeof(uint32_t));
	
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
    // create a context with RGBA pixels
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
	
    // paint the bitmap to our context which will fill in the pixels array
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
	
	// we're done with the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    tesseract->SetImage((const unsigned char *) pixels, width, height, sizeof(uint32_t), width * sizeof(uint32_t));
}


-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

- (UIImage *)convertToGrayscale:(UIImage*)img{
    
    CGSize size = [img size];
    
    int width = size.width;
    
    int height = size.height;
    
    // the pixels will be painted to this array
    
    uint32_t *pixels1 = (uint32_t *) malloc(width * height * sizeof(uint32_t));
    
    // clear the pixels so any transparency is preserved
    
    memset(pixels1, 0, width * height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create a context with RGBA pixels
    
    CGContextRef context = CGBitmapContextCreate(pixels1, width, height, 8, width * sizeof(uint32_t), colorSpace,
                                                 
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    
    // paint the bitmap to our context which will fill in the pixels array
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [img CGImage]);
    
    int tt = 1;
    
    CGFloat intensity;
    
    int bw;
    
    for(int y = 0; y < height; y++) {
        
        for(int x = 0; x < width; x++) {
            
            uint8_t *rgbaPixel = (uint8_t *) &pixels1[y * width + x];
            
            intensity = (rgbaPixel[tt] + rgbaPixel[tt + 1] + rgbaPixel[tt + 2]) / 3. / 255.;
            
            if (intensity > 0.45) {
                
                bw = 255;
                
            } else {
                
                bw = 0;
                
            }
            
            rgbaPixel[tt] = bw;
            
            rgbaPixel[tt + 1] = bw;
            
            rgbaPixel[tt + 2] = bw;
            
        }
        
    }
    
    // create a new CGImageRef from our context with the modified pixels
    
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    // we're done with the context, color space, and pixels
    
    CGContextRelease(context);
    
    CGColorSpaceRelease(colorSpace);
    
    free(pixels1);
    
    // make a new UIImage to return
    
    UIImage *resultUIImage = [UIImage imageWithCGImage:image];
    
    // we're done with image now too
    
    CGImageRelease(image);
    
    return resultUIImage;
}


#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
- (void)processImage:(Mat&)image;
{
    myMat = image;
}
#endif

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

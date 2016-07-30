//
//  PhotoVC.m
//  SDKSample
//
//  Created by Federico Lopez Cañas on 30/7/16.
//  Copyright © 2016 Parrot. All rights reserved.
//

#import "PhotoVC.h"
@import AVFoundation;
#import "QRScannerService.h"

@interface PhotoVC ()

@end

@implementation PhotoVC

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    session.sessionPreset = AVCaptureSessionPresetMedium;
    
    CALayer *viewLayer = self.photoImageView.layer;
    NSLog(@"viewLayer = %@", viewLayer);
    
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    
    captureVideoPreviewLayer.frame = self.photoImageView.bounds;
    [self.photoImageView.layer addSublayer:captureVideoPreviewLayer];
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!input) {
        // Handle the error appropriately.
        NSLog(@"ERROR: trying to open camera: %@", error);
    }
    [session addInput:input];
    
    [session startRunning];
    
    [self setTimer];
}

- (void)setTimer {
    [NSTimer scheduledTimerWithTimeInterval:0.5f
                                       target:self
                                     selector:@selector(takePicture)
                                     userInfo:nil
                                      repeats:YES];
}

- (void)takePicture {
    QRScannerService * scanner = [[QRScannerService alloc] init];
    UIImage * image = self.photoImageView.image;
    if (image) {
        [scanner scanAction:image];
    }
}

@end

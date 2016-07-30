//
//  QRScannerService.m
//  SDKSample
//
//  Created by Pablo Giorgi on 7/30/16.
//  Copyright © 2016 Parrot. All rights reserved.
//

#import "QRScannerService.h"
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import "ZXLuminanceSource.h"
#import "ZXCGImageLuminanceSource.h"
#import "ZXBinaryBitmap.h"
#import "ZXHybridBinarizer.h"
#import "ZXDecodeHints.h"
#import "ZXMultiFormatReader.h"
#import "ZXResult.h"
#import "ZXBarcodeFormat.h"

@implementation QRScannerService

- (DroneCommand)scanAction:(UIImage *)image {
    CGImageRef imageToDecode = image.CGImage;  // Given a CGImage in which we are looking for barcodes
    
    ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:imageToDecode];
    ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
    
    NSError *error = nil;
    
    // There are a number of hints we can give to the reader, including
    // possible formats, allowed lengths, and the string encoding.
    ZXDecodeHints *hints = [ZXDecodeHints hints];
    [hints addPossibleFormat:kBarcodeFormatQRCode];
    
    ZXMultiFormatReader *reader = [ZXMultiFormatReader reader];
    ZXResult *result = [reader decode:bitmap hints:hints error:&error];
    
    if (result == nil) {
        return Unknown;
    }
    
    // The coded result as a string. The raw data can be accessed with
    // result.rawBytes and result.length.
    NSString *contents = result.text;
    
    if ([contents isEqualToString:@"F1"]) {
        return Forward;
    }
    if ([contents isEqualToString:@"F2"]) {
        return Backward;
    }
    if ([contents isEqualToString:@"Diamond1"]) {
        return TurnLeft;
    }
    if ([contents isEqualToString:@"Diamond2"]) {
        return TurnRight;
    }
    return Unknown;
}

@end

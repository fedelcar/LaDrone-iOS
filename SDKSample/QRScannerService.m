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
    [hints addPossibleFormat:kBarcodeFormatAztec];
    [hints addPossibleFormat:kBarcodeFormatCodabar];
    [hints addPossibleFormat:kBarcodeFormatCode39];
    [hints addPossibleFormat:kBarcodeFormatCode93];
    [hints addPossibleFormat:kBarcodeFormatCode128];
    [hints addPossibleFormat:kBarcodeFormatDataMatrix];
    [hints addPossibleFormat:kBarcodeFormatEan8];
    [hints addPossibleFormat:kBarcodeFormatEan13];
    [hints addPossibleFormat:kBarcodeFormatITF];
    [hints addPossibleFormat:kBarcodeFormatMaxiCode];
    [hints addPossibleFormat:kBarcodeFormatPDF417];
    [hints addPossibleFormat:kBarcodeFormatQRCode];
    [hints addPossibleFormat:kBarcodeFormatRSS14];
    [hints addPossibleFormat:kBarcodeFormatRSSExpanded];
    [hints addPossibleFormat:kBarcodeFormatUPCA];
    [hints addPossibleFormat:kBarcodeFormatUPCE];
    [hints addPossibleFormat:kBarcodeFormatUPCEANExtension];
    
    ZXMultiFormatReader *reader = [ZXMultiFormatReader reader];
    ZXResult *result = [reader decode:bitmap hints:hints error:&error];
    
    if (result == nil) {
        return Unknown;
    }
    
    // The coded result as a string. The raw data can be accessed with
    // result.rawBytes and result.length.
    NSString *contents = result.text;
    
    if ([contents isEqualToString:@"forward"] || [contents isEqualToString:@"foward"] || [contents isEqualToString:@"fowad"]) {
        return Forward;
    }
    if ([contents isEqualToString:@"left"]) {
        return TurnLeft;
    }
    if ([contents isEqualToString:@"right"]) {
        return TurnRight;
    }
    if ([contents isEqualToString:@"fire"]) {
        return Fire;
    }
    if ([contents isEqualToString:@"repeat_4"]) {
        return Repeat4;
    }
    if ([contents isEqualToString:@"function_1"]) {
        return Repeat4;
    }

    return Unknown;
}

@end

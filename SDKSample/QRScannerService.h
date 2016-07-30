//
//  QRScannerService.h
//  SDKSample
//
//  Created by Pablo Giorgi on 7/30/16.
//  Copyright © 2016 Parrot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
    TurnLeft,
    TurnRight,
    Forward,
    Backward,
    Unknown
} DroneCommand;

@interface QRScannerService : NSObject

- (DroneCommand)scanAction:(UIImage *)image;

@end

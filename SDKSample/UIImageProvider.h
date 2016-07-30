//
//  UIImageProvider.h
//  SDKSample
//
//  Created by Pablo Giorgi on 7/30/16.
//  Copyright © 2016 Parrot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "QRScannerService.h"

@interface UIImageProvider : NSObject

+ (UIImage *)imageForCommand:(DroneCommand)command;

@end

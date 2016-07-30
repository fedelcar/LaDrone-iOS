//
//  UIImageProvider.m
//  SDKSample
//
//  Created by Pablo Giorgi on 7/30/16.
//  Copyright © 2016 Parrot. All rights reserved.
//

#import "UIImageProvider.h"

@implementation UIImageProvider

+ (UIImage *)imageForCommand:(DroneCommand)command {
    switch (command) {
        case TurnLeft: return [UIImage imageNamed:@"CommandLeft"];
        case TurnRight: return [UIImage imageNamed:@"CommandRight"];
        case Forward: return [UIImage imageNamed:@"CommandForward"];
        case Fire: return [UIImage imageNamed:@"CommandFire"];
        case Repeat4: return [UIImage imageNamed:@"CommandRepeat4"];
        case Function1: return [UIImage imageNamed:@"CommandFunction1"];
        default: return nil;
    }
}

@end

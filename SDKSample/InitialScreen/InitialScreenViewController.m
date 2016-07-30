//
//  InitialScreenViewController.m
//  SDKSample
//
//  Created by Pablo Giorgi on 7/30/16.
//  Copyright © 2016 Parrot. All rights reserved.
//

#import "InitialScreenViewController.h"

@interface InitialScreenViewController ()

@end

@implementation InitialScreenViewController

- (IBAction)startGamePressed:(id)sender {
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UIViewController * viewController = [storyboard instantiateInitialViewController];
    [self presentViewController:viewController animated:YES completion:nil];
}

@end

//
//  InitialScreenViewController.m
//  SDKSample
//
//  Created by Pablo Giorgi on 7/30/16.
//  Copyright © 2016 Parrot. All rights reserved.
//

#import "InitialScreenViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface InitialScreenViewController ()

@property (nonatomic, weak) IBOutlet UIButton * button;

@end

@implementation InitialScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self.button layer] setBorderColor:[UIColor whiteColor].CGColor];
}

- (IBAction)startGamePressed:(id)sender {
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UIViewController * viewController = [storyboard instantiateInitialViewController];
    [self presentViewController:viewController animated:YES completion:nil];
}

@end

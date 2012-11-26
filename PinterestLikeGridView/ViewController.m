//
//  ViewController.m
//  PinterestLikeGridView
//
//  Created by Weilong Song on 11/23/12.
//  Copyright (c) 2012 Weilong Song. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    UIScrollView *PLGV = [[PLGView alloc] initWithConfig:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
                                                 columns:3
                                             columnSpace:0
                                                    data:nil];
    [self.view addSubview:PLGV];
    NSLog(@"w%f, h%f", self.view.frame.size.width, self.view.frame.size.height);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate
{
    return YES;
}

@end

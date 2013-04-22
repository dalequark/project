//
//  SuccessViewController.m
//  taskyhttpdev
//
//  Created by Farhan Abrol on 4/21/13.
//  Copyright (c) 2013 Terrace F. Computer Scientists. All rights reserved.
//

#import "SuccessViewController.h"
#import "deviceSelector.h"
#import "LandingViewController.h"

@interface SuccessViewController ()
@property (nonatomic, strong) deviceSelector *dS;

@end

@implementation SuccessViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// set up the sensortag chooser
    UIViewController *parent = [[LandingViewController alloc]init];
    UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
    deviceSelector *dS = [[deviceSelector alloc]initWithStyle:UITableViewStyleGrouped];
    UINavigationController *rC = [[UINavigationController alloc]initWithRootViewController:parent];
    [rC pushViewController:dS animated:YES];
    mainWindow.rootViewController = rC;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

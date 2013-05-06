//
//  SensorSetupViewController.m
//  taskyhttpdev
//
//  Created by Raymond on 5/1/13.
//  Copyright (c) 2013 Terrace F. Computer Scientists. All rights reserved.
//

#import "SensorSetupViewController.h"
#import "WalkthroughLandingViewController.h"
#import "AbstractActionSheetPicker.h"
#import "ActionSheetDatePicker.h"
#import "deviceSelector.h"
#import "NSDate+TCUtils.h"

@interface SensorSetupViewController ()
- (void)dateWasSelected:(NSDate *)selectedDate element:(id)element;
@end

@implementation SensorSetupViewController

@synthesize setupDevice = _setupDevice;
@synthesize nameTextField = _nameTextField;
@synthesize sensorSegmentedControl = _sensorSegmentedControl;
@synthesize intervalSegmentedControl = _intervalSegmentedControl;
@synthesize dateTextField = _dateTextField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dateWasSelected:(NSDate *)selectedDate element:(id)element {
    self.selectedDate = selectedDate;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit)
                                               fromDate:self.selectedDate];
    NSInteger hour = [components hour];
    NSInteger minute = [components minute];

    //may have originated from textField or barButtonItem, use an IBOutlet instead of element
    self.dateTextField.text = [NSString stringWithFormat: @"%d:%02d %@",
                               ((hour + 11) % 12) + 1, minute, ((hour < 12) ? @"AM" : @"PM")];
}

- (IBAction)dateButtonTapped:(UIBarButtonItem *)sender {
    [self selectADate:sender];
}

- (IBAction)doneButtonTapped:(UIButton *)sender {
    // TODO: check self.nameTextField.text and self.dateTextField.text for validity
    
    NSString *sensor;
    if (self.sensorSegmentedControl.selectedSegmentIndex == 0) {
        sensor = @"accel";
    } else if (self.sensorSegmentedControl.selectedSegmentIndex == 1) {
        sensor = @"gyro";
    } else if (self.sensorSegmentedControl.selectedSegmentIndex == 2) {
        sensor = @"magneto";
    } else {
        sensor = @"unknown";
    }
    
    NSString *phone = @"15102702170"; // TODO
    
    NSString *baseURL = @"http://cstedman.mycpanel.princeton.edu/hci/backend.php/";
    NSString *urlString =
    [NSString stringWithFormat:@"%@?action=connect&uuid=%@&task=%@&phone=%@&interval=%@&time=%@&sensor=%@",
     baseURL,
     CFUUIDCreateString(nil,self.setupDevice.p.UUID),
     [self.nameTextField.text stringByReplacingOccurrencesOfString:@" " withString:@"+"],
     phone, // TODO format phone
     @"1", // TODO pass the actual interval (self.intervalSegmentedControl.selectedSegmentIndex)
     @"1", //self.dateTextField.text, // TODO format reminder time as secs from start of day
     sensor];
    NSLog(@"%@", urlString);
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFJSONRequestOperation *operation =
    [AFJSONRequestOperation
     JSONRequestOperationWithRequest:request
     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
         if ([@"success" isEqualToString:[JSON valueForKeyPath:@"status"]]){
             // TODO respond to success
         } else {
             // TODO respond to failure
         }
         NSLog(@"%@: %@", [JSON valueForKeyPath:@"status"], [JSON valueForKeyPath:@"message"]);
     }
     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
         // TODO respond to failure
         NSLog(@"Server error %d: %@", [response statusCode], JSON == NULL ? [error userInfo] : JSON);
     }];
    [operation start];
    
	// set up the sensortag chooser
    UIViewController *parent = [[WalkthroughLandingViewController alloc]init];
    UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
    deviceSelector *dS = [[deviceSelector alloc]initWithStyle:UITableViewStyleGrouped];
    UINavigationController *rC = [[UINavigationController alloc]initWithRootViewController:parent];
    [rC pushViewController:dS animated:YES];
    mainWindow.rootViewController = rC;
}

- (IBAction)selectADate:(UIControl *)sender {
    _actionSheetPicker = [[ActionSheetDatePicker alloc] initWithTitle:@"" datePickerMode:UIDatePickerModeTime selectedDate:self.selectedDate target:self action:@selector(dateWasSelected:element:) origin:sender];
    self.actionSheetPicker.hideCancel = YES;
    [self.actionSheetPicker showActionSheetPicker];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.nameTextField) {
        [textField resignFirstResponder];
    }
    return NO;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.nameTextField isFirstResponder] && [touch view] != self.nameTextField) {
        [self.nameTextField resignFirstResponder];
    }
    if ([self.dateTextField isFirstResponder] && [touch view] != self.dateTextField) {
        [self.dateTextField resignFirstResponder];
    }
    [super touchesBegan:touches withEvent:event];
}

- (void)viewDidUnload {
    self.actionSheetPicker = nil;
    self.dateTextField = nil;
    
    [super viewDidUnload];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.selectedDate = [NSDate date];
    self.nameTextField.delegate = (id<UITextFieldDelegate>)self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

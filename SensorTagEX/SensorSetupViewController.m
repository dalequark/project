//
//  SensorSetupViewController.m
//  taskyhttpdev
//
//  Created by Raymond on 5/1/13.
//  Copyright (c) 2013 Terrace F. Computer Scientists. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
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
@synthesize reminderTimeMin = _reminderTimeMin;
@synthesize reminderTimeHr = _reminderTimeHr;

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
    self.reminderTimeHr = hour;
    self.reminderTimeMin = minute;
}

- (IBAction)dateButtonTapped:(UIBarButtonItem *)sender {
    [self selectADate:sender];
}

- (IBAction)doneButtonTapped:(UIButton *)sender {

    // TODO: fix changing of background colors upon validation failure
    UIColor *validationFailedColor = [UIColor colorWithRed:255.0 green:252.0 blue:227.0 alpha:1.0];
    if ([self.nameTextField.text isEqualToString:@""]) {
        [self.nameTextField setBackgroundColor:validationFailedColor];
        self.nameTextField.layer.cornerRadius=8.0f;
        self.nameTextField.layer.masksToBounds=YES;
    }
    if ([self.dateTextField.text isEqualToString:@""]) {
        [self.dateTextField setBackgroundColor:validationFailedColor];
        self.dateTextField.layer.cornerRadius=8.0f;
        self.dateTextField.layer.masksToBounds=YES;
    }
    if ([self.nameTextField.text isEqualToString:@""] ||
        [self.dateTextField.text isEqualToString:@""]) {
        return;
    }
    
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
    
    // format reminderInterval as days (int)
    NSInteger reminderInterval;
    if (self.intervalSegmentedControl.selectedSegmentIndex == 0)
        reminderInterval = 1;
    else if (self.intervalSegmentedControl.selectedSegmentIndex == 1)
        reminderInterval = 2;
    else if (self.intervalSegmentedControl.selectedSegmentIndex == 2)
        reminderInterval = 3;
    else if (self.intervalSegmentedControl.selectedSegmentIndex == 3)
        reminderInterval = 4;
    else if (self.intervalSegmentedControl.selectedSegmentIndex == 4)
        reminderInterval = 5;
    else if (self.intervalSegmentedControl.selectedSegmentIndex == 5)
        reminderInterval = 6;
    else if (self.intervalSegmentedControl.selectedSegmentIndex == 6)
        reminderInterval = 7;
    else if (self.intervalSegmentedControl.selectedSegmentIndex == 7)
        reminderInterval = 14;
    else
        reminderInterval = 1;
    
    // format reminderTime as seconds from start of day (int)
    NSInteger reminderTime;
    reminderTime = self.reminderTimeHr * 3600 + self.reminderTimeMin * 60;

    // assemble all URL parameters
    NSString *baseURL = @"http://cstedman.mycpanel.princeton.edu/hci/backend.php/";
    NSString *urlString =
    [NSString stringWithFormat:@"%@?action=connect&uuid=%@&task=%@&phone=%@&interval=%d&time=%d&sensor=%@",
     baseURL, CFUUIDCreateString(nil,self.setupDevice.p.UUID),
     [self.nameTextField.text stringByReplacingOccurrencesOfString:@" " withString:@"+"],
     phone, reminderInterval, reminderTime, sensor];
    
    // send the request
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFJSONRequestOperation *operation =
    [AFJSONRequestOperation
     JSONRequestOperationWithRequest:request
     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
         if ([@"success" isEqualToString:[JSON valueForKeyPath:@"status"]]){
             [self finishSetup];
         } else {
             // TODO display error on failure
         }
         NSLog(@"%@: %@", [JSON valueForKeyPath:@"status"], [JSON valueForKeyPath:@"message"]);
     }
     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
         // TODO display error on failure
         NSLog(@"Server error %d: %@", [response statusCode], JSON == NULL ? [error userInfo] : JSON);
     }];
    [operation start];
}

-(IBAction)cancelSetupPressed {
    [self finishSetup];
}

-(void)finishSetup {
    // go back to chooser
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

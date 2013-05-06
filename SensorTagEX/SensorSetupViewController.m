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
    NSLog(@"name: %@", self.nameTextField.text);
    NSLog(@"sensor: %d", self.sensorSegmentedControl.selectedSegmentIndex);
    NSLog(@"interval: %d", self.intervalSegmentedControl.selectedSegmentIndex);
    NSLog(@"time: %@", self.dateTextField.text);
    
    /*
    // TODO: initialize the BLEDevice earlier, so that we connect as soon as the device is available
    SensorTagApplicationViewController *sensorVC =
    [[SensorTagApplicationViewController alloc]
     initWithStyle:UITableViewStyleGrouped andSensorTag:self.setupDevice];
    //[self.navigationController pushViewController:sensorVC animated:YES];
    [self presentViewController:sensorVC animated:YES completion:NULL];
    */
    
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

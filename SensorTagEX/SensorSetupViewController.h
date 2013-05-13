//
//  SensorSetupViewController.h
//  taskyhttpdev
//
//  Created by Raymond on 5/1/13.
//  Copyright (c) 2013 Terrace F. Computer Scientists. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEDevice.h"
#import "AbstractActionSheetPicker.h"
#import "ActionSheetDatePicker.h"

@interface SensorSetupViewController : UIViewController

    @property (nonatomic, strong) IBOutlet UITextField *nameTextField;
    @property (nonatomic, strong) IBOutlet UISegmentedControl *sensorSegmentedControl;
    @property (nonatomic, strong) IBOutlet UISegmentedControl *intervalSegmentedControl;
    @property (nonatomic, strong) IBOutlet UITextField *dateTextField;

    @property (nonatomic) int reminderTimeMin;
    @property (nonatomic) int reminderTimeHr;
    @property (nonatomic) NSDate *selectedDate;
    @property (nonatomic, strong) AbstractActionSheetPicker *actionSheetPicker;
    @property (nonatomic, strong) BLEDevice* setupDevice;

- (IBAction)selectADate:(id)sender;
- (IBAction)dateButtonTapped:(UIBarButtonItem *)sender;

@end

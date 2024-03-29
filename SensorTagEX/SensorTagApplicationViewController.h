/*
 *  SensorTagApplicationViewController.h
 *
 * Created by Ole Andreas Torvmark on 10/2/12.
 * Copyright (c) 2012 Texas Instruments Incorporated - http://www.ti.com/
 * ALL RIGHTS RESERVED
 */

#import <UIKit/UIKit.h>
#import "BLEDevice.h"
#import "BLEUtility.h"
#import "deviceCellTemplate.h"
#import "Sensors.h"
#import "AFJSONRequestOperation.h"
#import <MessageUI/MessageUI.h>

#define MIN_ALPHA_FADE 0.2f
#define ALPHA_FADE_STEP 0.05f

#define ACCELCHANGECUTTOFF 0.8f
#define GYROCHANGECUTOFF 60.0f

@interface SensorTagApplicationViewController : UITableViewController <CBCentralManagerDelegate,CBPeripheralDelegate,MFMailComposeViewControllerDelegate>

@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@property (strong, nonatomic) BLEDevice *d;
@property NSMutableArray *sensorsEnabled;

@property (strong, nonatomic) UITableViewCell *display;
@property (strong, nonatomic) UITableViewCell *status;
@property (strong, nonatomic) UITableViewCell *history;
@property (strong, nonatomic) accelerometerCellTemplate *acc;
@property (strong, nonatomic) accelerometerCellTemplate *mag;
@property (strong, nonatomic) accelerometerCellTemplate *gyro;
@property (strong, nonatomic) sensorMAG3110 *magSensor;
@property (strong, nonatomic) sensorIMU3000 *gyroSensor;

@property (strong, nonatomic) NSString *taskSensorName;
@property (strong, nonatomic) NSString *taskIntervalLen;
@property (strong, nonatomic) NSString *taskReminderTime;

@property (strong, nonatomic) sensorTagValues *currentVal;
@property (strong, nonatomic) NSMutableArray *vals;
@property (strong, nonatomic) NSTimer *logTimer;
@property (nonatomic) NSInteger triggered;
@property (nonatomic) NSInteger resetting;

@property float logInterval;

-(id) initWithStyle:(UITableViewStyle)style andSensorTag:(BLEDevice *)andSensorTag;

-(void) configureSensorTag;
-(void) deconfigureSensorTag;

- (IBAction) handleCalibrateMag;
- (IBAction) handleCalibrateGyro;

-(void) logValues:(NSTimer *)timer;

@end

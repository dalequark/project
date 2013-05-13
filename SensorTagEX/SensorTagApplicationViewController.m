/*
 *  SensorTagApplicationViewController.m
 *
 * Created by Ole Andreas Torvmark on 10/2/12.
 * Copyright (c) 2012 Texas Instruments Incorporated - http://www.ti.com/
 * ALL RIGHTS RESERVED
 */

#import "SensorTagApplicationViewController.h"
#import "WalkthroughLandingViewController.h"
#import "deviceSelector.h"
#import <UIKit/UIKit.h>

@interface SensorTagApplicationViewController ()
@end

@implementation SensorTagApplicationViewController

@synthesize d, status, display, history;
@synthesize sensorsEnabled, taskSensorName, taskIntervalLen, taskReminderTime;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


-(id) initWithStyle:(UITableViewStyle)style andSensorTag:(BLEDevice *)andSensorTag {
    self = [super initWithStyle:style];
    if (self) {
        self.d = andSensorTag;
        
        if (!self.display) {
            self.display = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"headercell"];
            self.display.textLabel.text = [NSString
                                   stringWithFormat:@"Maximum %@ days between tasks",
                                   self.taskIntervalLen];
            self.display.detailTextLabel.text = [NSString
                                         stringWithFormat:@"Remind me around %@ if I've forgotten",
                                         self.taskReminderTime];
        }
        
        if (!self.history) {
            CGRect frame = CGRectMake(12, 0, 296, 300);
            self.history = [[UITableViewCell alloc] init];
            self.history.backgroundView = [[UIView alloc] initWithFrame: frame];
            
            UIWebView* webView = [[UIWebView alloc] initWithFrame: frame];
            webView.tag = 1001;
            //webView.userInteractionEnabled = NO;
            webView.opaque = YES;
            webView.backgroundColor = [UIColor groupTableViewBackgroundColor];
            [self.history addSubview:webView];
            
            NSURL *url = [NSURL URLWithString:@"http://cstedman.mycpanel.princeton.edu/hci/"];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            [webView setScalesPageToFit:YES];
            [webView loadRequest:request];
        }
    
        if (!self.acc) {
            self.acc = [[accelerometerCellTemplate alloc]
                        initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Accelerometer"];
            self.acc.textLabel.text = @"Detect task using sensor motion";
            self.acc.detailTextLabel.text = @"Accelerometer data will be sent to server";
        }
        
        if (!self.gyro) {
            self.gyro = [[accelerometerCellTemplate alloc]
                         initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Gyroscope"];
            self.gyro.textLabel.text = @"Detect task using sensor rotation";
            self.gyro.detailTextLabel.text = @"Gyroscope data will be sent to server";
            
            //[self.gyro.accCalibrateButton addTarget:self action:@selector(handleCalibrateGyro) forControlEvents:UIControlEventTouchUpInside];
            self.gyroSensor = [[sensorIMU3000 alloc] init];
        }
        
        if (!self.mag) {
            self.mag = [[accelerometerCellTemplate alloc]
                        initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Magnetometer"];
            self.mag.textLabel.text = @"Detect task using magnet motion";
            self.mag.detailTextLabel.text = @"Magnetometer data will be sent to server";

            //[self.mag.accCalibrateButton addTarget:self action:@selector(handleCalibrateMag) forControlEvents:UIControlEventTouchUpInside];
            self.magSensor = [[sensorMAG3110 alloc] init];
        }

    }
    self.currentVal = [[sensorTagValues alloc]init];
    self.vals = [[NSMutableArray alloc]init];
    
    self.logInterval = 1.0; //1000 ms
    self.logTimer = [NSTimer scheduledTimerWithTimeInterval:self.logInterval target:self selector:@selector(logValues:) userInfo:nil repeats:YES];
    
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    self.sensorsEnabled = [[NSMutableArray alloc] init];
    if (!self.d.p.isConnected) {
        self.d.manager.delegate = self;
        [self.d.manager connectPeripheral:self.d.p options:nil];
    } else {
        self.d.p.delegate = self;
        [self configureSensorTag];
    }
}


-(void)viewWillDisappear:(BOOL)animated {
    [self deconfigureSensorTag];    
}

-(void)viewDidDisappear:(BOOL)animated {
    self.sensorsEnabled = nil;
    self.d.manager.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:[self spinner]];
    [self.navigationItem setRightBarButtonItem:barButton];
    [self.spinner startAnimating];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 3;
    } else {
        return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 56;
    } else {
        return 300;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Task Configuration";
    } else {
        return @"Task History";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        
        if (indexPath.row == 0) {
            return self.display;
        } else if (indexPath.row == 1) {
            if ([self.taskSensorName isEqualToString:@"accel"]) {
                return self.acc;
            } else if ([self.taskSensorName isEqualToString:@"gyro"]) {
                return self.gyro;
            } else if ([self.taskSensorName isEqualToString:@"magneto"]) {
                return self.mag;
            } else {
                return self.acc;
            }
            
        } else {
            self.status = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"status"];
            if ([self.taskSensorName isEqualToString:@"magneto"]) {
                self.status.imageView.image = [UIImage imageNamed:@"magnetometer.png"];
            } else {
                self.status.imageView.image = [UIImage imageNamed:@"gyroscope.png"];
            }
            
            self.status.textLabel.opaque = NO;
            [self.status setSelectionStyle:UITableViewCellSelectionStyleGray];
            if (self.triggered == YES || self.resetting == YES) {
                self.status.textLabel.textColor = [UIColor colorWithRed:20/255.0f green:80/255.0f blue:32/255.0f alpha:1.0f];
                self.status.textLabel.text = @"Sensor activity detected!";
                [self.status setHighlighted:YES animated:NO];
            } else {
                self.status.textLabel.textColor = [UIColor blackColor];
                self.status.textLabel.text = @"No sensor activity detected";
                [self.status setHighlighted:NO animated:YES];
            }
            return self.status;
        }
    } else {
        return self.history;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

-(void) configureSensorTag {
    // Configure sensortag, turning on Sensors and setting update period for sensors etc ...
    
    if ([self sensorEnabled:@"Accelerometer active"]) {
        CBUUID *sUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Accelerometer service UUID"]];
        CBUUID *cUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Accelerometer config UUID"]];
        CBUUID *pUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Accelerometer period UUID"]];
        NSInteger period = [[self.d.setupData valueForKey:@"Accelerometer period"] integerValue];
        uint8_t periodData = (uint8_t)(period / 10);
        [BLEUtility writeCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:pUUID data:[NSData dataWithBytes:&periodData length:1]];
        uint8_t data = 0x01;
        [BLEUtility writeCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&data length:1]];
        cUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Accelerometer data UUID"]];
        [BLEUtility setNotificationForCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID enable:YES];
        [self.sensorsEnabled addObject:@"Accelerometer"];
    }
    
    if ([self sensorEnabled:@"Gyroscope active"]) {
        CBUUID *sUUID =  [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Gyroscope service UUID"]];
        CBUUID *cUUID =  [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Gyroscope config UUID"]];
        uint8_t data = 0x07;
        [BLEUtility writeCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&data length:1]];
        cUUID =  [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Gyroscope data UUID"]];
        [BLEUtility setNotificationForCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID enable:YES];
        [self.sensorsEnabled addObject:@"Gyroscope"];
    }
    
    if ([self sensorEnabled:@"Magnetometer active"]) {
        CBUUID *sUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Magnetometer service UUID"]];
        CBUUID *cUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Magnetometer config UUID"]];
        CBUUID *pUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Magnetometer period UUID"]];
        NSInteger period = [[self.d.setupData valueForKey:@"Magnetometer period"] integerValue];
        uint8_t periodData = (uint8_t)(period / 10);
        [BLEUtility writeCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:pUUID data:[NSData dataWithBytes:&periodData length:1]];
        uint8_t data = 0x01;
        [BLEUtility writeCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&data length:1]];
        cUUID = [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Magnetometer data UUID"]];
        [BLEUtility setNotificationForCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID enable:YES];
        [self.sensorsEnabled addObject:@"Magnetometer"];
    }
    
    // create the button to delete this task
    [self.spinner stopAnimating];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc ]
                                   initWithTitle:@"Reset"
                                   style:UIBarButtonItemStyleBordered
                                   target:self action:@selector(confirmDeleteTask)];
    [self.navigationItem setRightBarButtonItem:doneButton];
}

-(void) deconfigureSensorTag {
    if ([self sensorEnabled:@"Accelerometer active"]) {
        CBUUID *sUUID =  [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Accelerometer service UUID"]];
        CBUUID *cUUID =  [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Accelerometer config UUID"]];
        uint8_t data = 0x00;
        [BLEUtility writeCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&data length:1]];
        cUUID =  [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Accelerometer data UUID"]];
        [BLEUtility setNotificationForCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID enable:NO];
    }
    if ([self sensorEnabled:@"Magnetometer active"]) {
        CBUUID *sUUID =  [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Magnetometer service UUID"]];
        CBUUID *cUUID =  [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Magnetometer config UUID"]];
        uint8_t data = 0x00;
        [BLEUtility writeCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&data length:1]];
        cUUID =  [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Magnetometer data UUID"]];
        [BLEUtility setNotificationForCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID enable:NO];
    }
    if ([self sensorEnabled:@"Gyroscope active"]) {
        CBUUID *sUUID =  [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Gyroscope service UUID"]];
        CBUUID *cUUID =  [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Gyroscope config UUID"]];
        uint8_t data = 0x00;
        [BLEUtility writeCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&data length:1]];
        cUUID =  [CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Gyroscope data UUID"]];
        [BLEUtility setNotificationForCharacteristic:self.d.p sCBUUID:sUUID cCBUUID:cUUID enable:NO];
    }
}

-(bool)sensorEnabled:(NSString *)Sensor {
    NSString *val = [self.d.setupData valueForKey:Sensor];
    if (val) {
        if ([val isEqualToString:@"1"]) return TRUE;
    }
    return FALSE;
}

-(int)sensorPeriod:(NSString *)Sensor {
    NSString *val = [self.d.setupData valueForKey:Sensor];
    return [val integerValue];
}

#pragma mark - CBCentralManager delegate function

-(void) centralManagerDidUpdateState:(CBCentralManager *)central {
    
}

-(void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}

- (void)confirmDeleteTask
{
    UIAlertView *alert = [[UIAlertView alloc] init];
	[alert setTitle:@"Reset Sensor"];
	[alert setMessage:@"Do you want to delete this task?"];
	[alert setDelegate:self];
	[alert addButtonWithTitle:@"Yes"];
	[alert addButtonWithTitle:@"No"];
	[alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0) {
		[self deleteTask];
	} else if (buttonIndex == 1) {
		// don't delete the task
	}
}

- (void)deleteTask
{
    // send request to our server with data
    NSString *baseURL = @"http://cstedman.mycpanel.princeton.edu/hci/backend.php/";
    NSString *urlString = [NSString stringWithFormat:@"%@?action=disconnect&uuid=%@", baseURL,
                           CFUUIDCreateString(nil, self.d.p.UUID)];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation
                                         JSONRequestOperationWithRequest:request
                                         success:^(NSURLRequest *request,
                                                   NSHTTPURLResponse *response, id JSON) {
        NSLog(@"%@: %@", [JSON valueForKeyPath:@"status"], [JSON valueForKeyPath:@"message"]);

        [self deconfigureSensorTag];
        
        // set up the sensortag chooser
        UIViewController *parent = [[WalkthroughLandingViewController alloc]init];
        UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
        deviceSelector *dS = [[deviceSelector alloc]initWithStyle:UITableViewStyleGrouped];
        UINavigationController *rC = [[UINavigationController alloc]initWithRootViewController:parent];
        [dS.m scanForPeripheralsWithServices:nil options:nil];
        [rC pushViewController:dS animated:YES];
        mainWindow.rootViewController = rC;
        
    } failure:nil];
    [operation start];
}

#pragma mark - CBperipheral delegate functions

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    // BLE services discovered
    NSString *uuidString = [self.d.setupData valueForKey:@"Gyroscope service UUID"];
    if ([service.UUID isEqual:[CBUUID UUIDWithString:uuidString]]) {
        [self configureSensorTag];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@".");
    for (CBService *s in peripheral.services) [peripheral discoverCharacteristics:nil forService:s];
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didUpdateNotificationStateForCharacteristic %@, error = %@",characteristic.UUID, error);
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    //NSLog(@"didUpdateValueForCharacteristic = %@",characteristic.UUID);

    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Accelerometer data UUID"]]]) {
        
        float oldValX = self.currentVal.accX;
        float oldValY = self.currentVal.accY;
        float oldValZ = self.currentVal.accZ;
        
        float x = [sensorKXTJ9 calcXValue:characteristic.value];
        float y = [sensorKXTJ9 calcYValue:characteristic.value];
        float z = [sensorKXTJ9 calcZValue:characteristic.value];
                
        self.currentVal.accX = x;
        self.currentVal.accY = y;
        self.currentVal.accZ = z;
        

        // detect significant amount of movement
        float accdx = (x-oldValX);
        float accdy = (y-oldValY);
        float accdz = (z-oldValZ);
        float movementVector = accdx*accdx + accdy*accdy + accdz*accdz;
        
        if (movementVector > ACCELCHANGECUTTOFF) {
            // send request to our server with data
            NSString *baseURL = @"http://cstedman.mycpanel.princeton.edu/hci/backend.php/";
            NSString *urlString = [NSString stringWithFormat:@"%@?action=accel&uuid=%@", baseURL, CFUUIDCreateString(nil, peripheral.UUID)];
            NSURL *url = [NSURL URLWithString:urlString];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            
            AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                NSLog(@"%@: %@", [JSON valueForKeyPath:@"status"], [JSON valueForKeyPath:@"message"]);
            } failure:nil];
            
            if ([self.taskSensorName isEqualToString:@"accel"]) {
                self.triggered = YES;
            }
            [operation start];
        }
    }
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Magnetometer data UUID"]]]) {
        
        float x = [self.magSensor calcXValue:characteristic.value];
        float y = [self.magSensor calcYValue:characteristic.value];
        float z = [self.magSensor calcZValue:characteristic.value];
        
        self.currentVal.magX = x;
        self.currentVal.magY = y;
        self.currentVal.magZ = z;
        
    }
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:[self.d.setupData valueForKey:@"Gyroscope data UUID"]]]) {
        
        float oldValX = self.currentVal.gyroX;
        float oldValY = self.currentVal.gyroY;
        float oldValZ = self.currentVal.gyroZ;
        
        float x = [self.gyroSensor calcXValue:characteristic.value];
        float y = [self.gyroSensor calcYValue:characteristic.value];
        float z = [self.gyroSensor calcZValue:characteristic.value];
        
        self.currentVal.gyroX = x;
        self.currentVal.gyroY = y;
        self.currentVal.gyroZ = z;
        
        // detect significant amount of gyro movement
        float dx = (x-oldValX);
        float dy = (y-oldValY);
        float dz = (z-oldValZ);
        float movementVector2 = dx*dx + dy*dy + dz*dz;
        
        if (movementVector2 > GYROCHANGECUTOFF) {
            // send request to our server with data
            NSString *baseURL = @"http://cstedman.mycpanel.princeton.edu/hci/backend.php/";
            NSString *urlString = [NSString stringWithFormat:@"%@?action=gyro&uuid=%@", baseURL, CFUUIDCreateString(nil, peripheral.UUID)];
            NSURL *url = [NSURL URLWithString:urlString];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            
            AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                NSLog(@"%@: %@", [JSON valueForKeyPath:@"message"], [JSON valueForKeyPath:@"origin"]);
            } failure:nil];
            
            if ([self.taskSensorName isEqualToString:@"gyro"]) {
                self.triggered = YES;
            }
            [operation start];
        }
    }
    [self.tableView reloadData];
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didWriteValueForCharacteristic %@ error = %@",characteristic.UUID,error);
}

- (IBAction) handleCalibrateMag {
    NSLog(@"Calibrate magnetometer pressed !");
    [self.magSensor calibrate];
}
- (IBAction) handleCalibrateGyro {
    NSLog(@"Calibrate gyroscope pressed ! ");
    [self.gyroSensor calibrate];
}

-(void) logValues:(NSTimer *)timer {
    NSString *date = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                    dateStyle:NSDateFormatterShortStyle
                                                    timeStyle:NSDateFormatterMediumStyle];
    self.currentVal.timeStamp = date;
    sensorTagValues *newVal = [[sensorTagValues alloc]init];
    newVal.accX = self.currentVal.accX;
    newVal.accY = self.currentVal.accY;
    newVal.accZ = self.currentVal.accZ;
    newVal.gyroX = self.currentVal.gyroX;
    newVal.gyroY = self.currentVal.gyroY;
    newVal.gyroZ = self.currentVal.gyroZ;
    newVal.magX = self.currentVal.magX;
    newVal.magY = self.currentVal.magY;
    newVal.magZ = self.currentVal.magZ;
    newVal.timeStamp = date;
    
    [self.vals addObject:newVal];
    
    self.resetting = self.triggered;
    self.triggered = NO;
}

@end

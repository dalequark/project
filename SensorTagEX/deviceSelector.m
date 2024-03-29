/*
 *  deviceSelector.m
 *
 * Created by Ole Andreas Torvmark on 10/2/12.
 * Copyright (c) 2012 Texas Instruments Incorporated - http://www.ti.com/
 * ALL RIGHTS RESERVED
 */

#import "deviceSelector.h"
#import "WalkthroughLandingViewController.h"
#import "SensorSetupViewController.h"

@interface deviceSelector ()

@end

@implementation deviceSelector
@synthesize m, nDevices, sensorTags;
@synthesize sensorTagsTaskName, sensorTagsTaskSensor, sensorTagsTaskInterval, sensorTagsReminderTime;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.m = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
        self.nDevices = [[NSMutableArray alloc]init];
        self.sensorTags = [[NSMutableArray alloc]init];
        self.sensorTagsTaskName = [[NSMutableArray alloc]init];
        self.sensorTagsTaskSensor = [[NSMutableArray alloc]init];
        self.sensorTagsTaskInterval = [[NSMutableArray alloc]init];
        self.sensorTagsReminderTime = [[NSMutableArray alloc]init];
        self.title = @"Tracked Tasks";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set up a back button
    UIBarButtonItem *mailer = [[UIBarButtonItem alloc]initWithTitle:@"Help" style:UIBarButtonItemStylePlain target:self action:@selector(backToWalkthrough)];
    [[self navigationItem] setLeftBarButtonItem:mailer];
    
    // set up a spinner waiting for sensor tags to connect
    self.spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:[self spinner]];
    [self.navigationItem setRightBarButtonItem:barButton];
    [self.spinner startAnimating];
}

- (void)backToWalkthrough
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    UIViewController *firstScreen = (WalkthroughLandingViewController *)[storyboard instantiateInitialViewController];
    [self.navigationController setNavigationBarHidden:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController setViewControllers:[NSArray arrayWithObjects: firstScreen, nil] animated:YES];
    //[self.navigationController setView:firstScreen.view];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated {
    self.m.delegate = self;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return sensorTags.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
     rather than adding every sensor that is paired immediately, make HTTP requests 
     to get the associated task for each paired sensor, using its UUID. if we cannot
     identify an associated task, insert a row that prompts us to set up a new task
     */
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:[NSString stringWithFormat:@"%d_Cell",indexPath.row]];
    CBPeripheral *p = [self.sensorTags objectAtIndex:indexPath.row];
    
    // retrieve sensor data from the server
    NSString *baseURL = @"http://cstedman.mycpanel.princeton.edu/hci/backend.php/";
    NSString *urlString = [NSString stringWithFormat:@"%@?action=info&uuid=%@",
                           baseURL, CFUUIDCreateString(nil,p.UUID)];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
                                        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    cell.accessoryView = spinner;
    spinner.frame = CGRectMake(145, 0, 30, 30);
    [spinner startAnimating];
    
    AFJSONRequestOperation *operation =
    [AFJSONRequestOperation
     JSONRequestOperationWithRequest:request
     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if ([@"success" isEqualToString:[JSON valueForKeyPath:@"status"]]) {
            // Existing sensor
            NSString *name = [JSON valueForKeyPath:@"task"];
            NSString *sensor = [JSON valueForKeyPath:@"sensor"];
            NSString *interval = [JSON valueForKeyPath:@"interval"];
            NSString *time = @"7pm"; //[JSON valueForKeyPath:@"interval"]; // TODO XXX
            
            NSLog(@"Found an existing sensor: %@ (%@)", name, sensor);
            [self.sensorTagsTaskName replaceObjectAtIndex:indexPath.row withObject:name];
            [self.sensorTagsTaskSensor replaceObjectAtIndex:indexPath.row withObject:sensor];
            [self.sensorTagsTaskInterval replaceObjectAtIndex:indexPath.row withObject:interval];
            [self.sensorTagsReminderTime replaceObjectAtIndex:indexPath.row withObject:time];
            cell.textLabel.text = name;
        } else {
            // New sensor
            NSLog(@"Found a new sensor");
            [self.sensorTagsTaskName replaceObjectAtIndex:indexPath.row withObject:[NSNull null]];
            [self.sensorTagsTaskSensor replaceObjectAtIndex:indexPath.row withObject:[NSNull null]];
            [self.sensorTagsTaskInterval replaceObjectAtIndex:indexPath.row withObject:[NSNull null]];
            [self.sensorTagsReminderTime replaceObjectAtIndex:indexPath.row withObject:[NSNull null]];
            cell.textLabel.text = @"New Sensor";
            cell.detailTextLabel.text= @"Click to add a new task";
        }
        NSLog(@"%@: %@", [JSON valueForKeyPath:@"status"], [JSON valueForKeyPath:@"message"]);
        [spinner stopAnimating];
        [cell setNeedsLayout];
     }
     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
         NSLog(@"Server error %d: %@", [response statusCode], JSON == NULL ? [error userInfo] : JSON);
     }];
    [operation start];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        if (self.sensorTags.count >= 1) {
            [[self spinner] stopAnimating];
            return @"Select a task above to configure the associated sensor.";
        } else {
            return @"Searching for sensors...";
        }
    }
    return nil;
}

#pragma mark - Table view delegate

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CBPeripheral *p = [self.sensorTags objectAtIndex:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // TODO: initialize the BLEDevice earlier, so that we connect as soon as the device is available
    BLEDevice *d = [[BLEDevice alloc]init];
    d.p = p;
    d.manager = self.m;
    d.setupData = [self makeSensorTagConfiguration];
    
    if ([self.sensorTagsTaskName objectAtIndex:indexPath.row] == [NSNull null]) {
        
        // new sensor, take us to setup page
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"SensorSetupStoryboard" bundle:nil];
        UIViewController *vc = [sb instantiateInitialViewController];
        ((SensorSetupViewController*)vc).setupDevice = d;
        vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:vc animated:YES completion:NULL];

    } else {
        
        // existing sensor
        SensorTagApplicationViewController *sensorVC =
            [[SensorTagApplicationViewController alloc]initWithStyle:UITableViewStyleGrouped andSensorTag:d];
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]
                                                 initWithTitle:@"Tasks"
                                                 style:UIBarButtonItemStyleBordered
                                                 target:nil action:nil];
        sensorVC.title = [self.sensorTagsTaskName objectAtIndex:indexPath.row];
        sensorVC.taskSensorName = [self.sensorTagsTaskSensor objectAtIndex:indexPath.row];
        sensorVC.taskIntervalLen = [self.sensorTagsTaskInterval objectAtIndex:indexPath.row];
        sensorVC.taskReminderTime = [self.sensorTagsReminderTime objectAtIndex:indexPath.row];

        if (![[self.sensorTagsTaskSensor objectAtIndex:indexPath.row] isEqualToString:@"accel"]){
            sensorVC.acc.hidden = @"YES";
        }
        if (![[self.sensorTagsTaskSensor objectAtIndex:indexPath.row] isEqualToString:@"magneto"]){
            sensorVC.mag.hidden = @"YES";
        }
        if (![[self.sensorTagsTaskSensor objectAtIndex:indexPath.row] isEqualToString:@"gyro"]){
            sensorVC.gyro.hidden = @"YES";
        }
        [self.navigationController pushViewController:sensorVC animated:YES];
    }
}

#pragma mark - CBCentralManager delegate

-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state != CBCentralManagerStatePoweredOn) {
        NSLog(@"CoreBluetooth return state: %d",central.state);
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"BLE Error"
                                  message:@"Use an iPhone 4S, iPad 3, iPad Mini, or later."
                                  delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    } else {
        [central scanForPeripheralsWithServices:nil options:nil];
    }
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"Found a BLE Device : %@",peripheral);
    
    /* iOS 6.0 bug workaround : connect to device before displaying UUID !
       The reason for this is that the CFUUID .UUID property of CBPeripheral
       here is null the first time an unkown (never connected before in any app)
       peripheral is connected. So therefore we connect to all peripherals we find.
    */
    
    peripheral.delegate = self;
    [central connectPeripheral:peripheral options:nil];
    
    [self.nDevices addObject:peripheral];
    
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [peripheral discoverServices:nil];
}

#pragma  mark - CBPeripheral delegate

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    BOOL replace = NO;
    BOOL found = NO;
    NSLog(@"Services scanned !");
    [self.m cancelPeripheralConnection:peripheral];
    for (CBService *s in peripheral.services) {
        NSLog(@"Service found : %@",s.UUID);
        if ([s.UUID isEqual:[CBUUID UUIDWithString:@"f000aa00-0451-4000 b000-000000000000"]])  {
            // this is a SensorTag
            found = YES;
        }
    }
    if (found) {
        // Match if we have this device from before
        for (int ii=0; ii < self.sensorTags.count; ii++) {
            CBPeripheral *p = [self.sensorTags objectAtIndex:ii];
            if ([p isEqual:peripheral]) {
                    [self.sensorTags replaceObjectAtIndex:ii withObject:peripheral];
                    [self.sensorTagsTaskName replaceObjectAtIndex:ii withObject:[NSNull null]];
                    [self.sensorTagsTaskSensor replaceObjectAtIndex:ii withObject:[NSNull null]];
                    [self.sensorTagsTaskInterval replaceObjectAtIndex:ii withObject:[NSNull null]];
                    [self.sensorTagsReminderTime replaceObjectAtIndex:ii withObject:[NSNull null]];
                    replace = YES;
                }
            }
        if (!replace) {
            [self.sensorTags addObject:peripheral];
            [self.sensorTagsTaskName addObject:[NSNull null]];
            [self.sensorTagsTaskSensor addObject:[NSNull null]];
            [self.sensorTagsTaskInterval addObject:[NSNull null]];
            [self.sensorTagsReminderTime addObject:[NSNull null]];
            [self.tableView reloadData];
        }
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didUpdateNotificationStateForCharacteristic %@ error = %@",characteristic,error);
}

-(void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didWriteValueForCharacteristic %@ error = %@",characteristic,error);
}


#pragma mark - SensorTag configuration

-(NSMutableDictionary *) makeSensorTagConfiguration {
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    
    // Then we setup the accelerometer
    [d setValue:@"1" forKey:@"Accelerometer active"];
    [d setValue:@"500" forKey:@"Accelerometer period"];
    [d setValue:@"f000aa10-0451-4000 b000-000000000000"  forKey:@"Accelerometer service UUID"];
    [d setValue:@"f000aa11-0451-4000 b000-000000000000"  forKey:@"Accelerometer data UUID"];
    [d setValue:@"f000aa12-0451-4000 b000-000000000000"  forKey:@"Accelerometer config UUID"];
    [d setValue:@"f000aa13-0451-4000 b000-000000000000"  forKey:@"Accelerometer period UUID"];
    
    //Then we setup the magnetometer
    [d setValue:@"1" forKey:@"Magnetometer active"];
    [d setValue:@"500" forKey:@"Magnetometer period"];
    [d setValue:@"f000aa30-0451-4000 b000-000000000000" forKey:@"Magnetometer service UUID"];
    [d setValue:@"f000aa31-0451-4000 b000-000000000000" forKey:@"Magnetometer data UUID"];
    [d setValue:@"f000aa32-0451-4000 b000-000000000000" forKey:@"Magnetometer config UUID"];
    [d setValue:@"f000aa33-0451-4000 b000-000000000000" forKey:@"Magnetometer period UUID"];
    
    //Then we setup the gyroscope    
    [d setValue:@"1" forKey:@"Gyroscope active"];
    [d setValue:@"f000aa50-0451-4000 b000-000000000000" forKey:@"Gyroscope service UUID"];
    [d setValue:@"f000aa51-0451-4000 b000-000000000000" forKey:@"Gyroscope data UUID"];
    [d setValue:@"f000aa52-0451-4000 b000-000000000000" forKey:@"Gyroscope config UUID"];
    
    return d;
}

@end

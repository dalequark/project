/*
 *  deviceSelector.m
 *
 * Created by Ole Andreas Torvmark on 10/2/12.
 * Copyright (c) 2012 Texas Instruments Incorporated - http://www.ti.com/
 * ALL RIGHTS RESERVED
 */

#import "deviceSelector.h"
#import "WalkthroughLandingViewController.h"

@interface deviceSelector ()

@end

@implementation deviceSelector
@synthesize m,nDevices,sensorTags;



- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.m = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
        self.nDevices = [[NSMutableArray alloc]init];
        self.sensorTags = [[NSMutableArray alloc]init];
        self.title = @"SensorTag Example";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /* XXX
     here we should set up an initial view with a spinner
     and text telling the user that we are waiting to detect sensortags
     which should go away once at least one sensortag is added to the view
     */
    
    // set up a back button
    UIBarButtonItem *mailer = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(backToWalkthrough)];
    [self.navigationItem setLeftBarButtonItem:mailer];

}

- (void)backToWalkthrough
{
    UIViewController *firstScreen = [[WalkthroughLandingViewController alloc]init];
    [self.navigationController pushViewController:firstScreen animated:YES];
    //[self.navigationController popToRootViewControllerAnimated:YES];
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
    /* XXX
     rather than adding every sensor that is paired immediately,
     here we should make HTTP requests to get the associated
     task for each paired sensor, using its UUID
     
     if we cannot identify an associated task, insert an alternate
     row into the view that prompts us to set up a new task
     */
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:[NSString stringWithFormat:@"%d_Cell",indexPath.row]];
    CBPeripheral *p = [self.sensorTags objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@",p.name];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",CFUUIDCreateString(nil, p.UUID)];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

-(NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if (self.sensorTags.count > 1) return [NSString stringWithFormat:@"Found %d sensor tags",self.sensorTags.count];
        else if (self.sensorTags.count == 1) return @"Found a sensor tag";
        else return @"Connect a sensor tag...";
    }
    
    return @"";
}

-(float) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 150.0f;
}

#pragma mark - Table view delegate

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CBPeripheral *p = [self.sensorTags objectAtIndex:indexPath.row];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    BLEDevice *d = [[BLEDevice alloc]init];
    
    d.p = p;
    d.manager = self.m;
    d.setupData = [self makeSensorTagConfiguration];
    
    SensorTagApplicationViewController *vC = [[SensorTagApplicationViewController alloc]initWithStyle:UITableViewStyleGrouped andSensorTag:d];
    [self.navigationController pushViewController:vC animated:YES];
    
}

#pragma mark - CBCentralManager delegate

-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state != CBCentralManagerStatePoweredOn) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"BLE not supported !" message:[NSString stringWithFormat:@"CoreBluetooth return state: %d",central.state] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
    else {
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
            NSLog(@"This is a SensorTag !");
            found = YES;
        }
    }
    if (found) {
        // Match if we have this device from before
        for (int ii=0; ii < self.sensorTags.count; ii++) {
            CBPeripheral *p = [self.sensorTags objectAtIndex:ii];
            if ([p isEqual:peripheral]) {
                    [self.sensorTags replaceObjectAtIndex:ii withObject:peripheral];
                    replace = YES;
                }
            }
        if (!replace) {
            [self.sensorTags addObject:peripheral];
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

    NSLog(@"%@",d);
    
    return d;
}

@end

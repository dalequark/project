/*
 *  deviceCellTemplate.m
 *
 * Created by Ole Andreas Torvmark on 10/2/12.
 * Copyright (c) 2012 Texas Instruments Incorporated - http://www.ti.com/
 * ALL RIGHTS RESERVED
 */

#import "deviceCellTemplate.h"
#import "AFHTTPRequestOperation.h"

@implementation deviceCellTemplate

@synthesize deviceName,deviceInfo,deviceIcon;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        self.backgroundColor = [UIColor whiteColor];
        self.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        
        // Initialization code
        self.deviceName = [[UILabel alloc] init];
        self.deviceName.textAlignment = NSTextAlignmentLeft;
        self.deviceName.font = [UIFont boldSystemFontOfSize:14];
        
        self.deviceInfo = [[UILabel alloc] init];
        self.deviceInfo.textAlignment = NSTextAlignmentLeft;
        self.deviceInfo.font = [UIFont boldSystemFontOfSize:8];
        
        self.deviceIcon = [[UIImageView alloc] init];
        [self.deviceIcon setAutoresizingMask:UIViewAutoresizingNone];
        self.deviceIcon.contentMode = UIViewContentModeScaleAspectFit;
        
        [self.contentView addSubview:self.deviceName];
        [self.contentView addSubview:self.deviceInfo];
        [self.contentView addSubview:self.deviceIcon];
        
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    CGRect contentRect = self.contentView.bounds;
    CGFloat boundsX = contentRect.origin.x;
    CGRect fr;
    
    fr = CGRectMake(boundsX + 10, 2, 45, 45);
    self.deviceIcon.frame = fr;
    
    fr = CGRectMake(boundsX + 70, 5, self.contentView.bounds.size.width - 100, 25);
    self.deviceName.frame = fr;
    
    fr = CGRectMake(boundsX + 70, 30,self.contentView.bounds.size.width - 100, 15);
    self.deviceInfo.frame = fr;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end



@implementation serviceWithoutPeriodCellTemplate

@synthesize serviceName;
@synthesize serviceOnOffButton;
@synthesize height;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.height = 50;
        self.serviceName = [[UILabel alloc] init];
        self.serviceName.textAlignment = NSTextAlignmentLeft;
        self.serviceName.font = [UIFont boldSystemFontOfSize:17];
        self.serviceName.backgroundColor = [UIColor clearColor];
        
        self.serviceOnOffButton = [[UISwitch alloc] init];
        self.serviceOnOffButton.enabled = YES;
        self.serviceOnOffButton.hidden = NO;
        
        [self.contentView addSubview:self.serviceOnOffButton];
        [self.contentView addSubview:self.serviceName];
    }
    return self;
}

-(void) layoutSubviews {
    [super layoutSubviews];
    CGRect contentRect = self.contentView.bounds;
    CGFloat boundsX = contentRect.origin.x;
    CGRect fr;
    
    if (contentRect.size.width < WIDTH_CHECKER) {
        self.serviceName.font = [UIFont boldSystemFontOfSize:12];
        fr = CGRectMake(boundsX + 10, 10, 300, 30);
        self.serviceName.frame = fr;
    }
    else {
        self.serviceName.font = [UIFont boldSystemFontOfSize:17];
        fr = CGRectMake(boundsX + 10, 10, 300, 30);
        self.serviceName.frame = fr;
    }
    fr = CGRectMake(boundsX + contentRect.size.width - 90, 10, 100, 30);
    self.serviceOnOffButton.frame = fr;
    
}

@end

@implementation serviceWithPeriodCellTemplate

@synthesize serviceName;
@synthesize serviceOnOffButton;
@synthesize servicePeriodSlider;
@synthesize servicePeriodMax;
@synthesize servicePeriodMin;
@synthesize servicePeriodCur;
@synthesize height;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.height = 100;
        self.serviceName = [[UILabel alloc] init];
        self.serviceName.textAlignment = NSTextAlignmentLeft;
        self.serviceName.font = [UIFont boldSystemFontOfSize:17];
        self.serviceName.backgroundColor = [UIColor clearColor];

        self.serviceOnOffButton = [[UISwitch alloc] init];
        self.serviceOnOffButton.enabled = YES;
        self.serviceOnOffButton.hidden = NO;
        
        self.servicePeriodSlider = [[UISlider alloc] init];
        self.servicePeriodSlider.enabled = YES;
        self.servicePeriodSlider.hidden = NO;
        [self.servicePeriodSlider addTarget:self action:@selector(updateSliderValue:) forControlEvents:UIControlEventValueChanged];
        
        self.servicePeriodMax = [[UILabel alloc] init];
        self.servicePeriodMax.textAlignment = NSTextAlignmentLeft;
        self.servicePeriodMax.font = [UIFont systemFontOfSize:16];
        self.servicePeriodMax.backgroundColor = [UIColor clearColor];

        self.servicePeriodMin = [[UILabel alloc] init];
        self.servicePeriodMin.textAlignment = NSTextAlignmentLeft;
        self.servicePeriodMin.font = [UIFont systemFontOfSize:16];
        self.servicePeriodMin.backgroundColor = [UIColor clearColor];
        
        self.servicePeriodCur = [[UILabel alloc] init];
        self.servicePeriodCur.textAlignment = NSTextAlignmentLeft;
        self.servicePeriodCur.font = [UIFont systemFontOfSize:16];
        self.servicePeriodCur.backgroundColor = [UIColor clearColor];
        
        
        [self.contentView addSubview:self.serviceOnOffButton];
        [self.contentView addSubview:self.serviceName];
        [self.contentView addSubview:self.servicePeriodSlider];
        [self.contentView addSubview:self.servicePeriodMax];
        [self.contentView addSubview:self.servicePeriodMin];
        [self.contentView addSubview:self.servicePeriodCur];
        
    }
    return self;
}

-(void) layoutSubviews {
    [super layoutSubviews];
    CGRect contentRect = self.contentView.bounds;
    CGFloat boundsX = contentRect.origin.x;
    CGRect fr;
    NSLog(@"Frame : %f,%f,%f,%f ",contentRect.origin.x,contentRect.origin.y,contentRect.size.width,contentRect.size.height);
    if (self.contentView.bounds.size.width < WIDTH_CHECKER) self.height = 100;
    else self.height = 50;
    
    if (contentRect.size.width < WIDTH_CHECKER) {
        fr = CGRectMake(boundsX + 10, 10, 300, 30);
        self.serviceName.frame = fr;
        
        fr = CGRectMake(boundsX + contentRect.size.width - 90, 10, 100, 30);
        self.serviceOnOffButton.frame = fr;
        
        fr = CGRectMake(boundsX + (contentRect.size.width / 2) - 80, 63, 160, 30);
        self.servicePeriodSlider.frame = fr;
        
        fr = CGRectMake(boundsX + (contentRect.size.width / 2) - 130, 63, 160, 30);
        self.servicePeriodMin.frame = fr;
        
        fr = CGRectMake(boundsX + (contentRect.size.width / 2) + 90, 63, 160, 30);
        self.servicePeriodMax.frame = fr;
        
        fr = CGRectMake(boundsX + (contentRect.size.width / 2) - 30, 40, 160, 30);
        self.servicePeriodCur.frame = fr;
    }
    else {
        fr = CGRectMake(boundsX + 10, 10, 300, 30);
        self.serviceName.frame = fr;
        
        fr = CGRectMake(boundsX + contentRect.size.width - 90, 10, 100, 30);
        self.serviceOnOffButton.frame = fr;
        
        fr = CGRectMake(boundsX + (contentRect.size.width / 2) - 80, 3, 160, 30);
        self.servicePeriodSlider.frame = fr;
        
        fr = CGRectMake(boundsX + (contentRect.size.width / 2) - 130, 3, 160, 30);
        self.servicePeriodMin.frame = fr;
        
        fr = CGRectMake(boundsX + (contentRect.size.width / 2) + 90, 3, 160, 30);
        self.servicePeriodMax.frame = fr;
        
        fr = CGRectMake(boundsX + (contentRect.size.width / 2) - 30, 25, 160, 30);
        self.servicePeriodCur.frame = fr;
    }
    
}

-(IBAction)updateSliderValue:(id)sender {
    UISlider *slider = (UISlider *)sender;
    self.servicePeriodCur.text = [NSString stringWithFormat: @"%0.0fms",[slider value]];
}

@end

@implementation accelerometerCellTemplate
@end



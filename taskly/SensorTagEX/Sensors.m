/*
 *  Sensors.h
 *
 * Created by Ole Andreas Torvmark on 10/2/12.
 * Copyright (c) 2012 Texas Instruments Incorporated - http://www.ti.com/
 * ALL RIGHTS RESERVED
 * 
 * Temperature, humidity, and other clowny sensors removed by Raymond Zhong 4/20/13
 */

#import "Sensors.h"

@implementation sensorIMU3000

@synthesize lastX,lastY,lastZ;
@synthesize calX,calY,calZ;

-(id) init {
    self = [super init];
    if (self) {
        self.calX = 0.0f;
        self.calY = 0.0f;
        self.calZ = 0.0f;
    }
    return self;
}

-(void) calibrate {
    self.calX = self.lastX;
    self.calY = self.lastY;
    self.calZ = self.lastZ;
    
}

-(float) calcXValue:(NSData *)data {
    //Orientation of sensor on board means we need to swap X (multiplying with -1)
    char scratchVal[6];
    [data getBytes:&scratchVal length:6];
    int16_t rawX = (scratchVal[0] & 0xff) | ((scratchVal[1] << 8) & 0xff00);
    self.lastX = (((float)rawX * 1.0) / ( 65536 / IMU3000_RANGE )) * -1;
    return (self.lastX - self.calX);
}
-(float) calcYValue:(NSData *)data {
    //Orientation of sensor on board means we need to swap Y (multiplying with -1)
    char scratchVal[6];
    [data getBytes:&scratchVal length:6];
    int16_t rawY = ((scratchVal[2] & 0xff) | ((scratchVal[3] << 8) & 0xff00));
    self.lastY = (((float)rawY * 1.0) / ( 65536 / IMU3000_RANGE )) * -1;
    return (self.lastY - self.calY);
}
-(float) calcZValue:(NSData *)data {
    char scratchVal[6];
    [data getBytes:&scratchVal length:6];
    int16_t rawZ = (scratchVal[4] & 0xff) | ((scratchVal[5] << 8) & 0xff00);
    self.lastZ = ((float)rawZ * 1.0) / ( 65536 / IMU3000_RANGE );
    return (self.lastZ - self.calZ);
}
+(float) getRange {
    return IMU3000_RANGE;
}

@end

@implementation sensorKXTJ9

+(float) calcXValue:(NSData *)data {
    char scratchVal[data.length];
    [data getBytes:&scratchVal length:3];
    return ((scratchVal[0] * 1.0) / (256 / KXTJ9_RANGE));
}
+(float) calcYValue:(NSData *)data {
    //Orientation of sensor on board means we need to swap Y (multiplying with -1)
    char scratchVal[data.length];
    [data getBytes:&scratchVal length:3];
    return ((scratchVal[1] * 1.0) / (256 / KXTJ9_RANGE)) * -1;
}
+(float) calcZValue:(NSData *)data {
    char scratchVal[data.length];
    [data getBytes:&scratchVal length:3];
    return ((scratchVal[2] * 1.0) / (256 / KXTJ9_RANGE));
}
+(float) getRange {
    return KXTJ9_RANGE;
}


@end

@implementation sensorMAG3110

@synthesize lastX,lastY,lastZ;
@synthesize calX,calY,calZ;

-(id) init {
    self = [super init];
    if (self) {
        self.calX = 0.0f;
        self.calY = 0.0f;
        self.calZ = 0.0f;
    }
    return self;
}

-(void) calibrate {
    self.calX = self.lastX;
    self.calY = self.lastY;
    self.calZ = self.lastZ;
 
}

-(float) calcXValue:(NSData *)data {
    //Orientation of sensor on board means we need to swap X (multiplying with -1)
    char scratchVal[6];
    [data getBytes:&scratchVal length:6];
    int16_t rawX = (scratchVal[0] & 0xff) | ((scratchVal[1] << 8) & 0xff00);
    self.lastX = (((float)rawX * 1.0) / ( 65536 / MAG3110_RANGE )) * -1;
    return (self.lastX - self.calX);
}
-(float) calcYValue:(NSData *)data {
    //Orientation of sensor on board means we need to swap Y (multiplying with -1)
    char scratchVal[6];
    [data getBytes:&scratchVal length:6];
    int16_t rawY = ((scratchVal[2] & 0xff) | ((scratchVal[3] << 8) & 0xff00));
    self.lastY = (((float)rawY * 1.0) / ( 65536 / MAG3110_RANGE )) * -1;
    return (self.lastY - self.calY);
}
-(float) calcZValue:(NSData *)data {
    char scratchVal[6];
    [data getBytes:&scratchVal length:6];
    int16_t rawZ = (scratchVal[4] & 0xff) | ((scratchVal[5] << 8) & 0xff00);
    self.lastZ =  ((float)rawZ * 1.0) / ( 65536 / MAG3110_RANGE );
    return (self.lastZ - self.calZ);
}
+(float) getRange {
    return 60.0;
}
@end

@implementation sensorTagValues

@end

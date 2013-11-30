//
//  TWViewController.m
//  Peripheral
//
//  Created by Vivek Jain on 11/29/13.
//  Copyright (c) 2013 ThoughtWorks. All rights reserved.
//

#import "TWViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "Constants.h"

@interface TWViewController () <CBPeripheralManagerDelegate>
@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic *charateristic;
@end

@implementation TWViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: @[
                                                       [CBUUID UUIDWithString:SERVICE_UUID]
                                                       ]
                                               }
     ];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.peripheralManager stopAdvertising];
    [super viewWillDisappear:animated];
}

#pragma mark - Peripheral Manager Methods
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if(peripheral.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Peripheral Manager is not Powered ON");
        return;
    }
    
    NSLog(@"Peripheral Manager is Powered ON");
    
    self.charateristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:CHARACTERISTIC_UUID]
                                                            properties:CBCharacteristicPropertyWriteWithoutResponse
                                                                 value:nil
                                                           permissions:CBAttributePermissionsWriteable];
    
    CBMutableService *service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:SERVICE_UUID]
                                                               primary:YES];
    
    service.characteristics = @[self.charateristic];
    
    [self.peripheralManager addService:service];
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    if(error) {
        NSLog(@"Failed to Advertise (%@)", error);
    } else {
        NSLog(@"Started Advertising");
    }
    
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    for (CBATTRequest *request in requests) {
        NSString *stringFromData = [[NSString alloc] initWithData:request.value encoding:NSUTF8StringEncoding];
        NSLog(@"Received value %@", stringFromData);
    }
}

@end

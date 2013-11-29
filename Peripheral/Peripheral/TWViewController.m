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

#pragma mark - Peripheral Methods
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if(peripheral.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Peripheral Manager is not Powered ON");
        return;
    }
    
    NSLog(@"Peripheral Manager is Powered ON");
    
    self.charateristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:CHARACTERISTIC_UUID]
                                                            properties:CBCharacteristicPropertyNotify
                                                                 value:nil
                                                           permissions:CBAttributePermissionsReadable];
    
    CBMutableService *service = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:SERVICE_UUID]
                                                               primary:YES];
    
    service.characteristics = @[self.charateristic];
    
    [self.peripheralManager addService:service];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
                  central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central subscribed to characteristic");
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Cenral unsubscribed from characteristic");
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    NSLog(@"Sending Again");
    [self sendData];
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    if(error) {
        NSLog(@"Failed to Advertise (%@)", error);
    } else {
        NSLog(@"Started Advertising");
    }
    
}

#pragma mark - Private
- (void)sendData
{
    [self.peripheralManager updateValue:[@"someData" dataUsingEncoding:NSUTF8StringEncoding]
                      forCharacteristic:self.charateristic
                   onSubscribedCentrals:nil];
}

@end

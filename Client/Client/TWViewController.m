//
//  TWViewController.m
//  Client
//
//  Created by Vivek Jain on 11/29/13.
//  Copyright (c) 2013 ThoughtWorks. All rights reserved.
//

#import "TWViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "Constants.h"

@interface TWViewController () <CBCentralManagerDelegate, CBPeripheralDelegate>
@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *peripheral;
@end

@implementation TWViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.centralManager stopScan];
    [super viewWillDisappear:animated];
}

#pragma mark - Central Manager Methods
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if(central.state != CBCentralManagerStatePoweredOn)
    {
        NSLog(@"Bluetooth is not Powered ON");
        return;
    }
    
    NSLog(@"Bluetooth is ON");
    [self scan];
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSLog(@"Peripheral discovered...");
    //Reject if peripheral is not 'close enough' (~ -22dbB)
    if(RSSI.integerValue > -15 || RSSI.integerValue < -35) return;
    
    [self.centralManager stopScan];
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    
    if(self.peripheral != peripheral) {
        self.peripheral = peripheral;
        [self.centralManager connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    [self cleanup];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral connected");
    
    peripheral.delegate = self;
    [peripheral discoverServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    NSLog(@"Peripheral disconnected");
    self.peripheral = nil;
}

#pragma mark - Peripheral Methods
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:CHARACTERISTIC_UUID]]
                                 forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    for (CBCharacteristic *characterstic in service.characteristics) {
        if([characterstic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_UUID]]) {
            [peripheral setNotifyValue:YES forCharacteristic:characterstic];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    NSString *stringFromData = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"Received: %@", stringFromData);
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
    [self.centralManager cancelPeripheralConnection:peripheral];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    if(![characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_UUID]]) return;
    
    if(characteristic.isNotifying) {
        NSLog(@"Notification for %@", characteristic);
    } else {
        NSLog(@"Notification stopped for %@", characteristic);
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}

#pragma mark - Private Methods
- (void)scan
{
    [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]
                                                options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
}

- (void)cleanup
{
    if (self.peripheral.state == CBPeripheralStateDisconnected) {
        return;
    }
    
    if (self.peripheral.services != nil) {
        for (CBService *service in self.peripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_UUID]]) {
                        if (characteristic.isNotifying) {
                            [self.peripheral setNotifyValue:NO forCharacteristic:characteristic];
                            return;
                        }
                    }
                }
            }
        }
    }
    
    [self.centralManager cancelPeripheralConnection:self.peripheral];
}

@end

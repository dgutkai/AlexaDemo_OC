//
//  BleTool.m
//  QCY_SPORT
//
//  Created by lanmi on 16/6/13.
//  Copyright © 2016年 lanmi. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "BleTool.h"

#define SERVICE_UUID @"0000CAA1-0000-1000-8000-00805F9B34FB"
#define CHARACTERISTIC_UUID @"0000CAB2-0000-1000-8000-00805F9B34FB"


@implementation BleTool
{
    NSMutableDictionary *peripheralList;
    NSMutableData *bleData; // BLE交互数据流
    CBPeripheral *curPeripheral; // 当前连接的外设设备
    CBCharacteristic *curCharacteristic;
    CBCentralManager *centralManager;// 中心设置管理器

}

/**
 *  重写初始化方法
 */
+(instancetype)sharebleManager{
    static BleTool * bleManager = nil;
    //添加线程锁
    @synchronized(self){
        if (!bleManager) {
            
            bleManager = [BleTool new];

        }
    }
    
    return bleManager;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        peripheralList = [[NSMutableDictionary alloc] initWithCapacity:5];
        bleData = [[NSMutableData alloc] init];
//        timer = [NSTimer timerWithTimeInterval:5 repeats:YES block:^(NSTimer * _Nonnull timer) {
//            
//        }];
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 //if Bluetooch not power on,show alert
                                 [NSNumber numberWithBool:YES],CBCentralManagerOptionShowPowerAlertKey,
                                 //centralManager restore IdentifierKey
                                 @"babyBluetoothRestore",CBCentralManagerOptionRestoreIdentifierKey,
                                 nil];
//       centralManager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue() options:options];
       centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue() options:@{ CBCentralManagerOptionRestoreIdentifierKey: @"myCentralManagerIdentifier" }];
//        BleData = [[NSMutableData alloc] init];
        self.isConected = NO;

    }
    return self;
}

- (NSString *) name{
    return curPeripheral.name;
}
- (NSString *) UUIDString{
    return curPeripheral.identifier.UUIDString;
}
//开始搜索外围设备
-(void)scanForPeripheraWithSerivies{
    if (centralManager.state == CBManagerStatePoweredOn && self.Scan) {
        [peripheralList removeAllObjects];
        [centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
    
    }

}

- (void) setIsConected:(BOOL)isConected{
    _isConected = isConected;
    if (isConected){
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_CONNECTSUCCESS object:self];
    }else{
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DISCONNECT object:self];
        curPeripheral = nil;
        curCharacteristic = nil;
//        self.deviceType = 0;
    }
}
-(void)setScan:(BOOL)Scan
{
    if (_Scan == Scan){
        return;
    }
     _Scan = Scan;
    if (Scan) {
        [self scanForPeripheraWithSerivies];
    }else{
        [centralManager stopScan];
    }
}
//- (void)searchAndConnect:(NSString *)uuid{
//    [centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:SERVICE_UUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
//}
//开始连接外围设备
-(void)connectPeripheral:(NSString *)uuid Type:(int)dtype
{
    CBPeripheral *peripheral = peripheralList[uuid];
    if (peripheral != nil){
        if (self.isConected){
            [centralManager cancelPeripheralConnection:curPeripheral];
        }
        NSLog(@"cancelPeripheralConnection %d--%@", dtype, curPeripheral.identifier.UUIDString);
        
        [centralManager connectPeripheral:peripheral options:nil];
        
    }

}
- (void) cancelConnection{
    if (self.isConected){
        [centralManager cancelPeripheralConnection:curPeripheral];
    }
}

- (void) writeData: (NSData *)data{
    if (curPeripheral != nil && curPeripheral != nil){
        [curPeripheral writeValue:data forCharacteristic:curCharacteristic  type:CBCharacteristicWriteWithResponse];
    }
}

#pragma mark - CBCentralManagerDelegate代理
//更新设备
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBManagerStatePoweredOn:
            [self scanForPeripheraWithSerivies];
            break;
            default:
            break;
    }
}
//发现外围设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
//    NSLog(@"advertisementData=%@", advertisementData);
    if (self.Scan) {
        if (peripheralList[peripheral.identifier.UUIDString] == nil){
            [peripheralList setObject:peripheral forKey:peripheral.identifier.UUIDString];
            NSLog(@"发现到的外围设备%@",peripheral.name);
            NSString *name = peripheral.name;
            if (name == nil){
                name = @"NULL";
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_SEARCHBLE object:self userInfo:@{@"uuid": peripheral.identifier.UUIDString, @"name": name}];
        }
//        [self.delegate foundPeripheral:peripheral];
        
    }
    
}

//成功连接外围设备
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    
    NSLog(@"连接成功 %@",peripheral.name);
//    if (curPeripheral != nil){
//        [centralManager cancelPeripheralConnection:curPeripheral];
//    }
//    curPeripheral = peripheral;
    peripheral.delegate = self;
    [peripheral discoverServices:@[[CBUUID UUIDWithString:SERVICE_UUID]]];
//    [peripheral discoverServices:nil];

}
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (error) {
        NSLog(@"连接失败%@",error);
    }
    self.isConected = NO;
    
     NSLog(@"连接失败");
    
}
//断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
       if (error) {
           NSLog(@"断开连接%@",error);
        }
    self.isConected = NO;
}

#pragma mark - CBPeripheral 代理方法
//外围设备寻找到服务后
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    NSLog(@"外围设备寻找到服务");
    if(error){
        NSLog(@"外围设备寻找服务过程中发生错误，错误信息：%@",error.localizedDescription);
        return;
    }
    CBUUID *serviceUUID=[CBUUID UUIDWithString:SERVICE_UUID];
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:serviceUUID]){
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:CHARACTERISTIC_UUID]] forService:service];
            break;
        }
    }
}

//外围设备寻找到特征
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    NSLog(@"外围设备寻找到特征");
    if (error) {
        NSLog(@"外围设备寻找特征过程中发生错误，错误信息：%@",error.localizedDescription);
    }
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:CHARACTERISTIC_UUID];
    for (CBCharacteristic *characteristic in service.characteristics) {
       if ([characteristic.UUID isEqual:characteristicUUID]) {
           [peripheral setNotifyValue:YES forCharacteristic:characteristic];
           curPeripheral = peripheral;
           curCharacteristic = characteristic;
           self.isConected = YES;
           break;
        }
        
        
    }

}

//更新特征值后（调用readValueForCharacteristic:方法或者外围设备在订阅后更新特征值都会调用此代理方法）
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    if (error) {
        NSLog(@"更新特征值时发生错误，错误信息：%@",error.localizedDescription);
        return;
    }
    CBUUID *characteristicUUID = [CBUUID UUIDWithString:CHARACTERISTIC_UUID];
    if ([characteristic.UUID isEqual:characteristicUUID]) {
        NSLog(@"返回了数据%@--%@", peripheral.name, characteristic.value);
//        [bleData appendData:characteristic.value];
        [bleData setData:characteristic.value];
        int result = 0;
//        while (result != -1) {
            result = [self parseData];
            NSLog(@"Result=%d", result);
            switch (result) {
                case 0x01:
                    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_START object:self];
                    break;
                case 0x02:
                    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_STOP object:self];
                    break;
                default:
                    break;
            }
//        }
        
        
    }
}

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)state {
    
}

- (int) parseData{
    if (bleData.length < 3){
        return -1;
    }
//    BOOL isStart = NO;
    int result = -1;
    unsigned char *bs = (unsigned char *)bleData.bytes;
    result = bs[2];
    return result;
//    for (int i = 1; i < bleData.length; i++){
//        if (bs[i-1] == 0x02 && ){
//            isStart = YES;
//        }else if (i > 3){
//            if (bs[i] == 0x23 && bs[i-1] == 0x23 && bs[i-2] == 0x23){
//                result = bs[i-3];
//                NSData *dt = [bleData subdataWithRange:NSMakeRange(i+1, bleData.length - i - 1)];
//                [bleData setData:dt];
//            }
//        }
//    }
//    return result;
}

- (NSData *)createData: (int)cmd Data: (NSData *)data{
    unsigned char *resultData;
    int dataLen = 0;
    if (data == nil){
        dataLen = 5;
        resultData = (unsigned char *)malloc(sizeof(unsigned char) * dataLen);
        resultData[0] = 0xab;
        resultData[1] = cmd & 0xFF;
        resultData[2] = 0x23;
        resultData[3] = 0x23;
        resultData[4] = 0x23;
    }else{
        dataLen = 5 + (int)data.length;
        resultData = (unsigned char *)malloc(sizeof(unsigned char) * dataLen);
        resultData[0] = 0xab;
        resultData[1] = cmd & 0xFF;
        memcpy(resultData + 2, data.bytes, data.length);
        resultData[dataLen - 3] = 0x23;
        resultData[dataLen - 2] = 0x23;
        resultData[dataLen - 1] = 0x23;
    }
    
    return [NSData dataWithBytes:resultData length:dataLen];
}
@end

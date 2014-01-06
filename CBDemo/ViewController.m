//
//  ViewController.m
//  CBDemo
//
//  Created by Sergio on 25/01/12.
//  Copyright (c) 2012 Sergio. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CBPeripheral.h>
#import "NSData+Conversion.h"
#import "CBUUID+StringExtraction.h"
#import "MBProgressHUD.h"
@interface ViewController()

@property (nonatomic, strong) NSTimer * timer;

@end

@implementation ViewController{
    BlueToothMe *instance;
    CBPeripheral * printerPeripheral;
    
    IBOutlet UISegmentedControl * _modeSegament;
    
    IBOutlet UISlider * _maxCurrentSlider;
    IBOutlet UISlider * _currentOffsetSlider;
    IBOutlet UISlider * _currentRiseFallTimeSlider;
    IBOutlet UISlider * _plusWidthSlider;
    IBOutlet UISlider * _plusPeriodSlider;
    IBOutlet UISlider * _timeInActiveModeSlider;
    
    IBOutlet UIScrollView * _scrollView;
    
    MBProgressHUD * _HUD;
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _scrollView.contentSize = CGSizeMake(320, 680);
    
    _modeSegament.enabled = NO;
    
   
    self.navigationController.navigationBar.hidden = YES;
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
//target:self
//                                                                                          action:@selector(scanBluetooth)];
    
    instance = [BlueToothMe shared];
    [instance setDelegate:self];
    
    NSArray *characteristics = [NSArray arrayWithObjects:[CBUUID UUIDWithString:@"2A1E"], 
                                                         [CBUUID UUIDWithString:@"2A1C"],
                                                         [CBUUID UUIDWithString:@"2A21"], nil];
    
    [instance setCharacteristics:characteristics forServiceCBUUID:@"1809"];
    [instance setLetWriteDataCBUUID:[NSArray arrayWithObject:@"1809"]];
    
    characteristics = [NSArray arrayWithObject:[CBUUID UUIDWithString:@"2A29"]];
                       
    [instance setCharacteristics:characteristics forServiceCBUUID:@"180A"];
    
    [instance hardwareResponse:^(CBPeripheral *peripheral, BLUETOOTH_STATUS status, NSError *error) {
        
        if (status == BLUETOOTH_STATUS_CONNECTED)
        {
            NSLog(@"connected!");
        }
        else if (status == BLUETOOTH_STATUS_FAIL_TO_CONNECT)
        {
            NSLog(@"fail to connect!");
        }
        else
        {
            NSLog(@"disconnected!");
        }
        
        NSLog(@"CBUUID: %@, ERROR: %@", (NSString *)peripheral.UUID, error.localizedDescription);
    }];
    
    [instance startScan];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadTableView)
                                                 name:kNewBlueToothPeripheralDiscoveredNotification
                                               object:nil];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideHUD)
                                                 name:kBlueToothPeripheralDisconnectedNotification
                                               object:nil];
}
- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kNewBlueToothPeripheralDiscoveredNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kBlueToothPeripheralDisconnectedNotification object:nil];
    
}

- (void)hideHUD
{
    if (_HUD) {
        [_HUD hide:YES];
    }
}

- (void)scanBluetooth
{
    [instance startScan];
    [self reloadTableView];
}

- (void)hardwareDidNotifyBehaviourOnCharacteristic:(CBCharacteristic *)characteristic
                                    withPeripheral:(CBPeripheral *)peripheral
                                             error:(NSError *)error
{
    NSLog(@"hardwareDidNotifyBehaviourOnCharacteristic:  %@ %@", [[characteristic UUID] representativeString],  [characteristic value]);

}

- (void)peripheralDidWriteChracteristic:(CBCharacteristic *)characteristic 
                         withPeripheral:(CBPeripheral *)peripheral 
                              withError:(NSError *)error
{

//    if (error)
    {
        NSLog(@"peripheralDidWriteChracteristic:  %@ %@", [[characteristic UUID] representativeString],  [characteristic value]);
 
        NSLog(@"error: %@", [error localizedDescription]);
        

        
        if ( error && _HUD) {
            [_HUD hide:YES];
        }
        
//        [self readFWUpdateControlCharacteristic:nil];
    }

}

NSString * const MODE[] = { @"Off", @"Paired", @"ACTIVE_CONT", @"ACTIVE_PULSE", @"ACTIVE_SINUS",
@"ACTIVE_NOISE", @"ACTIVE_FAKE", @"ERROR_ZERO", @"ERROR_OVF"};

NSString * const ELECTRODES_MODE[] = {@"Off", @"Negative", @"Positive"};

NSString * const FW_UPDATE_CONTROL[] = {@"FW_IDLE", @"FW_START", @"Positive"};

- (void)peripheralDidReadChracteristic:(CBCharacteristic *)characteristic 
                        withPeripheral:(CBPeripheral *)peripheral 
                             withError:(NSError *)error
{
//    NSLog(@"peripheralDidReadChracteristic: %@ %@   %@",characteristic.service, peripheral.name,    [characteristic value]);
    
//        uint8_t alarmValue  = 0;
//    /* get the value for the alarm */
//    [[characteristic value] getBytes:&alarmValue length:sizeof (alarmValue)];
//    
//    NSLog(@"value!  0x%x", alarmValue);
    
    if (error) {
        if (_HUD) {
            [_HUD hide:YES];
        }
    }
    
    NSString * characteristicName = @"";

    NSString * uuidString = [[characteristic UUID] representativeString];
//    NSLog(@"uuidString: %@", uuidString);
    characteristicName = [instance.characteristicMeta valueForKey:uuidString][@"name"];
   
    id unit = [instance.characteristicMeta valueForKey:uuidString][@"unit"];
    if (unit == nil || unit == [NSNull null]) {
        unit = @"";
    }
    NSString * hexString = [[characteristic value] hexadecimalString];

    if ([instance.characteristicMeta valueForKey:uuidString][@"dec"])
    {
        int dec = [[self hexToDec:hexString] intValue];
        
        
//        NSLog(@"Dec value, %d is sccessfully scanned.", dec);
        
        if ([uuidString isEqualToString:CHARACTERISTIC_MODE]) {
            self.textView.text = [self.textView.text stringByAppendingFormat:@"%@: %@\n", characteristicName, MODE[dec]] ;
            
            _modeSegament.selectedSegmentIndex = dec;
            _modeSegament.enabled = YES;
        }else{
        
             
            self.textView.text = [self.textView.text stringByAppendingFormat:@"%@: %d %@\n", characteristicName, dec, unit] ;
            
            if ([uuidString isEqualToString:CHARACTERISTIC_MAX_CURRENT]) {
                _maxCurrentSlider.value = dec;
            }else if ([uuidString isEqualToString:CHARACTERISTIC_CURRENT_OFFSET]) {
                _currentOffsetSlider.value = dec;
            }else if ([uuidString isEqualToString:CHARACTERISTIC_CURRENT_RISE_FALL_TIME]) {
                _currentRiseFallTimeSlider.value = dec;
            }else if ([uuidString isEqualToString:CHARACTERISTIC_PULSE_WIDTH]) {
                _plusWidthSlider.value = dec;
            }else if ([uuidString isEqualToString:CHARACTERISTIC_PULSE_PERIOD]) {
                _plusPeriodSlider.value = dec;
            }else if ([uuidString isEqualToString:CHARACTERISTIC_TIME_IN_ACTIVE_MODE]) {
                _timeInActiveModeSlider.value = dec;
            }
        }
        
        
    }else if ([instance.characteristicMeta valueForKey:uuidString][@"ascii"])
    {
   
        self.textView.text = [self.textView.text stringByAppendingFormat:@"%@: %@ \n", characteristicName, [NSString stringWithUTF8String:[[characteristic value] bytes]] ] ;
    }else{
        
         if ([uuidString isEqualToString:CHARACTERISTIC_ELECTRODES_MODE]) {
             NSString * most = [hexString substringToIndex:1];
             
             NSString * least = [hexString substringFromIndex:1];
             
             NSString * left_mode = ELECTRODES_MODE[[least intValue]];
             NSString * right_mode = ELECTRODES_MODE[[most intValue]];
             
//             Least nibble - left electrode
//             Most nibble - right electrode
             
            self.textView.text = [self.textView.text stringByAppendingFormat:@"%@: left nibble - %@, right nibble - %@\n", characteristicName, left_mode, right_mode] ;
             
         }else if ([uuidString isEqualToString:CHARACTERISTIC_PIN_CODE]) {
            self.textView.text = [self.textView.text stringByAppendingFormat:@"%@: %@\n", characteristicName, [hexString substringFromIndex:2]] ; //pin code max 999999, last 6 bits only
        
        
         }else {
             
             if ([uuidString isEqualToString:CHARACTERISTIC_FW_DATA_BUFFER]) {
                 //
             }else{
                 self.textView.text = [self.textView.text stringByAppendingFormat:@"%@: %@\n", characteristicName, hexString] ;
             }
             
             if ([uuidString isEqualToString:CHARACTERISTIC_FW_UPDATE_CONTROL]) {
 
                 NSLog(@"CHARACTERISTIC_FW_UPDATE_CONTROL result: %@", hexString);
                 
                 if ([hexString isEqualToString:@"0001"]) {
            
                 }
                 if ([hexString isEqualToString:@"0003"]) {
                     
                 }

                 
                 if ([hexString isEqualToString:@"0004"] || [hexString isEqualToString:@"0005"]) {
                     
                    
                     // CRC OK or ERROR
                     if ([hexString isEqualToString:@"0004"]) {
                         // OK, TODO: write 0006, burn signal
                     }
                     
                     if ([hexString isEqualToString:@"0005"]) {
                         // ERROR.
                         NSLog(@"CRC ERROR");
                     }
                     
                     if (_HUD) {
                         [_HUD hide:YES];
                     }
                 }
             }
         }
    }
    
    
}
- (NSString *)hexToAscii:(NSString*)hexString
{
    NSMutableString * newString = [NSMutableString string];
    
    NSArray * components = [hexString componentsSeparatedByString:@" "];
    for ( NSString * component in components ) {
        int value = 0;
        sscanf([component cStringUsingEncoding:NSASCIIStringEncoding], "%x", &value);
        [newString appendFormat:@"%c", (char)value];
    }
    
    NSLog(@"%@", newString);
    return newString;
}
- (NSNumber *)hexToDec:(NSString*)hexString
{
    NSScanner *scan = [NSScanner scannerWithString:hexString];
    
    unsigned int dec;
    
    if ([scan scanHexInt:&dec])
    {
//        NSLog(@"Dec value, %d is sccessfully scanned.", dec);
        return [NSNumber numberWithInt:dec];
    }
    else
        NSLog(@"No dec value is scanned.");
    
    return nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)doSomething:(id)sender
{
//    [self writeHighAlarmTemperature:1];
}

- (void)reloadTableView
{
    [self.tableView reloadData];
}

- (void)handleDeviceConnected
{
    NSLog(@"device connected!");
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDeviceDisconnected)
                                                 name:kBlueToothPeripheralDisconnectedNotification
                                               object:printerPeripheral];
}


- (void)handleDeviceDisconnected
{
    NSLog(@"device disconnected!!");
    
 
 
    if (printerPeripheral)
    {
        [printerPeripheral setDelegate:nil];
        printerPeripheral = nil;
    }
    
    [self.printView removeFromSuperview];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kBlueToothPeripheralConnectedNotification object:printerPeripheral];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kBlueToothPeripheralDisconnectedNotification object:printerPeripheral];
}

//- (IBAction)print:(id)sender
//{
//    [instance sendDataToDevice:self.textView.text
//                onCharacteristic:CHARACTERISTIC_ACTUAL_CURRENT];
//}

- (IBAction)readDeviceInfo:(id)sender
{
    [instance readDeviceInfoCharacteristics];
}

- (IBAction)readValue:(id)sender
{
    [instance readValueFromDeviceOnCharacteristic:CHARACTERISTIC_BATTERY_LEVEL];
    
    [instance readValueFromDeviceOnCharacteristic:CHARACTERISTIC_ACTUAL_CURRENT];
    
    [instance readValueFromDeviceOnCharacteristic:CHARACTERISTIC_MODE];

    [instance readValueFromDeviceOnCharacteristic:CHARACTERISTIC_ELECTRODES_MODE];

    [instance readValueFromDeviceOnCharacteristic:CHARACTERISTIC_TIME_IN_ACTIVE_MODE];

    [instance readValueFromDeviceOnCharacteristic:CHARACTERISTIC_FW_UPDATE_CONTROL];
    
    [instance readValueFromDeviceOnCharacteristic:CHARACTERISTIC_FW_DATA_BUFFER];

    [instance readValueFromDeviceOnCharacteristic:CHARACTERISTIC_PIN_CODE];

    [instance readValueFromDeviceOnCharacteristic:CHARACTERISTIC_MAX_CURRENT];

    
    [instance readValueFromDeviceOnCharacteristic:CHARACTERISTIC_CURRENT_OFFSET];
    [instance readValueFromDeviceOnCharacteristic:CHARACTERISTIC_CURRENT_RISE_FALL_TIME];
    [instance readValueFromDeviceOnCharacteristic:CHARACTERISTIC_PULSE_WIDTH];
    [instance readValueFromDeviceOnCharacteristic:CHARACTERISTIC_PULSE_PERIOD];
    
}

- (IBAction)finish:(id)sender
{

    if (printerPeripheral) {
        [instance disconnectPeripheral:printerPeripheral];
    }
    
    
//    exit(0);
    
}
#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return instance.dicoveredPeripherals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (!cell) {
       cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.detailTextLabel.numberOfLines = 0;
    
    }
    
    CBPeripheral * device = instance.dicoveredPeripherals[indexPath.row];
    cell.textLabel.text = device.name;

    cell.detailTextLabel.text = [NSString stringWithFormat:@"UUID: %@\n RSSI: %d \nConnected: %d",
                                 device.UUID,
                                 [device.RSSI integerValue],
                                 device.isConnected];
    return cell;

}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    printerPeripheral = instance.dicoveredPeripherals[indexPath.row];
    
    [instance connectPeripheral:printerPeripheral];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDeviceConnected)
                                                 name:kBlueToothPeripheralConnectedNotification
                                               object:printerPeripheral];
    

    
    [self.view addSubview:self.printView];
}

- (IBAction)onModeChanged:(id)sender
{
    UISegmentedControl * modeSwitch = (UISegmentedControl*)sender;

    int modeToSet = modeSwitch.selectedSegmentIndex;
    NSLog(@"modeToSet: %d", modeToSet);
    NSData * dataToSend = [BlueToothMe hexToData:([NSString stringWithFormat:@"0x%02x", modeToSet])];
    
    unsigned char buffer;
    
    [dataToSend getBytes: &buffer range: NSMakeRange( 1, 1 )];
    
    NSData * oneByteData = [BlueToothMe decToOneByteData:modeToSet]; //[NSData dataWithBytes:&buffer length:1];
    
    
    [instance sendDataToDevice:oneByteData
                onCharacteristic:CHARACTERISTIC_MODE];

}



NSData *dataByIntepretingHexString(NSString *hexString) {
    char const *chars = hexString.UTF8String;
    NSUInteger charCount = strlen(chars);
    if (charCount % 2 != 0) {
        return nil;
    }
    NSUInteger byteCount = charCount / 2;
    uint8_t *bytes = malloc(byteCount);
    for (int i = 0; i < byteCount; ++i) {
        unsigned int value;
        sscanf(chars + i * 2, "%2x", &value);
        bytes[i] = value;
    }
    return [NSData dataWithBytesNoCopy:bytes length:byteCount freeWhenDone:YES];
}


- (IBAction)sliderValueChanged:(id)sender
{
    UISlider * slider = (UISlider*)sender;
    NSLog(@"new value: %f", slider.value);
    
 
    
    NSData * data ;
    
    switch ([sender tag]) {
        case 10:
             data = [BlueToothMe decToOneByteData:(int)slider.value];
            
            [instance sendDataToDevice:data
                      onCharacteristic:CHARACTERISTIC_MAX_CURRENT];
            break;
        
        case 20:
             data = [BlueToothMe decToOneByteData:(int)slider.value];
            [instance sendDataToDevice:data
                      onCharacteristic:CHARACTERISTIC_CURRENT_OFFSET];
            break;
            
        case 30:
             data = [BlueToothMe decToOneByteData:(int)slider.value];
            [instance sendDataToDevice:data
                      onCharacteristic:CHARACTERISTIC_CURRENT_RISE_FALL_TIME];
            break;

        case 40:
             data = [BlueToothMe decToTwoByteData:(int)slider.value];
            [instance sendDataToDevice:data
                      onCharacteristic:CHARACTERISTIC_PULSE_WIDTH];
            break;
            
        case 50:
            data = [BlueToothMe decToTwoByteData:(int)slider.value];
            [instance sendDataToDevice:data
                      onCharacteristic:CHARACTERISTIC_PULSE_PERIOD];
            break;
            
            
        case 60:
            data = [BlueToothMe decToTwoByteData:(int)slider.value];
            [instance sendDataToDevice:data
                      onCharacteristic:CHARACTERISTIC_TIME_IN_ACTIVE_MODE];
            break;
            
            
            
        default:
            break;
    }

}

/*
 
 Value	Perm	Name	Description
 0	W	FW_IDLE	No FW update process
 1	R/W	FW_START	Start of FW update process
 2	R	FW_DATA	FW data transmission
 3	R/W	FW_END_DATA	End of FW data transmission
 4	R	FW_CRC_OK	Calculated CRC value is true
 5	R	FW_CRC_ERROR	Calculated CRC value is false
 6	R/W	FW_BURN	Start of flash update process
 
 */

enum{
    FW_IDLE = 0,
    FW_START,
    FW_DATA,
    FW_END_DATA,
    FW_CRC_OK,
    FW_CRC_ERROR,
    FW_BURN
}FW_UPDATE_CMD;

- (IBAction)updateFirmWare:(id)sender
{
    if (!_HUD) {
        _HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _HUD.labelText = @"Writing to buffer";

    }
    
    // send start signal
 
    _HUD.labelText = @"Send start signal";
    
    NSData * data = [BlueToothMe decToTwoByteData:FW_START];
    [instance sendDataToDevice:data
              onCharacteristic:CHARACTERISTIC_FW_UPDATE_CONTROL];
    
    [self readFWUpdateControlCharacteristic:nil];
 
    
     [self writeFWData];
}

- (void)writeFWData
{
    [_HUD show:YES];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        // Do something...
        
        [BlueToothMe readFirmwareFileWithBlock:^(NSData *dataToSend, BOOL finished) {
            //
            if (finished) {
                //            [_HUD hide:YES];
                //            return;
                
                // send end data signal
                
                _HUD.labelText = @"Send end data signal";
                NSData * data = [BlueToothMe decToTwoByteData:FW_END_DATA];
                [instance sendDataToDevice:data
                          onCharacteristic:CHARACTERISTIC_FW_UPDATE_CONTROL];
                
                
                
                _HUD.labelText = @"Checking data CRC";
                _HUD.detailsLabelText = @"This should take about 20-50 seconds.";
                
                
                
                
            }else{
                [instance sendDataToDevice:dataToSend
                          onCharacteristic:CHARACTERISTIC_FW_DATA_BUFFER];
                
            }
            
            
        }];
        
        //// done writing fw data, checking crc ok / error signla every 10s.
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(readFWUpdateControlCharacteristic:) userInfo:nil repeats:YES];
            

        });
    });

    

}

- (void)readFWUpdateControlCharacteristic:(NSTimer*)timer
{
    NSLog(@"reading readFWUpdateControlCharacteristic");
     [instance readValueFromDeviceOnCharacteristic:CHARACTERISTIC_FW_UPDATE_CONTROL];
}

@end

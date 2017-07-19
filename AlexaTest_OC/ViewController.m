//
//  ViewController.m
//  AlexaTest_OC
//
//  Created by lanmi on 2017/6/13.
//  Copyright © 2017年 lanmi. All rights reserved.
//

#import "ViewController.h"
#import <LoginWithAmazon/LoginWithAmazon.h>
#import "AlexaViewController.h"
#import "AmazonProxy.h"
#import "AmazonToken.h"
#import "BleTool.h"
@interface ViewController () <AIAuthenticationDelegate, UITableViewDelegate, UITableViewDataSource>
{
    AmazonProxy *lwa;
    BleTool *bleTool;
    NSMutableArray *BLEDevices;
}
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (weak, nonatomic) IBOutlet UIButton *logoutBtn;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UITableView *bleTableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    lwa = [AmazonProxy sharedInstance];
    // Do any additional setup after loading the view, typically from a nib.
    bleTool = [BleTool sharebleManager];
    bleTool.Scan = YES;
    BLEDevices = [[NSMutableArray alloc] initWithCapacity:10];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchBleNotification:) name:NOTIFICATION_SEARCHBLE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectedNotification:) name:NOTIFICATION_CONNECTSUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disconnectNotification:) name:NOTIFICATION_DISCONNECT object:nil];
}

- (void)viewDidAppear:(BOOL)animated{
    if (bleTool.isConected){
        [lwa loginWithDelegate:self];
    }else{
        self.infoLabel.text = @"请先连接蓝牙设备。";
    }
//    [self loginAmazon:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginAmazon:(id)sender {
//    if (bleTool.isConected){
        [lwa loginWithDelegate:self];
//    }else{
//        self.infoLabel.text = @"请先连接蓝牙设备。";
//    }
}
- (IBAction)logoutAmazon:(id)sender {
    [lwa logoutWithDelegate:self];
}

- (void)requestDidSucceed:(APIResult *)apiResult{
    switch (apiResult.api) {
        case kAPIAuthorizeUser:
            [lwa getAccessTokenWithDelegate:self];
            break;
        case kAPIClearAuthorizationState:
            
            break;
        case kAPIGetAccessToken:
        {
            [AmazonToken sharedInstance].loginWithAmazonToken = (NSString *)apiResult.result;
            AlexaViewController *alexaController = [[AlexaViewController alloc] init];
            [self presentViewController:alexaController animated:YES completion:nil];
        }
            break;
        default:
            return;
    }
}
- (void)requestDidFail:(APIError *)errorResponse{
    NSLog(@"errorResponse%@", errorResponse.error.message);
}

- (void) searchBleNotification: (NSNotification *)notification{
    NSString *name = notification.userInfo[@"name"];
    NSString *uuid = notification.userInfo[@"uuid"];
    [BLEDevices addObject:@{@"name":name, @"uuid":uuid}];
    [_bleTableView reloadData];
    NSLog(@"%@-%@", notification.userInfo[@"name"], notification.userInfo[@"uuid"]);
}

- (void) connectedNotification: (NSNotification *)notification{
    NSLog(@"connectedNotification %@", bleTool.name);
    self.infoLabel.text = [NSString stringWithFormat:@"%@连接成功。", bleTool.name];
}
- (void) disconnectNotification: (NSNotification *)notification{
    self.infoLabel.text = [NSString stringWithFormat:@"%@连接失败。", bleTool.name];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return BLEDevices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.text = BLEDevices[indexPath.row][@"name"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [bleTool connectPeripheral:BLEDevices[indexPath.row][@"uuid"] Type:3];
}
@end

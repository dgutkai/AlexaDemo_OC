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
@interface ViewController () <AIAuthenticationDelegate>
{
    AmazonProxy *lwa;
}
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (weak, nonatomic) IBOutlet UIButton *logoutBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    lwa = [AmazonProxy sharedInstance];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginAmazon:(id)sender {
    [lwa loginWithDelegate:self];
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
@end

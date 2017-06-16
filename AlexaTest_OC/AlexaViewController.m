//
//  AlexaViewController.m
//  AlexaTest_OC
//
//  Created by lanmi on 2017/6/13.
//  Copyright © 2017年 lanmi. All rights reserved.
//

#import "AlexaViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AlexaVoiceClient.h"
#import "Settings.h"
@interface AlexaViewController ()<AVAudioPlayerDelegate, AVAudioRecorderDelegate>
{
    AVAudioSession *audioSession;
    AVAudioRecorder *audioRecorder;
    AVAudioPlayer *audioPlayer;
    BOOL isRecording;
    AlexaVoiceClient *avsClient;
    NSString *speakToken;
    
    
}
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@end

@implementation AlexaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    audioSession = [AVAudioSession sharedInstance];
    isRecording = NO;
    avsClient = [[AlexaVoiceClient alloc] init];
    avsClient.pingHandler = ^(BOOL isSuccess){
        __weak AlexaViewController *weekSelf = self;
        dispatch_sync(dispatch_get_main_queue(), ^{
            if(isSuccess){
                weekSelf.infoLabel.text = @"Ping Success";
                NSLog(@"Ping Success");
            }else{
                weekSelf.infoLabel.text = @"Ping Error";
                NSLog(@"Ping ERROR");
            }
        });
    };
    avsClient.syncHandler = ^(BOOL isSuccess){
        __weak AlexaViewController *weekSelf = self;
        dispatch_sync(dispatch_get_main_queue(), ^{
            if(isSuccess){
                weekSelf.infoLabel.text = @"Sync Success";
                NSLog(@"Sync Success");
            }else{
                weekSelf.infoLabel.text = @"Sync Error";
                NSLog(@"Sync ERROR");
            }
        });
    };
    avsClient.directiveHandler = ^(NSArray *directiveData){
        __weak AlexaViewController *weekSelf = self;
        for (NSDictionary *item in directiveData) {
            NSString *contentType = (NSString *)item[@"contentType"];
            NSData *data = (NSData *)item[@"data"];
            if ([contentType isEqualToString:@"application/json"]){
                NSDictionary *jsonData = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                NSDictionary *directiveJson = (NSDictionary *)jsonData[@"directive"];
                NSDictionary *header = (NSDictionary *)directiveJson[@"header"];
                if ([header[@"name"] isEqualToString:@"Speak"]){
                    NSDictionary *payload = (NSDictionary *)directiveJson[@"payload"];
                    speakToken = payload[@"token"];
                }
            }
        }
        for (NSDictionary *item in directiveData) {
            NSString *contentType = (NSString *)item[@"contentType"];
            NSData *data = (NSData *)item[@"data"];
            if ([contentType isEqualToString:@"application/octet-stream"]){
                dispatch_sync(dispatch_get_main_queue(), ^{
                    weekSelf.infoLabel.text = @"Alexa is speaking";
                });
                [avsClient sendEventNamespace:@"SpeechSynthesizer" Name:@"SpeechStarted" Token:speakToken];
                [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionAllowBluetoothA2DP error:nil];
                audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
                audioPlayer.delegate = self;
                [audioPlayer prepareToPlay];
                [audioPlayer play];
            }
        }
    };
    // Do any additional setup after loading the view from its nib.
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)talkAction:(id)sender {
    [avsClient ping];
}
- (IBAction)downchannelAction:(id)sender {
}
- (IBAction)talk2Action:(id)sender {
    if (isRecording){
        [audioRecorder stop];
        isRecording = NO;
        NSLog(@"AudioURL = %@", audioRecorder.url.absoluteString);
        [avsClient postRecordingWithAudioData:[NSData dataWithContentsOfURL:audioRecorder.url]];
        
    }else{
        [self prepareAudioSession];
        [audioRecorder prepareToRecord];
        [audioRecorder record];
        isRecording = YES;
        
    }
}
- (IBAction)wakeAction:(id)sender {
    
}

- (void) prepareAudioSession{
    NSURL *directory = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
    NSURL *fileURL = [directory URLByAppendingPathComponent:[Settings TEMP_FILE_NAME]];
    audioRecorder = [[AVAudioRecorder alloc] initWithURL:fileURL settings:[Settings RECORDING_SETTING] error:nil];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionAllowBluetoothA2DP error:nil];
}
@end

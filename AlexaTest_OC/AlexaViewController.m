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
    NSTimer *timer;
    int lowCount;
}
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *voiceViewImg;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progress;

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
        dispatch_sync(dispatch_get_main_queue(), ^{
            weekSelf.progress.hidden = YES;
            weekSelf.voiceViewImg.hidden = NO;
        });
        if (directiveData == nil){
            return;
        }
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
    
    [self prepareAudioSession];
    //设置定时检测
//    timer = [NSTimer timerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
//        [audioRecorder updateMeters];//刷新音量数据
//        //获取音量的平均值  [recorder averagePowerForChannel:0];
//        //音量的最大值  [recorder peakPowerForChannel:0];
//        
//        double lowPassResults = pow(10, (0.05 * [audioRecorder peakPowerForChannel:0]));
//        NSLog(@"%lf",lowPassResults);
//    }];
    
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
        timer.fireDate = [NSDate distantFuture];
    }else{
        
        [audioRecorder prepareToRecord];
        [audioRecorder record];
        isRecording = YES;
        if (timer){
            timer.fireDate = [NSDate distantPast];
        }else{
            timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(detectionVoice) userInfo:nil repeats:YES];
        }
    }
}
- (IBAction)wakeAction:(id)sender {
    
}

- (void) prepareAudioSession{
    NSURL *directory = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
    NSURL *fileURL = [directory URLByAppendingPathComponent:[Settings TEMP_FILE_NAME]];
    audioRecorder = [[AVAudioRecorder alloc] initWithURL:fileURL settings:[Settings RECORDING_SETTING] error:nil];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionAllowBluetoothA2DP error:nil];
    audioRecorder.meteringEnabled = YES;
    audioRecorder.delegate = self;
}

//刷新上次录音
- (void)detectionVoice
{
    if (!audioRecorder || !isRecording){
        lowCount = 0;
        return;
    }
    [audioRecorder updateMeters];//刷新音量数据
    //获取音量的平均值  [recorder averagePowerForChannel:0];
    //音量的最大值  [recorder peakPowerForChannel:0];
    
    double lowPassResults = pow(10, (0.05 * [audioRecorder peakPowerForChannel:0]));
    NSLog(@"%lf",lowPassResults);
    if (lowPassResults < 0.009 && lowCount >= 1){
        lowCount++;
        if (lowCount > 20){
            lowCount = 0;
            self.voiceViewImg.hidden = YES;
            [self.progress setHidden:NO];
            [self talk2Action:nil];
            
        }
    }else{
        lowCount = 1;
    }
    
    if (0<lowPassResults<=0.06) {
        [self.voiceViewImg setImage:[UIImage imageNamed:@"record_animate_01.png"]];
    }else if (0.06<lowPassResults<=0.13) {
        [self.voiceViewImg setImage:[UIImage imageNamed:@"record_animate_02.png"]];
    }else if (0.13<lowPassResults<=0.20) {
        [self.voiceViewImg setImage:[UIImage imageNamed:@"record_animate_03.png"]];
    }else if (0.20<lowPassResults<=0.27) {
        [self.voiceViewImg setImage:[UIImage imageNamed:@"record_animate_04.png"]];
    }else if (0.27<lowPassResults<=0.34) {
        [self.voiceViewImg setImage:[UIImage imageNamed:@"record_animate_05.png"]];
    }else if (0.34<lowPassResults<=0.41) {
        [self.voiceViewImg setImage:[UIImage imageNamed:@"record_animate_06.png"]];
    }else if (0.41<lowPassResults<=0.48) {
        [self.voiceViewImg setImage:[UIImage imageNamed:@"record_animate_07.png"]];
    }else if (0.48<lowPassResults<=0.55) {
        [self.voiceViewImg setImage:[UIImage imageNamed:@"record_animate_08.png"]];
    }else if (0.55<lowPassResults<=0.62) {
        [self.voiceViewImg setImage:[UIImage imageNamed:@"record_animate_09.png"]];
    }else if (0.62<lowPassResults<=0.69) {
        [self.voiceViewImg setImage:[UIImage imageNamed:@"record_animate_10.png"]];
    }else if (0.69<lowPassResults<=0.76) {
        [self.voiceViewImg setImage:[UIImage imageNamed:@"record_animate_11.png"]];
    }else if (0.76<lowPassResults<=0.83) {
        [self.voiceViewImg setImage:[UIImage imageNamed:@"record_animate_12.png"]];
    }else if (0.83<lowPassResults<=0.9) {
        [self.voiceViewImg setImage:[UIImage imageNamed:@"record_animate_13.png"]];
    }else {
        [self.voiceViewImg setImage:[UIImage imageNamed:@"record_animate_14.png"]];
    }
    
}


@end

//
//  ViewController.m
//  Hackmap
//
//  Created by Timothy Tong on 2014-09-20.
//  Copyright (c) 2014 Timothy Tong. All rights reserved.
//

#import "ViewController.h"
#import <MyoKit/MyoKit.h>

@interface ViewController ()
@property(nonatomic, readwrite)BOOL leftAlreadyAlerted;
@property(nonatomic, readwrite)BOOL rightAlreadyAlerted;
@property(nonatomic, readwrite)BOOL leftConnected;
@property(nonatomic, readwrite)BOOL rightConnected;
@property(nonatomic, readwrite)NSUUID *leftMyo;
@property(nonatomic, readwrite)NSUUID *rightMyo;
@property(nonatomic, strong)UILabel *leftLabel;
@property(nonatomic, strong)UILabel *rightLabel;
@property(nonatomic, strong)TLMPose *currentPose;
@property(nonatomic, strong)UIAlertView *alertView;
@property(nonatomic, strong)UIButton *gotoMapsButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.leftAlreadyAlerted = NO;
    self.rightAlreadyAlerted = NO;
    self.leftConnected = NO;
    self.rightConnected = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *connectBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width/2-150, self.view.frame.size.height/2-20, 300, 40)];
    UILabel *connectBtnLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 300, 40)];
    connectBtnLabel.text = @"CONNECT";
    connectBtnLabel.textAlignment = NSTextAlignmentCenter;
    connectBtnLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:50];
    connectBtnLabel.textColor = [UIColor blackColor];
    [connectBtn addSubview:connectBtnLabel];
    [self.view addSubview:connectBtn];
    [connectBtn addTarget:self action:@selector(connect:) forControlEvents:UIControlEventTouchUpInside];
    
    //LABELS
    self.leftLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, self.view.frame.size.height/2 + 50, self.view.frame.size.width-40, 100)];
    self.leftLabel.text = @"LEFT: WAITING FOR CONNECTION";
    self.leftLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:35.0];
    self.leftLabel.lineBreakMode = NSLineBreakByCharWrapping;
    self.leftLabel.numberOfLines = 0;
    [self.view addSubview:self.leftLabel];
    
    self.rightLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, self.view.frame.size.height/2 + 170, self.view.frame.size.width-40, 100)];
    self.rightLabel.text = @"RIGHT: WAITING FOR CONNECTION";
    self.rightLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:35.0];
    self.rightLabel.lineBreakMode = NSLineBreakByCharWrapping;
    self.rightLabel.numberOfLines = 0;
    [self.view addSubview:self.rightLabel];
    
    //GO TO MAPS BUTTON
    self.gotoMapsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.gotoMapsButton.frame = CGRectMake(self.view.frame.size.width-50, self.view.frame.size.height-30, 50, 30);
    UILabel *gotoMapsLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 50, 30)];
    gotoMapsLabel.text = @"GO TO MAPS";
    gotoMapsLabel.textAlignment = NSTextAlignmentCenter;
    gotoMapsLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:30];
    [self.gotoMapsButton addSubview:gotoMapsLabel];
    self.gotoMapsButton.alpha = 0;
    [self.gotoMapsButton addTarget:self action:@selector(gotoMaps:) forControlEvents:UIControlEventTouchUpInside];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didConnectDevice:)
                                                 name:TLMHubDidConnectDeviceNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didDisconnectDevice:)
                                                 name:TLMHubDidDisconnectDeviceNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceivePoseChange:)
                                                 name:TLMMyoDidReceivePoseChangedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRecognizeArm:)
                                                 name:TLMMyoDidReceiveArmRecognizedEventNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didLoseArm:)
                                                 name:TLMMyoDidReceiveArmLostEventNotification
                                               object:nil];
    
    // Do any additional setup after loading the view, typically from a nib.
}
//- (void)didDisconnected:(NSNotification *)notification{
//    NSLog(@"Did disconnected");
//}

- (void)gotoMaps:(id)sender{
    NSLog(@"GOING TO MAPS");
    if (self.rightMyo!=nil && self.leftMyo!=nil) {
        NSLog(@"Two hand gestures available");
    }
    else{
        [self alertWithTitle:@"Notice" andContent:@"Using single hand gestures" andCancelButton:@"OK"];
    }
}

- (void)didConnectDevice:(NSNotification *)notification{
    NSLog(@"Did connect device");
    NSMutableString *resultString = [NSMutableString stringWithFormat:@""];
    NSArray *myosArray = [TLMHub sharedHub].myoDevices;
    TLMMyo *myo = [myosArray lastObject];
    [resultString appendString:[NSString stringWithFormat:@"%@",myo.identifier]];
    if (!self.leftConnected) {
        if (!self.leftAlreadyAlerted) {
            [self.alertView dismissWithClickedButtonIndex:0 animated:NO];
            [self alertWithTitle:@"Myo connected" andContent:@"Please perform the setup gesture."andCancelButton:@"OK"];
            self.leftAlreadyAlerted = YES;
        }
    }
    else if (!self.rightConnected){
        if (!self.rightAlreadyAlerted) {
            [self.alertView dismissWithClickedButtonIndex:0 animated:NO];
            [self alertWithTitle:@"Myo connected" andContent:@"Please perform the setup gesture."andCancelButton:@"OK"];
        }
    }
}

- (void)didDisconnectDevice:(NSNotification *)notification {
    NSArray *array = [TLMHub sharedHub].myoDevices;
    NSString *disconnectedArm;
    BOOL deviceStillConnected = false;
    if (array.count == 0) {
        self.leftMyo = nil;
        self.leftAlreadyAlerted = NO;
        self.leftLabel.text = @"LEFT: WAITING FOR CONNECTION";
        self.rightMyo = nil;
        self.rightAlreadyAlerted = NO;
        self.rightLabel.text = @"RIGHT: WAITING FOR CONNECTION";
    }
    for (int i = 0; i < array.count; i++) {
        NSLog(@"Running loop #%d",i);
        TLMMyo *myo = [array objectAtIndex:i];
        if (myo.identifier == self.leftMyo || myo.identifier == self.rightMyo) {
            deviceStillConnected = true;
        }
        else{
            if (myo.identifier == self.leftMyo) {
                disconnectedArm = @"Right";
            }
            else if(myo.identifier == self.rightMyo){
                disconnectedArm = @"Left";
            }
        }
        if (!deviceStillConnected) {
            if ([disconnectedArm isEqualToString:@"Left"]) {
                self.leftMyo = nil;
                self.leftAlreadyAlerted = NO;
                self.leftLabel.text = @"LEFT: WAITING FOR CONNECTION";
            }
            else if([disconnectedArm isEqualToString:@"Right"]){
                self.rightMyo = nil;
                self.rightAlreadyAlerted = NO;
                self.rightLabel.text = @"RIGHT: WAITING FOR CONNECTION";
            }
        }
    }
    
}

- (void)didLoseArm:(NSNotification *)notification {
    [self.alertView dismissWithClickedButtonIndex:0 animated:NO];
    [self alertWithTitle:@"Arm Lost" andContent:@"Please re-adjust your myo and perform the setup gesture" andCancelButton:@"OK"];
    /*
     NSArray *array = [TLMHub sharedHub].myoDevices;
     NSString *disconnectedArm;
     BOOL deviceStillConnected = false;
     for (int i = 0; i < array.count; i++) {
     NSLog(@"Running loop #%d",i);
     TLMMyo *myo = [array objectAtIndex:i];
     if (myo.identifier == self.leftMyo || myo.identifier == self.rightMyo) {
     deviceStillConnected = true;
     }
     else{
     if (myo.identifier == self.leftMyo) {
     disconnectedArm = @"Right";
     }
     else if(myo.identifier == self.rightMyo){
     disconnectedArm = @"Left";
     }
     }
     if (!deviceStillConnected) {
     if ([disconnectedArm isEqualToString:@"Left"]) {
     self.leftMyo = nil;
     self.leftAlreadyAlerted = NO;
     self.leftLabel.text = @"LEFT: WAITING FOR CONNECTION";
     }
     else if([disconnectedArm isEqualToString:@"Right"]){
     self.rightMyo = nil;
     self.rightAlreadyAlerted = NO;
     self.rightLabel.text = @"RIGHT: WAITING FOR CONNECTION";
     }
     }
     }
     */
}

- (void)alertWithTitle:(NSString *)title andContent:(NSString *)content andCancelButton:(NSString *)cancel{
    self.alertView = [[UIAlertView alloc]initWithTitle:title message:content delegate:nil cancelButtonTitle:cancel otherButtonTitles:nil];
    [self.alertView show];
}

- (void)didReceivePoseChange:(NSNotification *)notification {
    // Retrieve the pose from the NSNotification's userInfo with the kTLMKeyPose key.
    TLMPose *pose = notification.userInfo[kTLMKeyPose];
    self.currentPose = pose;
    
    // Handle the cases of the TLMPoseType enumeration
    switch (pose.type) {
        case TLMPoseTypeUnknown:
        case TLMPoseTypeRest:
            NSLog(@"Rest");
            break;
        case TLMPoseTypeFist:
            NSLog(@"Fist");
            break;
        case TLMPoseTypeWaveIn:
            NSLog(@"Wave In");
            break;
        case TLMPoseTypeWaveOut:
            NSLog(@"Wave Out");
            break;
        case TLMPoseTypeFingersSpread:
            NSLog(@"Fingers Spread");
            break;
        case TLMPoseTypeThumbToPinky:
            NSLog(@"Thumb to Pinky");
            break;
    }
}


- (void)didRecognizeArm:(NSNotification *)notification {
    NSLog(@"!!!!!!!!!Did recognize arm!!!!!!!!");
    [self.alertView dismissWithClickedButtonIndex:0 animated:NO];
    // Retrieve the arm event from the notification's userInfo with the kTLMKeyArmRecognizedEvent key.
    TLMArmRecognizedEvent *armEvent = notification.userInfo[kTLMKeyArmRecognizedEvent];
    
    // Update the armLabel with arm information
    NSString *armString = armEvent.arm == TLMArmRight ? @"Right" : @"Left";
    if ([armString isEqualToString:@"Right"]) {
        if (self.rightMyo == nil) {
            [self.alertView dismissWithClickedButtonIndex:0 animated:NO];
            [self alertWithTitle:@"Success" andContent:@"Myo connected on RIGHT arm" andCancelButton:@"ok"];
            self.rightMyo = armEvent.myo.identifier;
            if (self.rightMyo == self.leftMyo) {
                self.leftMyo = nil;
                self.leftLabel.text = @"LEFT: WAITING FOR CONNECTION";
                self.leftAlreadyAlerted = NO;
            }
            self.rightLabel.text = [NSString stringWithFormat:@"RIGHT: %@",self.rightMyo.UUIDString];
            [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.gotoMapsButton.alpha = 1;
            } completion:^(BOOL finished) {
            }];
        }
        else{
            if (armEvent.myo.identifier != self.rightMyo) {
                [self.alertView dismissWithClickedButtonIndex:0 animated:NO];
                [self alertWithTitle:@"Error" andContent:@"More than one myo worn on RIGHT arm"andCancelButton:@"ok"];
                if (!self.leftConnected && self.leftAlreadyAlerted) {
                    self.leftAlreadyAlerted = NO;
                }
                
            }
        }
    }
    else if([armString isEqualToString:@"Left"]){
        if (self.leftMyo == nil) {
            [self.alertView dismissWithClickedButtonIndex:0 animated:NO];
            [self alertWithTitle:@"Success" andContent:@"Myo connected on LEFT arm"andCancelButton:@"ok"];
            self.leftMyo = armEvent.myo.identifier;
            if (self.leftMyo == self.rightMyo) {
                self.rightMyo = nil;
                self.rightLabel.text = @"RIGHT: WAITING FOR CONNECTION";
                self.rightAlreadyAlerted = NO;
            }
            self.leftLabel.text = [NSString stringWithFormat:@"LEFT: %@",self.leftMyo.UUIDString];
        }
        else{
            if (armEvent.myo.identifier != self.leftMyo) {
                [self.alertView dismissWithClickedButtonIndex:0 animated:NO];
                [self alertWithTitle:@"Error" andContent:@"More than one myo worn on LEFT arm" andCancelButton:@"ok"];
                if (!self.rightConnected && self.rightAlreadyAlerted) {
                    self.rightAlreadyAlerted = NO;
                }
            }
        }
    }
    //    NSString *directionString = armEvent.xDirection == TLMArmXDirectionTowardWrist ? @"Toward Wrist" : @"Toward Elbow";
    //    self.armLabel.text = [NSString stringWithFormat:@"Arm: %@ X-Direction: %@", armString, directionString];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)connect:(id)sender{
    UINavigationController *controller = [TLMSettingsViewController settingsInNavigationController];
    [self presentViewController:controller animated:YES completion:nil];
}

@end

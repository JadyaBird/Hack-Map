//
//  MapsViewController.m
//  Hackmap
//
//  Created by Timothy Tong on 2014-09-20.
//  Copyright (c) 2014 Timothy Tong. All rights reserved.
//

#import "MapsViewController.h"
#import <MyoKit/MyoKit.h>
#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#define METERS_PER_MILE 1609.344
typedef enum controlMode{
    MControlModeStandby,
    MControlModeNormal,
    MControlModeFlyOver,
    MControlModeInit
}controlMode;

@interface MapsViewController()<MKMapViewDelegate,CLLocationManagerDelegate>
@property (nonatomic, strong)TLMPose *currentPose;
@property (nonatomic, strong)MKMapView *map;
@property (nonatomic, strong)UIAlertView *alertView;
@property (nonatomic)controlMode currentMode;
@property (nonatomic)NSInteger backSMStage;
@property (nonatomic, strong)CLGeocoder *geocoder;
@property (nonatomic, strong)CLLocationManager *locationManager;
@property (nonatomic, strong)UIImageView *iconView;
@property (nonatomic, readwrite)BOOL repeat;
@end

@implementation MapsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.currentMode = MControlModeInit;
    self.repeat = NO;
    self.backSMStage = 1;
    self.map = [[MKMapView alloc]initWithFrame:self.view.frame];
    self.map.delegate = self;
    self.map.mapType = MKMapTypeSatellite;
    self.map.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.map];
    UIView *bottomBar = [[UIView alloc]initWithFrame:CGRectMake(0, self.view.frame.size.height-40, self.view.frame.size.width, 40)];
    bottomBar.backgroundColor = [UIColor whiteColor];
    UIImage *play = [UIImage imageNamed:@"play.png"];
    self.iconView = [[UIImageView alloc]initWithFrame:CGRectMake(10, 5, 30, 30)];
    self.iconView.alpha = 0.7;
    self.iconView.image = play;
    [bottomBar addSubview:self.iconView];
    
    [self.view addSubview:bottomBar];
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didLoseArm:)
                                                 name:TLMMyoDidReceiveArmLostEventNotification
                                               object:nil];
    // Posted when a new orientation event is available from a TLMMyo. Notifications are posted at a rate of 50 Hz.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveOrientationEvent:)
                                                 name:TLMMyoDidReceiveOrientationEventNotification
                                               object:nil];
    // Posted when a new accelerometer event is available from a TLMMyo. Notifications are posted at a rate of 50 Hz.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveAccelerometerEvent:)
                                                 name:TLMMyoDidReceiveAccelerometerEventNotification
                                               object:nil];
    // Posted when a new pose is available from a TLMMyo
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceivePoseChange:)
                                                 name:TLMMyoDidReceivePoseChangedNotification
                                               object:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didLoseArm:(NSNotification *)notification{
    [self.alertView dismissWithClickedButtonIndex:0 animated:NO];
    [self alertWithTitle:@"Arm Lost" andContent:@"Please re-adjust your myo and perform the setup gesture" andCancelButton:@"OK"];
    
}

- (void)didReceiveOrientationEvent:(NSNotification *)notification{
    
}

- (void)didReceiveAccelerometerEvent:(NSNotification *)notification{
    
}

- (void)alertWithTitle:(NSString *)title andContent:(NSString *)content andCancelButton:(NSString *)cancel{
    self.alertView = [[UIAlertView alloc]initWithTitle:title message:content delegate:nil cancelButtonTitle:cancel otherButtonTitles:nil];
    [self.alertView show];
}

- (void)didReceivePoseChange:(NSNotification *)notification{
    // Retrieve the pose from the NSNotification's userInfo with the kTLMKeyPose key.
    TLMPose *pose = notification.userInfo[kTLMKeyPose];
    self.currentPose = pose;
    TLMMyo *myo = pose.myo;
    TLMArm arm = myo.identifier == self.rightMyo ? TLMArmRight:TLMArmLeft;
    
    // Handle the cases of the TLMPoseType enumeration
    NSString *poseString;
    switch (pose.type) {
        case TLMPoseTypeUnknown:
        case TLMPoseTypeRest:
            NSLog(@"Rest");
            poseString = @"REST";
            if ((arm == TLMArmLeft || arm == TLMArmRight) && self.backSMStage == 2 && self.currentMode == MControlModeStandby) {
                NSLog(@"back SM stage 3");
                self.backSMStage = 3;
            }
            break;
        case TLMPoseTypeFist:
            NSLog(@"Fist");
            poseString = @"Fist";
            MKCoordinateRegion outRegion;
            //Set Zoom level using Span
            MKCoordinateSpan outSpan;
            outRegion.center=self.map.region.center;
            
            outSpan.latitudeDelta=self.map.region.span.latitudeDelta * 4;
            outSpan.longitudeDelta=self.map.region.span.longitudeDelta *4;

            outRegion.span=outSpan;
            [self.map setRegion:outRegion animated:YES];
            break;
        case TLMPoseTypeWaveIn:
            NSLog(@"Wave In");
            if (arm == TLMArmRight && self.backSMStage == 1 && self.currentMode == MControlModeStandby) {
                NSLog(@"back SM stage 2");
                self.backSMStage = 2;
            }
            else if(arm ==TLMArmRight && self.backSMStage == 3 && self.currentMode == MControlModeStandby){
                NSLog(@"back from standby!!!");
                self.backSMStage = 1;
                [self back];
            }
            poseString = @"Wave In";
            break;
        case TLMPoseTypeWaveOut:
            NSLog(@"Wave Out");
            if (arm == TLMArmLeft && self.backSMStage == 1 && self.currentMode == MControlModeStandby) {
                NSLog(@"back SM stage 2");
                self.backSMStage = 2;
            }
            else if(arm ==TLMArmLeft && self.backSMStage == 3 && self.currentMode == MControlModeStandby){
                NSLog(@"back from standby!!!");
                self.backSMStage = 1;
                [self back];
            }
            
            poseString = @"Wave Out";
            break;
        case TLMPoseTypeFingersSpread:
            NSLog(@"Fingers Spread");
            MKCoordinateRegion inRegion;
            //Set Zoom level using Span
            MKCoordinateSpan inSpan;
            inRegion.center=self.map.region.center;
            
            inSpan.latitudeDelta=self.map.region.span.latitudeDelta /2.0002;
            inSpan.longitudeDelta=self.map.region.span.longitudeDelta /2.0002;
            inRegion.span=inSpan;
            [self.map setRegion:inRegion animated:TRUE];
            poseString = @"Fingers Spread";
            break;
        case TLMPoseTypeThumbToPinky:
            NSLog(@"Thumb to Pinky");
            poseString = @"Thumb to Pinky";
            if (self.currentMode == MControlModeStandby) {
                NSLog(@"Switching to normal mode");
                self.currentMode = MControlModeNormal;
                UIImage *link = [UIImage imageNamed:@"link.png"];
                [self.iconView setImage:link];
                self.repeat = YES;
                [self blinkIcon];
            }
            else if(self.currentMode == MControlModeNormal){
                NSLog(@"Switching to normal mode");
                self.repeat = NO;
                self.currentMode = MControlModeStandby;
            }
            break;
    }
}

- (void)blinkIcon{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.9 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.iconView.alpha = 0.2;
        } completion:^(BOOL finished) {
            self.iconView.alpha = 1;
            if (self.repeat) {
                [self blinkIcon];
            }
            else{
                [self.iconView setImage:[UIImage imageNamed:@"play.png"]];
            }
            
        }];
    });
    
}

- (void)back{
    [self.alertView dismissWithClickedButtonIndex:0 animated:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)getUserLocation{
    // Create the location manager if this object does not
    // already have one.
    if (nil == self.locationManager)
        self.locationManager = [[CLLocationManager alloc] init];
    
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    ;
    
    // Set a movement threshold for new events.
    self.locationManager.distanceFilter = 500; // meters
    
    [self.locationManager startUpdatingLocation];
    self.currentMode = MControlModeStandby;
    //    [self.map setCenterCoordinate:self.map.userLocation.coordinate animated:YES];
    NSLog(@"Now standing by");
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation  {
    NSLog(@"LOCATION UPDATED");
    CLLocationCoordinate2D loc = [newLocation coordinate];
    [self.map setCenterCoordinate:loc];
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = loc;
    [self.map addAnnotation:point];
}

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    // If it's a relatively recent event, turn off updates to save power.
    CLLocation *location = [locations lastObject];
    NSDate* eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0) {
        // If the event is recent, do something with it.
        NSLog(@"latitude %+.6f, longitude %+.6f\n",
              location.coordinate.latitude,
              location.coordinate.longitude);
    }
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end

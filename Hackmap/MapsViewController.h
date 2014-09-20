//
//  MapsViewController.h
//  Hackmap
//
//  Created by Timothy Tong on 2014-09-20.
//  Copyright (c) 2014 Timothy Tong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MapsViewController:UIViewController
@property (nonatomic, strong)NSUUID *leftMyo;
@property (nonatomic, strong)NSUUID *rightMyo;
- (void)getUserLocation;
@end

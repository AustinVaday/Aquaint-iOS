//
//  DataViewController.h
//  Page-Based-Application-Demo
//
//  Created by Austin Vaday on 11/16/15.
//  Copyright (c) 2015 ConnectMe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DataViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *dataLabel;
@property (strong, nonatomic) id dataObject;

@end

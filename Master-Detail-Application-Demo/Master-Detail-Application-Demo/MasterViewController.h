//
//  MasterViewController.h
//  Master-Detail-Application-Demo
//
//  Created by Austin Vaday on 11/16/15.
//  Copyright (c) 2015 ConnectMe. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) DetailViewController *detailViewController;

@end

//
//  DetailViewController.h
//  Master-Detail-Application-Demo
//
//  Created by Austin Vaday on 11/16/15.
//  Copyright (c) 2015 ConnectMe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end

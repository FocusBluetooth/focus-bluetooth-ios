//
//  ViewController.h
//  CBDemo
//
//  Created by Sergio on 25/01/12.
//  Copyright (c) 2012 Sergio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlueToothMe.h"

@interface ViewController : UIViewController <BlueToothMeDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong)     IBOutlet UITableView * tableView;
@property (nonatomic, strong)     IBOutlet UIView * printView;
@property (nonatomic, strong)     IBOutlet UITextView * textView;
@property (nonatomic, strong)     IBOutlet UIButton * printButton;

NSData *dataByIntepretingHexString(NSString *hexString);


@end

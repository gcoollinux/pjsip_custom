//
//  DialViewController.h
//  SimpleSipPhone
//
//  Created by MK on 15/5/23.
//  Copyright (c) 2015年 Makee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DialViewController : UIViewController
@property (weak, nonatomic)  NSString *phoneNumberFiled;
- (IBAction)EndCall:(id)sender;
@property (strong, nonatomic) IBOutlet UILabel *CallStatus;
- (void)__processMakeCall;
@end

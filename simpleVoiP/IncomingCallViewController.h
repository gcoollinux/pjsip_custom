//
//  IncomingCallViewController.h
//  SimpleSipPhone
//
//  Created by MK on 15/5/23.
//  Copyright (c) 2015年 Makee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IncomingCallViewController : UIViewController

@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, assign) NSInteger callId;
@property (strong, nonatomic) IBOutlet UIButton *AnswerCallButton;

@end

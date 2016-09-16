//
//  customPjsua.h
//  simpleVoiP
//
//  Created by puja on 16/09/16.
//  Copyright © 2016 akshay bansal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface customPjsua : NSObject


@property (weak, nonatomic)  NSString *serverField;
@property (weak, nonatomic)  NSString *usernameField;
@property (weak, nonatomic)  NSString *passwordField;

+ (id)sharedManager;

-(BOOL)initialisePjsua;
- (void) sipRegister ;

@end

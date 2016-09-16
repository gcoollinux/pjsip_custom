//
//  customPjsua.m
//  simpleVoiP
//
//  Created by puja on 16/09/16.
//  Copyright © 2016 akshay bansal. All rights reserved.
//

#import "customPjsua.h"
#import <pjsua-lib/pjsua.h>
#import "LoginViewController.h"
#import "DialViewController.h"
#import "IncomingCallViewController.h"
#import "AppDelegate.h"


static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata);
static void on_call_state(pjsua_call_id call_id, pjsip_event *e);
static void on_call_media_state(pjsua_call_id call_id);
static void on_reg_state(pjsua_acc_id acc_id);




@implementation customPjsua

+ (id)sharedManager
{
    static customPjsua *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });

    return sharedMyManager;
}

-(id)init {
    
    return self;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

- (void)__handleRegisterStatus:(NSNotification *)notification {
    pjsua_acc_id acc_id = [notification.userInfo[@"acc_id"] intValue];
    pjsip_status_code status = [notification.userInfo[@"status"] intValue];
    NSString *statusText = notification.userInfo[@"status_text"];
    
    if (status != PJSIP_SC_OK) {
        NSLog(@"Login failed Error Message: %d(%@)", status, statusText);
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:acc_id forKey:@"login_account_id"];
    [[NSUserDefaults standardUserDefaults] setObject:self.serverField forKey:@"server_uri"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //[self __switchToDialViewController];
}


- (void) sipRegister {
    
    NSString *server = self.serverField;
    NSString *username = self.usernameField;
    NSString *password = self.passwordField;
    
    pjsua_acc_id acc_id;
    pjsua_acc_config cfg;
    
    pjsua_acc_config_default(&cfg);
    cfg.id = pj_str((char *)[NSString stringWithFormat:@"sip:%@@%@", username, server].UTF8String);
    cfg.reg_uri = pj_str((char *)[NSString stringWithFormat:@"sip:%@", server].UTF8String);
    cfg.reg_retry_interval = 0;
    cfg.cred_count = 1;
    cfg.cred_info[0].realm = pj_str("*");
    cfg.cred_info[0].username = pj_str((char *)username.UTF8String);
    cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
    cfg.cred_info[0].data = pj_str((char *)password.UTF8String);
    
    pj_status_t status = pjsua_acc_add(&cfg, PJ_TRUE, &acc_id);
    
    if (status != PJ_SUCCESS) {
        NSString *errorMessage = [NSString stringWithFormat:@"Login failed, returning error number:%d!", status];
        NSLog(@"register error: %@", errorMessage);
    }
}



-(BOOL)initialisePjsua
{

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(__handleIncommingCall:)
                                                 name:@"SIPIncomingCallNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(__handleRegisterStatus:)
                                                 name:@"SIPRegisterStatusNotification"
                                               object:nil];
    
    pj_status_t status;
    
    // 创建SUA
    status = pjsua_create();
    
    if (status != PJ_SUCCESS) {
        NSLog(@"error create pjsua"); return NO;
    }
    
    {
        // SUA 相关配置
        pjsua_config cfg;
        pjsua_media_config media_cfg;
        pjsua_logging_config log_cfg;
        
        pjsua_config_default(&cfg);
        
        // 回调函数配置
        cfg.cb.on_incoming_call = &on_incoming_call;            // 来电回调
        cfg.cb.on_call_media_state = &on_call_media_state;      // 媒体状态回调（通话建立后，要播放RTP流）
        cfg.cb.on_call_state = &on_call_state;                  // 电话状态回调
        cfg.cb.on_reg_state = &on_reg_state;                    // 注册状态回调
        
        // 媒体相关配置
        pjsua_media_config_default(&media_cfg);
        media_cfg.clock_rate = 16000;
        media_cfg.snd_clock_rate = 16000;
        media_cfg.ec_tail_len = 0;
        
        // 日志相关配置
        pjsua_logging_config_default(&log_cfg);
#ifdef DEBUG
        log_cfg.msg_logging = PJ_TRUE;
        log_cfg.console_level = 4;
        log_cfg.level = 5;
#else
        log_cfg.msg_logging = PJ_FALSE;
        log_cfg.console_level = 0;
        log_cfg.level = 0;
#endif
        
        // 初始化PJSUA
        status = pjsua_init(&cfg, &log_cfg, &media_cfg);
        if (status != PJ_SUCCESS) {
            NSLog(@"error init pjsua"); return NO;
        }
    }
    
    // udp transport
    {
        pjsua_transport_config cfg;
        pjsua_transport_config_default(&cfg);
        
        // 传输类型配置
        status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &cfg, NULL);
        if (status != PJ_SUCCESS) {
            NSLog(@"error add transport for pjsua"); return NO;
        }
    }
    
    // 启动PJSUA
    status = pjsua_start();
    if (status != PJ_SUCCESS) {
        NSLog(@"error start pjsua"); return NO;
    }
    return YES;

}


- (void)__handleIncommingCall:(NSNotification *)notification {
    pjsua_call_id callId = [notification.userInfo[@"call_id"] intValue];
    NSString *phoneNumber = notification.userInfo[@"remote_address"];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    IncomingCallViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"IncomingCallViewController"];
    
    viewController.phoneNumber = phoneNumber;
    viewController.callId = callId;
    
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UIViewController *rootViewController = appDelegate.window.rootViewController;
    [rootViewController presentViewController:viewController animated:YES completion:nil];
}


static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata) {
    pjsua_call_info ci;
    pjsua_call_get_info(call_id, &ci);
    
    NSString *remote_info = [NSString stringWithUTF8String:ci.remote_info.ptr];
    
    NSUInteger startIndex = [remote_info rangeOfString:@"<"].location;
    NSUInteger endIndex = [remote_info rangeOfString:@">"].location;
    
    NSString *remote_address = [remote_info substringWithRange:NSMakeRange(startIndex + 1, endIndex - startIndex - 1)];
    remote_address = [remote_address componentsSeparatedByString:@":"][1];
    
    id argument = @{
                    @"call_id"          : @(call_id),
                    @"remote_address"   : remote_address
                    };
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SIPIncomingCallNotification" object:nil userInfo:argument];
    });
    
}

static void on_call_state(pjsua_call_id call_id, pjsip_event *e) {
    pjsua_call_info ci;
    pjsua_call_get_info(call_id, &ci);
    
    id argument = @{
                    @"call_id"  : @(call_id),
                    @"state"    : @(ci.state)
                    };
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SIPCallStatusChangedNotification" object:nil userInfo:argument];
    });
}

static void on_call_media_state(pjsua_call_id call_id) {
    pjsua_call_info ci;
    pjsua_call_get_info(call_id, &ci);
    
    if (ci.media_status == PJSUA_CALL_MEDIA_ACTIVE) {
        // When media is active, connect call to sound device.
        pjsua_conf_connect(ci.conf_slot, 0);
        pjsua_conf_connect(0, ci.conf_slot);
    }
}

static void on_reg_state(pjsua_acc_id acc_id) {
    
    pj_status_t status;
    pjsua_acc_info info;
    
    status = pjsua_acc_get_info(acc_id, &info);
    if (status != PJ_SUCCESS)
        return;
    
    id argument = @{
                    @"acc_id"       : @(acc_id),
                    @"status_text"  : [NSString stringWithUTF8String:info.status_text.ptr],
                    @"status"       : @(info.status)
                    };
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SIPRegisterStatusNotification" object:nil userInfo:argument];
    });
}




@end

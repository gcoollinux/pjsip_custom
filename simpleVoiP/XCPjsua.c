//
//  XCPjsua.c
//  simpleVoiP
//
//  Created by akshay bansal on 8/25/16.
//  Copyright © 2016 akshay bansal. All rights reserved.
//

#include <pjsua-lib/pjsua.h>
#include "XCPjsua.h"
#define THIS_FILE "XCPjsua.c"
static pjsua_acc_id acc_id;
static pjsua_call_id call_id_global;

const size_t MAX_SIP_ID_LENGTH = 50;
const size_t MAX_SIP_REG_URI_LENGTH = 50;

static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata);
static void on_call_state(pjsua_call_id call_id, pjsip_event *e);
static void on_call_media_state(pjsua_call_id call_id);
static void error_exit(const char *title, pj_status_t status);

int startPjsip(char *sipUser, char* sipDomain)
{
    pj_status_t status;
    
    // Create pjsua first
    status = pjsua_create();
    if (status != PJ_SUCCESS) error_exit("Error in pjsua_create()", status);
    
    // Init pjsua
    {
        // Init the config structure
        pjsua_config cfg;
        pjsua_config_default (&cfg);
        
        cfg.cb.on_incoming_call = &on_incoming_call;
        cfg.cb.on_call_media_state = &on_call_media_state;
        cfg.cb.on_call_state = &on_call_state;
        
        // Init the logging config structure
        pjsua_logging_config log_cfg;
        pjsua_logging_config_default(&log_cfg);
        log_cfg.console_level = 4;
       // log_cfg.console_level = 5;
        //log_cfg.level = 5;

        
        // Init the pjsua
        status = pjsua_init(&cfg, &log_cfg, NULL);
        if (status != PJ_SUCCESS) error_exit("Error in pjsua_init()", status);
    }
    
    // Add UDP transport.
    {
        // Init transport config structure
        pjsua_transport_config cfg;
        pjsua_transport_config_default(&cfg);
        cfg.port = 5080;
        
        // Add TCP transport.
        status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &cfg, NULL);
        if (status != PJ_SUCCESS) error_exit("Error creating transport", status);
    }
    
    // Add TCP transport.
    {
        // Init transport config structure
        pjsua_transport_config cfg;
        pjsua_transport_config_default(&cfg);
        cfg.port = 5080;
        
        // Add TCP transport.
        status = pjsua_transport_create(PJSIP_TRANSPORT_TCP, &cfg, NULL);
        if (status != PJ_SUCCESS) error_exit("Error creating transport", status);
    }
    
    // Initialization is done, now start pjsua
    status = pjsua_start();
    if (status != PJ_SUCCESS) error_exit("Error starting pjsua", status);
    
    // Register the account on local sip server
    {
        pjsua_acc_config cfg;
        
        pjsua_acc_config_default(&cfg);
        
        char sipId[MAX_SIP_ID_LENGTH];
        sprintf(sipId, "sip:%s@%s", sipUser, sipDomain);
        cfg.id = pj_str(sipId);
        
        char regUri[MAX_SIP_REG_URI_LENGTH];
        sprintf(regUri, "sip:%s", sipDomain);
        cfg.reg_uri = pj_str(regUri);
        
        
        cfg.proxy[0] = pj_str((char *)"sip:108.170.10.194");
        cfg.cred_count = 1;
        cfg.cred_info[0].scheme = pj_str((char *)"digest");
        cfg.cred_info[0].realm = pj_str((char *)"*");
        cfg.cred_info[0].username = pj_str((char *)"801");
        cfg.cred_info[0].data_type = 0;
        cfg.cred_info[0].data = pj_str((char *)"1234");
        
        

        status = pjsua_acc_add(&cfg, PJ_TRUE, &acc_id);
        if (status != PJ_SUCCESS) error_exit("Error adding account", status);
    }
    
    return 0;
}

/* Callback called by the library upon receiving incoming call */
static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id,
                             pjsip_rx_data *rdata)
{
    
    pjsua_call_info ci;
    
    PJ_UNUSED_ARG(acc_id);
    PJ_UNUSED_ARG(rdata);
    
    pjsua_call_get_info(call_id, &ci);
    
    PJ_LOG(3,(THIS_FILE, "Incoming call from %.*s!!",
              (int)ci.remote_info.slen,
              ci.remote_info.ptr));
    
    /* Automatically answer incoming calls with 200/OK */
  //  pjsua_call_answer(call_id, 200, NULL, NULL);
    answercall(call_id);
}

/* Callback called by the library when call's state has changed */
static void on_call_state(pjsua_call_id call_id, pjsip_event *e)
{
    pjsua_call_info ci;
    
    PJ_UNUSED_ARG(e);
    
    pjsua_call_get_info(call_id, &ci);
    PJ_LOG(3,(THIS_FILE, "Call %d state=%.*s", call_id,
              (int)ci.state_text.slen,
              ci.state_text.ptr));
    if (call_id) {
        /* Automatically answer incoming calls with 200/OK */
     //   pjsua_call_answer(call_id, 200, NULL, NULL);
        answercall(call_id);
        
    }
   
}

/* Callback called by the library when call's media state has changed */
static void on_call_media_state(pjsua_call_id call_id)
{
    pjsua_call_info ci;
    
    pjsua_call_get_info(call_id, &ci);
    
    if (ci.media_status == PJSUA_CALL_MEDIA_ACTIVE) {
        // When media is active, connect call to sound device.
        pjsua_conf_connect(ci.conf_slot, 0);
        pjsua_conf_connect(0, ci.conf_slot);
    }
}

/* Display error and exit application */
static void error_exit(const char *title, pj_status_t status)
{
    pjsua_perror(THIS_FILE, title, status);
    pjsua_destroy();
    exit(1);
}


void makeCall(char* destUri)
{
    pj_status_t status;
    pj_str_t uri = pj_str(destUri);
    
    status = pjsua_call_make_call(acc_id, &uri, 0, NULL, NULL, NULL);
    if (status != PJ_SUCCESS) error_exit("Error making call", status);
}

void endCall()
{
    pjsua_call_hangup_all();
}

void answercall(pjsua_call_id call_id)
{
    //if (call_id) {
        pjsua_call_answer(call_id, 200, NULL, NULL);
   // }
    
}


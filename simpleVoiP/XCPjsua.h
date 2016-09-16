//
//  XCPjsua.h
//  simpleVoiP
//
//  Created by akshay bansal on 8/25/16.
//  Copyright © 2016 akshay bansal. All rights reserved.
//
#include <pjsua-lib/pjsua.h>
#ifndef XCPjsua_h
#define XCPjsua_h
int startPjsip(char *sipUser, char* sipDomain);
/**
 * Make VoIP call.
 *
 * @param destUri the uri of the receiver, something like "sip:192.168.43.106:5080"
 */
void makeCall(char* destUri);

/**
 * End ongoing VoIP calls
 */
void endCall();

/**
 * Answer incoming VoIP calls
 */
void answercall(pjsua_call_id call_id);
#endif /* XCPjsua_h */

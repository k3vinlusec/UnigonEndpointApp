//
//  c-bridge-helper.h
//  UnigonEndpointNExtension
//
//  Created by Kai Lu on 11/21/20.
//

#ifndef c_bridge_helper_h
#define c_bridge_helper_h

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <libproc.h>
#include <errno.h>


struct process_info {
    pid_t pid;
    char procName[MAXPATHLEN];
    pid_t ppid;
    uid_t uid;
    char userName[256];
    gid_t gid;
    char fullPath[PROC_PIDPATHINFO_MAXSIZE];
    bool success;
};

struct process_info getProcInfoDetail(pid_t pid);
void getprocfullpath(audit_token_t *audittoken);
#endif /* c_bridge_helper_h */



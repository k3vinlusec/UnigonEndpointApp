//
//  c-bridge-helper.c
//  UnigonEndpointNExtension
//
//  Created by Kai Lu on 11/21/20.
//

#include "c-bridge-helper.h"
#include <os/log.h>
#include <pwd.h>


char *getUsernameByUid(uid_t uid) {
    
    struct passwd *pw;
    pw = getpwuid(uid);
    if(pw){
        //os_log(OS_LOG_DEFAULT, "getUsernameByUid: %{public}s", pw->pw_name);
        return pw->pw_name;
    }
    return NULL;
}

struct process_info getProcInfoDetail(pid_t pid)
{
    struct process_info pInfo;
    struct proc_bsdshortinfo proc;
    int st = proc_pidinfo(pid, PROC_PIDT_SHORTBSDINFO, 0, &proc, PROC_PIDT_SHORTBSDINFO_SIZE);
    if (st != PROC_PIDT_SHORTBSDINFO_SIZE) {
        os_log(OS_LOG_DEFAULT, "[*] Error: proc_pidinfo()");
        pInfo.success = false;
        return pInfo;
    }
        //printf("pid: %d, ppid: %d, comm: %s, uid: %d, gid: %d\n", (int)proc.pbsi_pid,(int)proc.pbsi_ppid, proc.pbsi_comm, (int)proc.pbsi_uid, (int)proc.pbsi_gid);
    
    char pathbuf[PROC_PIDPATHINFO_MAXSIZE]={0};
    int ret = proc_pidpath (pid, pathbuf, sizeof(pathbuf));
    if (ret <=0) {
        os_log(OS_LOG_DEFAULT, "[*] Error: pid: %d, proc_pidpath() %{public}s", pid, strerror(errno));
        pInfo.success = false;
        return pInfo;
    }
    
    //os_log(OS_LOG_DEFAULT, "[*] pid: %d, ppid: %d, comm: %{public}s, uid: %d, gid: %d, proc: %{public}s\n", (int)proc.pbsi_pid,(int)proc.pbsi_ppid, proc.pbsi_comm, (int)proc.pbsi_uid, (int)proc.pbsi_gid, pathbuf);
    
    
    //proc.pbsi_comm only has 16 bytes length, so it could truncate the process name having more 16 bytes length
    char *pn = strrchr(pathbuf, '/');
    pInfo.pid = proc.pbsi_pid;
    memset(pInfo.procName, 0, MAXPATHLEN);
    memcpy(pInfo.procName, pn+1, strlen(pn)-1);
    pInfo.gid = proc.pbsi_gid;
    pInfo.ppid = proc.pbsi_ppid;
    pInfo.uid = proc.pbsi_uid;
    char *user = getUsernameByUid(pInfo.uid);
    memset(pInfo.userName, 0, 256);
    if(user == NULL){
        memcpy(pInfo.userName, "N/A", 3);
    }else{
        memcpy(pInfo.userName, user, strlen(user));
    }
    memset(pInfo.fullPath, 0, PROC_PIDPATHINFO_MAXSIZE);
    memcpy(pInfo.fullPath, pathbuf, sizeof(pathbuf));
    pInfo.success = true; // gain proc info successfully
    
    return pInfo;
}

void getprocfullpath(audit_token_t *audittoken){
    char pathbuf[PROC_PIDPATHINFO_MAXSIZE]={0};
    if (__builtin_available(macOS 11.0, *)) {
        int ret = proc_pidpath_audittoken(audittoken, pathbuf, sizeof(pathbuf));
        if (ret <=0) {
            os_log(OS_LOG_DEFAULT, "[*] Error: proc_pidpath_audittoken() %{public}s", strerror(errno));
        }
    } else {
        // Fallback on earlier versions
    }
    
    os_log(OS_LOG_DEFAULT, "[*] Proc: %{public}s", pathbuf);
}

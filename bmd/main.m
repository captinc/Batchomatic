#import "../headers/NSTask.h"
#import <stdio.h>
#import <string.h>
#import <dlfcn.h>
#define FLAG_PLATFORMIZE (1 << 1)

void fixSetuidForChimera() { //this method needs to be run when using Chimera or Electra because they behave slightly differently than unc0ver
    void *handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
    if (!handle)
        return;
    dlerror();
    typedef void (*fix_entitle_prt_t)(pid_t pid, uint32_t what);
    fix_entitle_prt_t enetitle_ptr = (fix_entitle_prt_t)dlsym(handle, "jb_oneshot_entitle_now");
    const char *dlsym_error = dlerror();
    if (dlsym_error)
        return;
    enetitle_ptr(getpid(), FLAG_PLATFORMIZE);
    dlerror();
    typedef void (*fix_setuid_prt_t)(pid_t pid);
    fix_setuid_prt_t setuid_ptr = (fix_setuid_prt_t)dlsym(handle,"jb_oneshot_fix_setuid_now");
    dlsym_error = dlerror();
    if (dlsym_error)
        return;
    setuid_ptr(getpid());
    setuid(0);
    setgid(0);
    setuid(0);
    setgid(0);
}

int main(int argc, char *argv[], char *envp[]) { //allows the user to pick one of the commands below and then runs it as root. Hardcoding commands instead of allowing the user to specify a command in the arguments is a safer and better practice
    if (argc < 2) {
        printf("Error: you did not specify a command to run\n");
        return 1;
    }
    
    setuid(0); //make us root
    if (getuid() != 0) {
        fixSetuidForChimera();
    }
    NSTask *task = [[NSTask alloc] init];
    NSMutableArray *args = [[NSMutableArray alloc] init];
    
    if (!strcmp(argv[1], "deb")) { //the feature for creating a .deb of a single tweak
        if (argc > 2) {
            [task setLaunchPath:@"/usr/bin/bmd"];
            [args addObject:@"rmtemp"];
            [task setArguments:args];
            [task launch];
            [task waitUntilExit];

            task = [[NSTask alloc] init];
            args = [[NSMutableArray alloc] init];
            [task setLaunchPath:@"/bin/bash"];
            [args addObject:@"/Library/batchomatic/createoffline.sh"];
            [args addObject:@"deb"];
            [args addObject:[NSString stringWithFormat:@"%s", argv[2]]];
        }
        else {
            printf("Error: you did not specify a package identifier\n");
            return 1;
        }
    }
    //---------------------------------------------------------------------------------------------------
    else if (!strcmp(argv[1], "rmtemp")) {
        [task setLaunchPath:@"/bin/rm"];
        [args addObject:@"-r"];
        [args addObject:@"/tmp/batchomatic"];
    }
    else if (!strcmp(argv[1], "chperms1")) {
        [task setLaunchPath:@"/bin/chmod"];
        [args addObject:@"-R"];
        [args addObject:@"777"];
        [args addObject:@"/var/mobile/BatchInstall/SavedDebs"];
    }
    else if (!strcmp(argv[1], "chperms2")) {
        [task setLaunchPath:@"/bin/chmod"];
        [args addObject:@"-R"];
        [args addObject:@"777"];
        [args addObject:@"/var/mobile/BatchInstall/OfflineDebs"];
    }
    //---------------------------------------------------------------------------------------------------
    else if (!strcmp(argv[1], "installprefs")) {
        [task setLaunchPath:@"/bin/cp"];
        [args addObject:@"-r"];
        [args addObject:@"/var/mobile/BatchInstall/Preferences/*"];
        [args addObject:@"/var/mobile/Library/Preferences"];
    }
    else if (!strcmp(argv[1], "installactivatorprefs")) {
        [task setLaunchPath:@"/bin/cp"];
        [args addObject:@"/var/mobile/BatchInstall/Preferences/libactivator.exported.plist"];
        [args addObject:@"/var/mobile/Library/Caches/libactivator.plist"];
    }
    else if (!strcmp(argv[1], "installhosts")) {
        [task setLaunchPath:@"/bin/mv"];
        [args addObject:@"/etc/hosts"];
        [args addObject:@"/etc/hosts-beforeBatchomatic.bak"];
        [task setArguments:args];
        [task launch];
        [task waitUntilExit];
        
        task = [[NSTask alloc] init];
        args = [[NSMutableArray alloc] init];
        [task setLaunchPath:@"/bin/cp"];
        [args addObject:@"/var/mobile/BatchInstall/hosts"];
        [args addObject:@"/etc"];
        [task setArguments:args];
        [task launch];
        [task waitUntilExit];
        
        task = [[NSTask alloc] init];
        args = [[NSMutableArray alloc] init];
        [task setLaunchPath:@"/bin/chmod"];
        [args addObject:@"644"];
        [args addObject:@"/etc/hosts"];
    }
    else if (!strcmp(argv[1], "installdeb")) {
        [task setLaunchPath:@"/usr/bin/dpkg"];
        [args addObject:@"-i"];
        [args addObject:@"--force-all"];
        [args addObject:[NSString stringWithFormat:@"%s", argv[2]]];
    }
    else if (!strcmp(argv[1], "dpkgconfig")) {
        [task setLaunchPath:@"/usr/bin/dpkg"];
        [args addObject:@"--configure"];
        [args addObject:@"-a"];
    }
    else if (!strcmp(argv[1], "addrepos")) {
        [task setLaunchPath:@"/bin/bash"];
        [args addObject:@"/Library/batchomatic/determinerepostoadd.sh"];
        [args addObject:[NSString stringWithFormat:@"%s", argv[2]]];
    }
    else if (!strcmp(argv[1], "removeall")) {
        [task setLaunchPath:@"/bin/bash"];
        [args addObject:@"/Library/batchomatic/removealltweaks.sh"];
        [args addObject:[NSString stringWithFormat:@"%s", argv[2]]];
    }
    //---------------------------------------------------------------------------------------------------
    else if (!strcmp(argv[1], "online")) { //running each stage of creating an online deb
        if (!strcmp(argv[2], "all")) {
            [task setLaunchPath:@"/bin/bash"];
            [args addObject:@"/Library/batchomatic/createonline.sh"];
            [args addObject:@"all"];
        }
        else {
            char* p;
            errno = 0;
            long arg = strtol(argv[2], &p, 10);
            if (*p != '\0' || errno != 0) {
                printf("Error converting string to int\n");
                return 1;
            }
            if (arg < INT_MIN || arg > INT_MAX) {
                printf("Error converting string to int\n");
                return 1;
            }
            int arg_int = arg;
            if (arg_int >= 1 && arg_int <= 10) {
                [task setLaunchPath:@"/bin/bash"];
                [args addObject:@"/Library/batchomatic/createonline.sh"];
                [args addObject:[NSString stringWithFormat:@"%s", argv[2]]];
            }
            else {
                printf("Error: you did not pick a valid step\n");
                return 1;
            }
        }
    }
    else if (!strcmp(argv[1], "offline")) { //running each stage of creating an offline deb
        if (!strcmp(argv[2], "all")) {
            [task setLaunchPath:@"/bin/bash"];
            [args addObject:@"/Library/batchomatic/createoffline.sh"];
            [args addObject:@"all"];
        }
        else {
            char* p;
            errno = 0;
            long arg = strtol(argv[2], &p, 10);
            if (*p != '\0' || errno != 0) {
                printf("Error converting string to int\n");
                return 1;
            }
            if (arg < INT_MIN || arg > INT_MAX) {
                printf("Error converting string to int\n");
                return 1;
            }
            int arg_int = arg;
            if (arg_int >= 1 && arg_int <= 10) {
                [task setLaunchPath:@"/bin/bash"];
                [args addObject:@"/Library/batchomatic/createoffline.sh"];
                [args addObject:[NSString stringWithFormat:@"%s", argv[2]]];
                if (arg_int == 8) {
                    [args addObject:[NSString stringWithFormat:@"%s", argv[3]]];
                    [args addObject:[NSString stringWithFormat:@"%s", argv[4]]];
                }
            }
            else {
                printf("Error: you did not pick a valid step\n");
                return 1;
            }
        }
    }
    else {
        printf("Error: you did not pick a valid option\n");
        return 1;
    }
    [task setArguments:args];
    [task launch];
    [task waitUntilExit];
    return 0;
}

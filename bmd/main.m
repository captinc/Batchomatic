#import <stdio.h>
#import <string.h>
#import <dlfcn.h>
#import "../Headers/NSTask.h"
#define FLAG_PLATFORMIZE (1 << 1)

// On Chimera, you have to do this fancy stuff to make yourself root
// (cannot simply do setuid() like unc0ver/checkra1n)
void fixSetuidForChimera() {
    void *handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
    if (!handle) {
        return;
    }
    
    dlerror();
    typedef void (*fix_entitle_prt_t)(pid_t pid, uint32_t what);
    fix_entitle_prt_t enetitle_ptr = (fix_entitle_prt_t)dlsym(handle, "jb_oneshot_entitle_now");
    const char *dlsym_error = dlerror();
    if (dlsym_error) {
        return;
    }
    enetitle_ptr(getpid(), FLAG_PLATFORMIZE);
    
    dlerror();
    typedef void (*fix_setuid_prt_t)(pid_t pid);
    fix_setuid_prt_t setuid_ptr = (fix_setuid_prt_t)dlsym(handle,"jb_oneshot_fix_setuid_now");
    dlsym_error = dlerror();
    if (dlsym_error) {
        return;
    }
    
    setuid_ptr(getpid());
    setuid(0);
    setgid(0);
    setuid(0);
    setgid(0);
}

// Allows you to pick one of the commands below and run
// it as root. Hardcoding commands instead of passing a
// command in the arguments is a safer and better practice
int main(int argc, char *argv[], char *envp[]) {
    if (argc < 2) {
        printf("Error: you did not specify an option to run\n");
        return 1;
    }
    
    // make us root
    setuid(0);
    if (getuid() != 0) {
        fixSetuidForChimera();
    }
    
    NSTask *task = [[NSTask alloc] init];
    NSMutableArray *args = [[NSMutableArray alloc] init];
    // misc utilities
    if (!strcmp(argv[1], "rmtemp")) {
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
    //--------------------------------------------------------------------------------------------------------------------------
    // loading a list of currently installed tweaks for the "Repack tweak to .deb" menu
    else if (!strcmp(argv[1], "getlist")) {
        [task setLaunchPath:@"/bin/bash"];
        [args addObject:@"/Library/Batchomatic/createonline.sh"];
        [args addObject:@"getlist"];
    }
    else if (!strcmp(argv[1], "rmgetlist")) {
        [task setLaunchPath:@"/bin/rm"];
        [args addObject:@"-r"];
        [args addObject:@"/tmp/batchomaticGetList"];
    }
    //--------------------------------------------------------------------------------------------------------------------------
    // creating a .deb of a single tweak
    else if (!strcmp(argv[1], "deb")) {
        if (argc > 2) {
            [task setLaunchPath:@"/usr/bin/bmd"];
            [args addObject:@"rmtemp"];
            [task setArguments:args];
            [task launch];
            [task waitUntilExit];

            task = [[NSTask alloc] init];
            args = [[NSMutableArray alloc] init];
            [task setLaunchPath:@"/bin/bash"];
            [args addObject:@"/Library/Batchomatic/createoffline.sh"];
            [args addObject:@"deb"];
            [args addObject:[NSString stringWithFormat:@"%s", argv[2]]];
        }
        else {
            printf("Error: you did not specify a package identifier\n");
            return 1;
        }
    }
    //--------------------------------------------------------------------------------------------------------------------------
    // installing the .deb
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
        [args addObject:@"/Library/Batchomatic/determinerepostoadd.sh"];
        [args addObject:[NSString stringWithFormat:@"%s", argv[2]]];
    }
    else if (!strcmp(argv[1], "removealltweaks")) {
        [task setLaunchPath:@"/bin/bash"];
        [args addObject:@"/Library/Batchomatic/removealltweaks.sh"];
        [args addObject:[NSString stringWithFormat:@"%s", argv[2]]];
    }
    //--------------------------------------------------------------------------------------------------------------------------
    // running each stage of creating an online deb
    else if (!strcmp(argv[1], "online")) {
        if (!strcmp(argv[2], "all")) {
            [task setLaunchPath:@"/bin/bash"];
            [args addObject:@"/Library/Batchomatic/createonline.sh"];
            [args addObject:@"all"];
        }
        else {
            // convert a string from argv[] to an int to verify that the user chose a valid step
            char *p;
            errno = 0;
            long arg = strtol(argv[2], &p, 10);
            if (*p != '\0' || errno != 0) {
                return 1;
            }
            if (arg < INT_MIN || arg > INT_MAX) {
                return 1;
            }
            int arg_int = arg;
            
            if (arg_int >= 1 && arg_int <= 10) {
                [task setLaunchPath:@"/bin/bash"];
                [args addObject:@"/Library/Batchomatic/createonline.sh"];
                [args addObject:[NSString stringWithFormat:@"%s", argv[2]]];
            }
            else {
                printf("Error: you did not pick a valid step\n");
                return 1;
            }
        }
    }
    //--------------------------------------------------------------------------------------------------------------------------
    // running each stage of creating an offline deb
    else if (!strcmp(argv[1], "offline")) {
        if (!strcmp(argv[2], "all")) {
            [task setLaunchPath:@"/bin/bash"];
            [args addObject:@"/Library/Batchomatic/createoffline.sh"];
            [args addObject:@"all"];
        }
        else {
            char *p;
            errno = 0;
            long arg = strtol(argv[2], &p, 10);
            if (*p != '\0' || errno != 0) {
                return 1;
            }
            if (arg < INT_MIN || arg > INT_MAX) {
                return 1;
            }
            int arg_int = arg;
            
            if (arg_int >= 1 && arg_int <= 10) {
                [task setLaunchPath:@"/bin/bash"];
                [args addObject:@"/Library/Batchomatic/createoffline.sh"];
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
        printf("Error: you did not specify a valid option\n");
        return 1;
    }
    
    [task setArguments:args];
    [task launch];
    [task waitUntilExit];
    
    return 0;
}

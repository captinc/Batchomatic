#include <stdio.h>
#include <string.h>
#include <dlfcn.h>
#import "NSTask.h"

#define FLAG_PLATFORMIZE (1 << 1)
void fixsetuid_electra_chimera()
{
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

int main(int argc, char *argv[], char *envp[]) {
    if (argc < 2) {
        printf("Error: you did not specify a command to run\n");
        return 1;
    }
    
    setuid(0);
    if (getuid() != 0) {
        fixsetuid_electra_chimera();
    }
    
    NSTask *task = [[NSTask alloc] init];
    NSMutableArray *args = [[NSMutableArray alloc] init];
    
    if (!strcmp(argv[1], "1")) {
        [task setLaunchPath:@"/bin/cp"];
        [args addObject:@"/etc/hosts"];
        [args addObject:@"/tmp/batchomatic/create/var/mobile/BatchInstall"];
    }
    else if (!strcmp(argv[1], "2")) {
        [task setLaunchPath:@"/bin/chmod"];
        [args addObject:@"777"];
        [args addObject:@"/tmp/batchomatic/create/var/mobile/BatchInstall/hosts"];
    }
    else if (!strcmp(argv[1], "3")) {
        [task setLaunchPath:@"/bin/mv"];
        [args addObject:@"/etc/hosts"];
        [args addObject:@"/etc/hosts-beforeBatchomatic.bak"];
    }
    else if (!strcmp(argv[1], "4")) {
        [task setLaunchPath:@"/bin/cp"];
        [args addObject:@"/var/mobile/BatchInstall/hosts"];
        [args addObject:@"/etc"];
    }
    else if (!strcmp(argv[1], "5")) {
        [task setLaunchPath:@"/bin/chmod"];
        [args addObject:@"777"];
        [args addObject:@"/etc/hosts"];
    }
    else if (!strcmp(argv[1], "6")) {
        [task setLaunchPath:@"/usr/bin/dpkg"];
        [args addObject:@"-i"];
        [args addObject:[NSString stringWithFormat:@"%s", argv[2]]];
    }
    else {
        printf("Error: you did not pick a valid command\n");
        return 1;
    }
    
    [task setArguments:args];
    [task launch];
    [task waitUntilExit];
    
    return 0;
}

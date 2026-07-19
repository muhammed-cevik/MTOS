/*
 * MT OS - Kernel Entry Point
 * Python + C tabanlı mini işletim sistemi
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>
#include <sys/utsname.h>

#define MTOS_VERSION "1.0.0"
#define MTOS_NAME    "MT OS"

void print_banner(void) {
    printf("\n");
    printf("  ███╗   ███╗████████╗ ██████╗ ███████╗\n");
    printf("  ████╗ ████║╚══██╔══╝██╔═══██╗██╔════╝\n");
    printf("  ██╔████╔██║   ██║   ██║   ██║███████╗\n");
    printf("  ██║╚██╔╝██║   ██║   ██║   ██║╚════██║\n");
    printf("  ██║ ╚═╝ ██║   ██║   ╚██████╔╝███████║\n");
    printf("  ╚═╝     ╚═╝   ╚═╝    ╚═════╝ ╚══════╝\n");
    printf("\n");
    printf("  %s v%s - Mini Terminal OS\n", MTOS_NAME, MTOS_VERSION);
    printf("  Python + C + Lua Powered\n");
    printf("  Type 'help' for commands\n");
    printf("  ─────────────────────────────────────\n\n");
}

void init_kernel(void) {
    struct utsname sys;
    uname(&sys);
    printf("[KERNEL] MT OS Kernel initializing...\n");
    printf("[KERNEL] Host: %s %s\n", sys.sysname, sys.release);
    printf("[KERNEL] Arch: %s\n", sys.machine);
    printf("[KERNEL] PID: %d\n", getpid());
    printf("[KERNEL] Kernel OK.\n\n");
}

int main(int argc, char *argv[]) {
    (void)argc;

    init_kernel();
    print_banner();

    /* argv[0] dizinini bul, shell.py'yi oradan çalıştır */
    char argv0_copy[512];
    strncpy(argv0_copy, argv[0], sizeof(argv0_copy) - 1);
    argv0_copy[sizeof(argv0_copy)-1] = '\0';
    char *dir = dirname(argv0_copy);

    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "MTOS_ROOT='%s/..' python3 '%s/../shell/shell.py'", dir, dir);

    int ret = system(cmd);
    if (ret != 0) {
        fprintf(stderr, "[KERNEL] Shell exited with code %d\n", ret);
    }

    printf("\n[KERNEL] MT OS shutting down. Goodbye!\n");
    return 0;
}

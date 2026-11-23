// claudemini-icon: tiny setuid-root helper, shipped ONLY in the rootful .deb.
// Usage: claudemini-icon <Default|SideStore|LiveContainer|Dopamine|Chimera|Sileo|Github>
//        claudemini-icon --respring        (restarts SpringBoard so the new Home Screen icon shows up)
// It copies Icon-<name>@2x/@3x.png over AppIcon60x60@2x/@3x.png inside /Applications/ClaudeMini.app and refreshes
// SpringBoard with uicache, because the normal iOS icon-switching API does not update the Home Screen for
// apps installed in /Applications. Only fixed file names inside the app folder are touched; the folder is owned by root.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <spawn.h>
#include <ftw.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/wait.h>

extern char **environ;

#define APP_DIR "/Applications/ClaudeMini.app"

static const char *kAllowed[] = { "Default", "SideStore", "LiveContainer", "Dopamine", "Chimera", "Sileo", "Github",
                                    "Default-Dark", "SideStore-Dark", "LiveContainer-Dark", "Dopamine-Dark", "Chimera-Dark", "Sileo-Dark", "Github-Dark", NULL };

static int copy_file(const char *src, const char *dst) {
    int in = open(src, O_RDONLY | O_NOFOLLOW);
    if (in < 0) return -1;
    char tmp[512];
    if (snprintf(tmp, sizeof(tmp), "%s.tmp", dst) >= (int)sizeof(tmp)) { close(in); return -1; }
    unlink(tmp);
    int out = open(tmp, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0644);
    if (out < 0) { close(in); return -1; }
    char buf[8192];
    ssize_t n;
    int ok = 1;
    while ((n = read(in, buf, sizeof(buf))) > 0) {
        if (write(out, buf, (size_t)n) != n) { ok = 0; break; }
    }
    if (n < 0) ok = 0;
    close(in);
    if (close(out) != 0) ok = 0;
    if (!ok) { unlink(tmp); return -1; }
    chmod(tmp, 0644);
    if (rename(tmp, dst) != 0) { unlink(tmp); return -1; }
    return 0;
}

static int run(const char *path, char *const argv[]) {
    pid_t pid;
    if (posix_spawn(&pid, path, NULL, NULL, argv, environ) != 0) return -1;
    int status = 0;
    while (waitpid(pid, &status, 0) < 0) {
        if (errno != EINTR) return -1;
    }
    return (WIFEXITED(status) && WEXITSTATUS(status) == 0) ? 0 : -1;
}

// Cached icons live in SpringBoard's icon cache: after the files change, the old picture can stay until the cache is
// rebuilt. Everything deleted here is a cache that iOS recreates by itself.
static int remove_entry(const char *path, const struct stat *sb, int flag, struct FTW *ftwbuf) {
    (void)sb; (void)flag; (void)ftwbuf;
    return remove(path);
}

static void remove_tree(const char *path) {
    struct stat st;
    if (lstat(path, &st) != 0) return;
    nftw(path, remove_entry, 16, FTW_DEPTH | FTW_PHYS);
}

static void touch_now(const char *path) {
    utimes(path, NULL);   // current time: tells LaunchServices that the bundle changed
}

static int respring(void) {
    char *sbreload[] = { "sbreload", NULL };
    if (access("/usr/bin/sbreload", X_OK) == 0 && run("/usr/bin/sbreload", sbreload) == 0) return 0;
    char *killer[] = { "killall", "-9", "SpringBoard", NULL };
    return run("/usr/bin/killall", killer);
}

int main(int argc, char **argv) {
    if (argc != 2) return 64;
    if (strcmp(argv[1], "--respring") == 0) {
        setgid(0);
        setuid(0);
        if (geteuid() != 0) return 77;
        setenv("PATH", "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin", 1);
        return respring() == 0 ? 0 : 3;
    }
    int allowed = 0;
    for (int i = 0; kAllowed[i]; i++) if (strcmp(argv[1], kAllowed[i]) == 0) allowed = 1;
    if (!allowed) return 65;

    setgid(0);
    setuid(0);
    if (geteuid() != 0) return 77;   // the setuid bit is missing

    static const char *scales[] = { "@2x", "@3x", NULL };
    for (int i = 0; scales[i]; i++) {
        char src[512], dst[512];
        snprintf(src, sizeof(src), APP_DIR "/Icon-%s%s.png", argv[1], scales[i]);
        snprintf(dst, sizeof(dst), APP_DIR "/AppIcon60x60%s.png", scales[i]);
        if (copy_file(src, dst) != 0) return 1;
    }

    // Make the change visible to iOS: new modification times and a fresh icon cache.
    touch_now(APP_DIR "/AppIcon60x60@2x.png");
    touch_now(APP_DIR "/AppIcon60x60@3x.png");
    touch_now(APP_DIR "/Info.plist");
    touch_now(APP_DIR);
    remove_tree("/var/mobile/Library/Caches/com.apple.IconsCache");
    remove_tree("/var/mobile/Library/Caches/MappedImageCache/Persistent");

    setenv("PATH", "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin", 1);
    char *with_path[] = { "uicache", "-p", APP_DIR, NULL };
    if (run("/usr/bin/uicache", with_path) != 0) {
        char *plain[] = { "uicache", NULL };
        if (run("/usr/bin/uicache", plain) != 0) return 2;
    }
    char *agent[] = { "killall", "-9", "iconservicesagent", NULL };
    run("/usr/bin/killall", agent);   // best effort: it rebuilds its cache from the new files
    return 0;
}

#ifndef __KSU_H_KSU
#define __KSU_H_KSU

#include <linux/version.h>
#include <linux/types.h>
#include <linux/cred.h>
#include <linux/workqueue.h>
#include <linux/fs.h>
#include <linux/input.h>

#define KERNEL_SU_VERSION KSU_VERSION
#define KERNEL_SU_OPTION 0xDEADBEEF

extern struct cred *ksu_cred;
extern bool ksu_late_loaded;
extern bool allow_shell;
#ifdef MODULE
extern bool ksu_bundled;
#endif
extern bool ksu_no_custom_rc;

#if LINUX_VERSION_CODE >= KERNEL_VERSION(5, 10, 0) || defined(KSU_COMPAT_HAS_SELINUX_POLICY_STRUCT)
extern struct selinux_policy *backup_sepolicy;
#else
extern struct policydb *backup_policydb;
extern struct sidtab *backup_sidtab;
#endif

// kernel su version full strings
#ifndef KSU_VERSION_FULL
#define KSU_VERSION_FULL "v3.x-00000000@unknown"
#endif
#define KSU_FULL_VERSION_STRING 255

void setup_ksu_cred(void);

// Manual hook function declarations - matching bakasu guide exactly
#ifdef CONFIG_KSU_MANUAL_HOOK
// stat hooks - take pointers for su path redirection
#ifdef CONFIG_KSU_SUSFS
extern __attribute__((hot)) int ksu_handle_stat(int *dfd, struct filename **filename, int *flags);
extern int ksu_handle_faccessat(int *dfd, struct filename **filename, int *mode, int *__unused_flags);
#else
extern __attribute__((hot)) int ksu_handle_stat(int *dfd, const char __user **filename_user, int *flags);
extern int ksu_handle_faccessat(int *dfd, const char __user **filename_user, int *mode, int *flags);
#endif
extern void ksu_handle_newfstat_ret(unsigned int *fd, struct stat __user **statbuf_ptr);
#if defined(__ARCH_WANT_STAT64) || defined(__ARCH_WANT_COMPAT_STAT64)
extern void ksu_handle_fstat64_ret(unsigned long *fd, struct stat64 __user **statbuf_ptr);
#endif

// execve hooks - take pointers
extern int ksu_handle_execveat(int *fd, struct filename **filename_ptr, void *argv, void *envp, int *flags);
extern int ksu_handle_post_execveat(int *fd, struct filename **filename_ptr, void *argv, void *envp, int *flags, int *retval);

// sys_reboot hook
extern int ksu_handle_sys_reboot(int magic1, int magic2, unsigned int cmd, void __user **arg);

// input hooks
extern bool ksu_input_hook __read_mostly;
extern __attribute__((cold)) int ksu_handle_input_handle_event(unsigned int *type, unsigned int *code, int *value);
#endif

#endif

import Foundation
import UIKit
import MachO

class SecurityUtils {

    static func isDeviceCompromised() -> Bool {
        return isJailbroken() || isDebuggerAttached()
    }

    // Finding 2: Robust Jailbreak Detection
    static func isJailbroken() -> Bool {
        // Always return false for simulators to avoid false positives during development
        #if targetEnvironment(simulator)
        return false
        #endif

        // 1. Check for suspicious files and apps
        let paths = [
            "/Applications/Cydia.app",
            "/Applications/FakeCarrier.app",
            "/Applications/Icy.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/bin/sh",
            "/etc/apt",
            "/etc/ssh/sshd_config",
            "/private/var/lib/apt/",
            "/usr/bin/ssh",
            "/usr/libexec/sftp-server",
            "/usr/libexec/ssh-keysign",
            "/usr/sbin/sshd",
            "/var/cache/apt",
            "/var/lib/apt",
            "/var/lib/cydia",
            "/var/log/syslog",
            "/usr/local/bin/cycript",
            "/usr/lib/libcycript.dylib"
        ]

        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }

        // 2. Check for suspicious URL schemes
        // Note: Requires LSApplicationQueriesSchemes in Info.plist
        let urlSchemes = ["cydia://", "sileo://", "zbra://", "undecimus://"]
        for scheme in urlSchemes {
            if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                return true
            }
        }

        // 3. Sandbox Violation: Try to write outside the sandbox
        let jailbreakTestPath = "/private/jailbreak_test.txt"
        do {
            try "Jailbreak Test".write(toFile: jailbreakTestPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: jailbreakTestPath)
            return true
        } catch {
            // Correct behavior: should fail to write to system directories
        }

        // 4. Check for Symbolic Links (Sandbox escape detection)
        // On jailbroken devices, /Applications is often a symlink to save space.
        var s = stat()
        if lstat("/Applications", &s) == 0 {
            if (s.st_mode & S_IFLNK) != 0 {
                return true
            }
        }

        return false
    }

    // Finding 3: Debugger Detection (Anti-Tampering)
    static func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        let res = sysctl(&mib, 4, &info, &size, nil, 0)
        if res != 0 {
            return false
        }
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    // Finding 4: Screen Recording Detection helper
    static func isScreenBeingCaptured() -> Bool {
        return UIScreen.main.isCaptured
    }
}

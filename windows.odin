#+build windows
package microfetch

import "base:intrinsics"
import "core:os"
import "core:fmt"
import "core:unicode"
import "core:unicode/utf8"
import "core:strings"
import win "core:sys/windows"

foreign import kernel "system:kernel32.lib";
foreign import advapi "system:advapi32.lib"

DISK_SPACE_INFORMATION :: struct {
    ActualTotalAllocationUnits: u64,
    ActualAvailableAllocationUnits: u64,
    ActualPoolUnavailableAllocationUnits: u64,
    CallerTotalAllocationUnits: u64,
    CallerAvailableAllocationUnits: u64,
    CallerPoolUnavailableAllocationUnits: u64,
    UsedAllocationUnits: u64,
    TotalReservedAllocationUnits: u64,
    VolumeStorageReserveAllocationUnits: u64,
    AvailableCommittedAllocationUnits: u64,
    PoolAvailableAllocationUnits: u64,
    SectorsPerAllocationUnit: u32,
    BytesPerSector: u32,
}

foreign kernel {
    QueryUnbiasedInterruptTime :: proc(interrupt_time: ^u64) -> win.BOOL ---
    GetComputerNameW :: proc(buffer: ^win.wstring, size: ^u32) -> win.BOOL ---
    QueryFullProcessImageNameA :: proc(h_process: win.HANDLE, flags: u32, exe_name: win.LPSTR, size: ^u32) -> win.BOOL ---
    GetDiskSpaceInformationW :: proc(root_path: win.LPWSTR, disk_space_info: ^DISK_SPACE_INFORMATION) -> win.HRESULT ---
}

foreign advapi {
    GetUserNameW :: proc(buffer: ^win.wstring, size: ^u32) -> win.BOOL ---
}

// We do not free these to increase speed.
// Windows will automatically release them.
ntdll_hmod: win.HMODULE
winbrand_hmod: win.HMODULE


Rtl_Get_Nt_Version_Numbers :: proc "system"(minor_version, major_version, build_number: ^u32)
rtl_get_nt_version_numbers: Rtl_Get_Nt_Version_Numbers

Branding_Format_String :: proc "system"(format: win.PCWSTR) -> win.PWSTR
branding_format_string: Branding_Format_String

@init
_win_init :: proc() {
    win.SetConsoleOutputCP(.UTF8)

    ntdll_hmod = win.LoadLibraryW(intrinsics.constant_utf16_cstring("ntdll.dll"))
    if ntdll_hmod == {} {
        fmt.printfln("Could not load ntdll.dll: %v", win.GetLastError())
        // os.exit(1)
    } else {
        rtl_get_nt_version_numbers = cast(Rtl_Get_Nt_Version_Numbers)win.GetProcAddress(ntdll_hmod, "RtlGetNtVersionNumbers")
        if rtl_get_nt_version_numbers == nil {
            fmt.printfln("Could not get RtlGetNtVersionNumbers: %v", win.GetLastError())
            // os.exit(1)
        }
    }

    winbrand_hmod = win.LoadLibraryW(intrinsics.constant_utf16_cstring("winbrand.dll"))
    if winbrand_hmod == {} {
        fmt.printfln("Could not load winbrand.dll: %v", win.GetLastError())
        // os.exit(1)
    } else {
        branding_format_string = cast(Branding_Format_String)win.GetProcAddress(winbrand_hmod, "BrandingFormatString")
        if branding_format_string == nil {
            fmt.printfln("Could not get BrandingFormatString: %v", win.GetLastError())
            // os.exit(1)
        }
    }
}

get_os_pretty_name :: proc() -> (res: string) {
    if branding_format_string == nil {
        return "Failed"
    }

    os_name := branding_format_string("%WINDOWS_LONG%")
    defer win.GlobalFree(cast(rawptr)os_name)

    res, _ = win.wstring_to_utf8(os_name, len(os_name))
    return
}

get_system_info :: proc() -> string {
    if rtl_get_nt_version_numbers == nil {
        return "Failed"
    }

    major_version, minor_version, build_number: u32
    rtl_get_nt_version_numbers(&major_version, &minor_version, &build_number)

    return fmt.tprintf("NT v{}.{}.{}", major_version, minor_version, build_number & 0x0FFFFFFF)
}

get_uptime_seconds :: proc() -> (uptime: u64) {
    // NOTE(robin): This apparently cannot fail
    assert(bool(QueryUnbiasedInterruptTime(&uptime)))
    return uptime / 10000 / 1000
}

get_desktop :: proc() -> string {
    return "dwm.exe (Desktop Window Manager)"
}

MAX_COMPUTERNAME_LENGTH :: 15

_get_username_and_hostname :: proc() -> (username: string, hostname: string) {
    wrapper :: proc($N: int, p: proc "c"(buffer: ^win.wstring, size: ^u32) -> win.BOOL) -> string {
        buffer: [N]u16
        size := u32(N)

        if !p(cast(^win.wstring)&buffer[0], &size) {
            return "Not enough space"
        }
        out, _ := win.utf16_to_utf8(buffer[:size])
        return out
    }

    HOSTNAME_SIZE :: MAX_COMPUTERNAME_LENGTH + 1
    hostname = wrapper(HOSTNAME_SIZE, GetComputerNameW)
    UNLEN :: 256 + 1
    username = wrapper(UNLEN, GetUserNameW)
    return
}

string_compare_lower :: proc(l, r: string) -> bool {
    r_pos := 0
    for l_r in l {
        if r_pos >= len(r) {
            return false
        }
        r_r, w := utf8.decode_rune_in_string(r[r_pos:])
        r_pos += w
        if unicode.to_lower(l_r) != unicode.to_lower(r_r) {
            return false
        }
    }

    return true
}

get_shell :: proc() -> (name: string) {
    pid: u32
    ppid: u32

    for {
        h_process := win.GetCurrentProcess() if pid == 0 else win.OpenProcess(win.PROCESS_QUERY_LIMITED_INFORMATION, false, pid)

        if h_process == nil {
            return
        }

        info: win.PROCESS_BASIC_INFORMATION
        size: u32
        if win.NtQueryInformationProcess(h_process, .ProcessBasicInformation, &info, u32(size_of(info)), &size) == 0 /* Success */ {
            assert(size == size_of(info))
            ppid = u32(info.InheritedFromUniqueProcessId)
        }

        exe_buffer: [2028]u8
        size = len(exe_buffer)
        if !QueryFullProcessImageNameA(h_process, 0, &exe_buffer[0], &size) {
            return name
        }

        exe := string(exe_buffer[:size])
        exe = strings.trim_suffix(exe, ".exe")
        last_path := strings.last_index_byte(exe, '\\')
        if last_path != -1 {
            exe = exe[last_path + 1:]
        }
        name = strings.clone(exe, context.temp_allocator)

        if string_compare_lower(name, "microfetch") || string_compare_lower(name, "odin") {
            pid = ppid
            continue
        }
        break
    }

    return
}

_get_root_disk_usage :: proc() -> (total_size, used_size: u64) {
    disk_space_info: DISK_SPACE_INFORMATION

    result := GetDiskSpaceInformationW(nil, &disk_space_info)

    total_size = disk_space_info.ActualTotalAllocationUnits *
        u64(disk_space_info.SectorsPerAllocationUnit) *
        u64(disk_space_info.BytesPerSector)

    used_size = (disk_space_info.ActualTotalAllocationUnits - disk_space_info.ActualAvailableAllocationUnits) *
        u64(disk_space_info.SectorsPerAllocationUnit) *
        u64(disk_space_info.BytesPerSector)
    return
}

_get_memory_usage :: proc() -> (total_memory, used_memory: u64) {
    memory_status_ex := win.MEMORYSTATUSEX {
        dwLength = size_of(win.MEMORYSTATUSEX),
    }

    win.GlobalMemoryStatusEx(&memory_status_ex)

    return memory_status_ex.ullTotalPhys, memory_status_ex.ullTotalPhys - memory_status_ex.ullAvailPhys
}

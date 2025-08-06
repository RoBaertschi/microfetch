#+build windows
package microfetch

import "base:intrinsics"
import "core:os"
import "core:fmt"
import win "core:sys/windows"

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
        os.exit(1)
    }

    rtl_get_nt_version_numbers = cast(Rtl_Get_Nt_Version_Numbers)win.GetProcAddress(ntdll_hmod, "RtlGetNtVersionNumbers")
    if rtl_get_nt_version_numbers == {} {
        fmt.printfln("Could not get RtlGetNtVersionNumbers: %v", win.GetLastError())
        os.exit(1)
    }

    winbrand_hmod = win.LoadLibraryW(intrinsics.constant_utf16_cstring("winbrand.dll"))
    if winbrand_hmod == {} {
        fmt.printfln("Could not load winbrand.dll: %v", win.GetLastError())
        os.exit(1)
    }

    branding_format_string = cast(Branding_Format_String)win.GetProcAddress(winbrand_hmod, "BrandingFormatString")
    if branding_format_string == {} {
        fmt.printfln("Could not get BrandingFormatString: %v", win.GetLastError())
        os.exit(1)
    }
}

get_os_pretty_name :: proc() {
}

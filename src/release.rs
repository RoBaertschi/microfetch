use std::{ffi::c_void, mem::transmute};
use windows::{
    Win32::{
        Foundation::{FreeLibrary, GlobalFree, HGLOBAL},
        System::LibraryLoader::{GetProcAddress, LoadLibraryA},
    },
    core::{PCWSTR, PWSTR},
};
use windows_strings::{s, w};

type PfnRtlGetNtVersionNumbers = unsafe extern "system" fn(
    major_version: *mut u32,
    minor_version: *mut u32,
    build_number: *mut u32,
);

pub fn get_system_info() -> windows::core::Result<String> {
    let hmod = unsafe { LoadLibraryA(s!("ntdll.dll"))? };
    let rtl_get_nt_version_numbers: Option<PfnRtlGetNtVersionNumbers> =
        unsafe { GetProcAddress(hmod, s!("RtlGetNtVersionNumbers")).map(|p| transmute(p)) };

    if let Some(rtl_get_nt_version_numbers) = rtl_get_nt_version_numbers {
        let mut major_version: u32 = 0;
        let mut minor_version: u32 = 0;
        let mut build_number: u32 = 0;

        unsafe {
            rtl_get_nt_version_numbers(&mut major_version, &mut minor_version, &mut build_number)
        };

        // NOTE(robin): build_number <= 10000 < 20000 is Windows 10
        let version = format!(
            "NT v{major_version}.{minor_version}.{}",
            build_number & 0x0FFFFFFF
        );
        unsafe {
            _ = FreeLibrary(hmod);
        }

        return Ok(version);
    }
    unsafe {
        _ = FreeLibrary(hmod);
    }
    Ok("Unknown".to_string())
}

type PfnBrandingFormatString = unsafe extern "system" fn(PCWSTR) -> PWSTR;

pub fn get_os_pretty_name() -> windows::core::Result<String> {
    let hmod = unsafe { LoadLibraryA(s!("winbrand.dll"))? };
    let branding_fromat_string: Option<PfnBrandingFormatString> =
        unsafe { GetProcAddress(hmod, s!("BrandingFormatString")).map(|p| transmute(p)) };

    if let Some(branding_fromat_string) = branding_fromat_string {
        let os_name = unsafe { branding_fromat_string(w!("%WINDOWS_LONG%")) };

        let os_name_str =
            unsafe { os_name.to_string() }.unwrap_or("could not get windows name".to_string());
        unsafe {
            _ = GlobalFree(Some(HGLOBAL(os_name.0 as *mut c_void)));
        }
        unsafe {
            _ = FreeLibrary(hmod);
        }

        return Ok(os_name_str);
    }
    unsafe {
        _ = FreeLibrary(hmod);
    }
    Ok("Unknown".to_string())
}

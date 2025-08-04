use std::{
    ffi::c_void,
    mem::transmute,
};
use windows::{
    Win32::{
        Foundation::{FreeLibrary, GlobalFree, HGLOBAL},
        System::LibraryLoader::{GetProcAddress, LoadLibraryA},
    },
    core::{PCWSTR, PWSTR},
};
use windows_strings::{s, w};

pub fn get_system_info() -> String {
    // format!(
    //     "{} {} ({})",
    //     utsname.sysname().to_str().unwrap_or("Unknown"),
    //     utsname.release().to_str().unwrap_or("Unknown"),
    //     utsname.machine().to_str().unwrap_or("Unknown")
    // )
    // todo!("is this kernel info?")
    "Nothing".to_string()
}

type PfnBrandingFormatString = unsafe extern "system" fn(PCWSTR) -> PWSTR;

pub fn get_os_pretty_name() -> windows::core::Result<String> {
    let hmod = unsafe { LoadLibraryA(s!("winbrand.dll"))? };
    let branding_fromat_string: Option<PfnBrandingFormatString> =
        unsafe { GetProcAddress(hmod, s!("")).map(|p| transmute(p)) };

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

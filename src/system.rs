use crate::colors::COLORS;
use windows::Win32::NetworkManagement::NetManagement::UNLEN;
use windows::Win32::System::SystemInformation::ComputerNameNetBIOS;
use windows::{
    Win32::{
        Storage::FileSystem::{DISK_SPACE_INFORMATION, GetDiskSpaceInformationW},
        System::{
            SystemInformation::{
                GetComputerNameExW, GlobalMemoryStatusEx, MEMORYSTATUSEX,
            },
            WindowsProgramming::GetUserNameW,
        },
    },
    core::PWSTR,
};

pub fn get_username_and_hostname() -> String {
    const HOSTNAME_SIZE: usize = 2048;
    let mut hostname: [u16; HOSTNAME_SIZE] = [0; HOSTNAME_SIZE];
    let mut size = HOSTNAME_SIZE as u32;

    unsafe {
        _ = GetComputerNameExW(
            ComputerNameNetBIOS,
            Some(PWSTR::from_raw(&mut hostname[0])),
            &mut size,
        )
    };
    let hostname = unsafe { PWSTR::from_raw(&mut hostname[0]).to_string() }
        .unwrap_or("invalid_hostname".to_owned());

    let mut username: [u16; UNLEN as usize] = [0; UNLEN as usize];
    size = UNLEN;

    unsafe {
        _ = GetUserNameW(Some(PWSTR::from_raw(&mut username[0])), &mut size);
    }
    let username = unsafe { PWSTR::from_raw(&mut username[0]).to_string() }
        .unwrap_or("invalid_username".to_owned());

    format!(
        "{yellow}{username}{red}@{green}{hostname}{reset}",
        yellow = COLORS.yellow,
        red = COLORS.red,
        green = COLORS.green,
        reset = COLORS.reset,
    )
}

pub fn get_shell() -> String {
    // TODO(robin): detect the shell correctly
    "cmd.exe".to_string()
}

pub fn get_root_disk_usage() -> windows::core::Result<String> {
    let mut disk_space_info = DISK_SPACE_INFORMATION::default();

    unsafe {
        // NOTE(robin): null means the root file system
        GetDiskSpaceInformationW(PWSTR::null(), &mut disk_space_info)?;
    }

    let total_size = disk_space_info.ActualTotalAllocationUnits
        * disk_space_info.SectorsPerAllocationUnit as u64
        * disk_space_info.BytesPerSector as u64;
    let used_size = disk_space_info.UsedAllocationUnits
        * disk_space_info.SectorsPerAllocationUnit as u64
        * disk_space_info.BytesPerSector as u64;

    let total_size = total_size as f64 / (1024.0 * 1024.0 * 1024.0);
    let used_size = used_size as f64 / (1024.0 * 1024.0 * 1024.0);
    let usage = (used_size / total_size) * 100.0;

    Ok(format!(
        "{used_size:.2} GiB / {total_size:.2} GiB ({cyan}{usage:.0}%{reset})",
        cyan = COLORS.cyan,
        reset = COLORS.reset,
    ))
}

pub fn get_memory_usage() -> windows::core::Result<String> {
    let mut memory_status_ex = MEMORYSTATUSEX {
        dwLength: size_of::<MEMORYSTATUSEX>() as u32,
        ..MEMORYSTATUSEX::default()
    };

    unsafe {
        GlobalMemoryStatusEx(&mut memory_status_ex)?;
    }

    let total_memory_kb = memory_status_ex.ullTotalPhys as f64 / 1024.0;
    let available_memory_kb = memory_status_ex.ullAvailPhys as f64 / 1024.0;

    let total_memory = total_memory_kb / 1024.0 / 1024.0;
    let available_memory_gb = available_memory_kb / 1024.0 / 1024.0;
    let used_memory = total_memory - available_memory_gb;

    let percentage_used = (used_memory / total_memory * 100.0).round() as u64;

    Ok(format!(
        "{used_memory:.2} GiB / {total_memory:.2} GiB ({cyan}{percentage_used}%{reset})",
        cyan = COLORS.cyan,
        reset = COLORS.reset,
    ))
}

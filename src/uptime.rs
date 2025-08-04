use std::io;

use windows::Win32::System::WindowsProgramming::QueryUnbiasedInterruptTime;

pub fn get_current() -> Result<String, io::Error> {
    let mut uptime: u64 = 0;

    if !unsafe { QueryUnbiasedInterruptTime(&mut uptime) }.as_bool() {
        return Ok("invalid_uptime".to_string());
    }

    let uptime_seconds = uptime / 10000 / 1000;

    let days = uptime_seconds / 86400;
    let hours = (uptime_seconds / 3600) % 24;
    let minutes = (uptime_seconds / 60) % 60;

    let mut result = String::with_capacity(32);
    if days > 0 {
        result.push_str(&days.to_string());
        result.push_str(if days == 1 { " day" } else { " days" });
    }
    if hours > 0 {
        if !result.is_empty() {
            result.push_str(", ");
        }
        result.push_str(&hours.to_string());
        result.push_str(if hours == 1 { " hour" } else { " hours" });
    }
    if minutes > 0 {
        if !result.is_empty() {
            result.push_str(", ");
        }
        result.push_str(&minutes.to_string());
        result.push_str(if minutes == 1 { " minute" } else { " minutes" });
    }
    if result.is_empty() {
        result.push_str("less than a minute");
    }

    Ok(result)
}

mod colors;
mod desktop;
mod release;
mod system;
mod uptime;

use crate::colors::print_dots;
use crate::desktop::get_desktop_info;
use crate::release::{get_os_pretty_name, get_system_info};
use crate::system::{get_memory_usage, get_root_disk_usage, get_shell, get_username_and_hostname};
use crate::uptime::get_current;
use std::io::{Write, stdout};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    if Some("--version") == std::env::args().nth(1).as_deref() {
        println!("Microfetch {}", env!("CARGO_PKG_VERSION"));
    } else {
        let fields = Fields {
            user_info: get_username_and_hostname(),
            os_name: get_os_pretty_name().unwrap_or_else(|e| format!("no os name {e}")),
            kernel_version: get_system_info().unwrap_or_else(|e| format!("no kernel version {e}")),
            shell: get_shell(),
            desktop: get_desktop_info(),
            uptime: get_current().unwrap_or_else(|e| format!("no uptime {e}")),
            memory_usage: get_memory_usage().unwrap_or_else(|e| format!("no memory usage {e}")),
            storage: get_root_disk_usage().unwrap_or_else(|e| format!("no disk usage {e}")),
            colors: print_dots(),
        };
        print_system_info(&fields)?;
    }

    Ok(())
}

// Struct to hold all the fields we need in order to print the fetch. This
// helps avoid Clippy warnings about argument count, and makes it slightly
// easier to pass data around. Though, it is not like we really need to.
struct Fields {
    user_info: String,
    os_name: String,
    kernel_version: String,
    shell: String,
    uptime: String,
    desktop: String,
    memory_usage: String,
    storage: String,
    colors: String,
}

fn print_system_info(fields: &Fields) -> Result<(), Box<dyn std::error::Error>> {
    use crate::colors::COLORS;

    let Fields {
        user_info,
        os_name,
        kernel_version,
        shell,
        uptime,
        desktop,
        memory_usage,
        storage,
        colors,
    } = fields;

    let cyan = COLORS.cyan;
    let blue = COLORS.blue;
    let reset = COLORS.reset;
    let system_info = format!(
        "
    {blue}▄▄▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄▄▄    {user_info} ~{reset}
    {blue}█████████ █████████    {cyan}  {blue}System{reset}        {os_name}
    {blue}█████████ █████████    {cyan}  {blue}Kernel{reset}        {kernel_version}
    {blue}█████████ █████████    {cyan}  {blue}Shell{reset}         {shell}
    {blue}▀▀▀▀▀▀▀▀▀ ▀▀▀▀▀▀▀▀▀    {cyan}  {blue}Uptime{reset}        {uptime}
    {blue}█████████ █████████    {cyan}  {blue}Desktop{reset}       {desktop}
    {blue}█████████ █████████    {cyan}  {blue}Memory{reset}        {memory_usage}
    {blue}█████████ █████████    {cyan}󱥎  {blue}Storage (/){reset}   {storage}
    {blue}█████████ █████████    {cyan}  {blue}Colors{reset}        {colors}\n"
    );
    Ok(stdout().write_all(system_info.as_bytes())?)
}

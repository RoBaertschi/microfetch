package microfetch

import "base:runtime"
import "core:os"
import "core:os/os2"
import "core:strings"
import "core:fmt"
import vmem "core:mem/virtual"

get_uptime :: proc() -> string {
    uptime_seconds := get_uptime_seconds()
    days := uptime_seconds / 86400
    hours := (uptime_seconds / 3600) % 24
    minutes := (uptime_seconds / 60) % 60

    sb := strings.builder_make_len_cap(0, 32, context.temp_allocator)

    if days > 0 {
        strings.write_u64(&sb, days)
        strings.write_string(&sb, " day" if days == 1 else " days")
    }

    if hours > 0 {
        if strings.builder_len(sb) > 0 {
            strings.write_string(&sb, ", ")
        }
        strings.write_u64(&sb, hours)
        strings.write_string(&sb, " hour" if hours == 1 else " hours")
    }

    if minutes > 0 {
        if strings.builder_len(sb) > 0 {
            strings.write_string(&sb, ", ")
        }
        strings.write_u64(&sb, minutes)
        strings.write_string(&sb, " minute" if minutes == 1 else " minutes")
    }

    if strings.builder_len(sb) <= 0 {
        strings.write_string(&sb, "less than a minute")
    }

    return strings.to_string(sb)
}

get_username_and_hostname :: proc() -> string {
    username, hostname := _get_username_and_hostname()

    return fmt.tprintf("{}{}{}@{}{}{}", COLORS.yellow, username, COLORS.reset, COLORS.green, hostname, COLORS.reset)
}

bytes_to_gigabytes :: proc(bytes: u64) -> f64 {
    return f64(bytes) / runtime.Gigabyte
}

get_root_disk_usage :: proc() -> string {
    total_size, used_size := _get_root_disk_usage()

    return fmt.tprintf("{:M} / {:M} ({}{:.0f}%%{})", used_size, total_size, COLORS.cyan, (f64(used_size) / f64(total_size) * 100), COLORS.reset)
}

get_memory_usage :: proc() -> string {
    total_memory, used_memory := _get_memory_usage()

    return fmt.tprintf("{:M} / {:M} ({}{:.0f}%%{})",
        used_memory,
        total_memory,
        COLORS.cyan, (f64(used_memory) / f64(total_memory) * 100), COLORS.reset
    )
}

arena_buffer: [64 * runtime.Kilobyte]byte

main :: proc() {
    arena: vmem.Arena
    err := vmem.arena_init_buffer(&arena, arena_buffer[:])
    if err != nil {
        fmt.println(err)
        return
    }
    context.temp_allocator = vmem.arena_allocator(&arena)
    context.allocator = context.temp_allocator

    user_info := get_username_and_hostname()
    os_name := get_os_pretty_name()
    kernel_version := get_system_info()
    shell := get_shell()
    uptime := get_uptime()
    desktop := get_desktop()
    memory_usage := get_memory_usage()
    storage := get_root_disk_usage()
    dots := print_dots()


    fmt.printfln(
        `{0}    ▄▄▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄▄▄    {3} ~{2}
    {0}█████████ █████████    {1}  {0}System{2}        {4}
    {0}█████████ █████████    {1}  {0}Kernel{2}        {5}
    {0}█████████ █████████    {1}  {0}Shell{2}         {6}
    {0}▀▀▀▀▀▀▀▀▀ ▀▀▀▀▀▀▀▀▀    {1}  {0}Uptime{2}        {7}
    {0}█████████ █████████    {1}  {0}Desktop{2}       {8}
    {0}█████████ █████████    {1}  {0}Memory{2}        {9}
    {0}█████████ █████████    {1}󱥎  {0}Storage (/){2}   {10}
    {0}█████████ █████████    {1}  {0}Colors{2}        {11}
        `, COLORS.blue, COLORS.cyan, COLORS.reset, user_info, os_name, kernel_version, shell, uptime, desktop, memory_usage, storage, dots
    )
}

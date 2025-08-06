package microfetch

import "core:fmt"
import "core:terminal"
import "core:terminal/ansi"

Colors :: struct {
    reset:   string,
    blue:    string,
    cyan:    string,
    green:   string,
    yellow:  string,
    red:     string,
    magenta: string,
}

COLORS: Colors

@init
init_colors :: proc() {
    if terminal.color_enabled {
        COLORS = {
            reset   = ansi.CSI + ansi.RESET      + ansi.SGR,
            blue    = ansi.CSI + ansi.FG_BLUE    + ansi.SGR,
            cyan    = ansi.CSI + ansi.FG_CYAN    + ansi.SGR,
            green   = ansi.CSI + ansi.FG_GREEN   + ansi.SGR,
            yellow  = ansi.CSI + ansi.FG_YELLOW  + ansi.SGR,
            red     = ansi.CSI + ansi.FG_RED     + ansi.SGR,
            magenta = ansi.CSI + ansi.FG_MAGENTA + ansi.SGR,
        }
    }
}

print_dots :: proc() -> string {
    return fmt.tprintf(
        "{}  {}  {}  {}  {}  {}  {}",
        COLORS.blue,
        COLORS.cyan,
        COLORS.green,
        COLORS.yellow,
        COLORS.red,
        COLORS.magenta,
        COLORS.reset,
    )
}

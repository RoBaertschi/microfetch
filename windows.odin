#+build windows
package microfetch

import win "core:sys/windows"

@init
_win_init :: proc() {
    win.SetConsoleOutputCP(.UTF8)
}

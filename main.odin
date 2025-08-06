package microfetch

import "core:os"
import "core:os/os2"
import "core:fmt"


main :: proc() {
    dots := print_dots()
    fmt.println(dots)
}

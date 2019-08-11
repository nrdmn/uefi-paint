const uefi = @import("std").os.uefi;
const AbsolutePointerProtocol = uefi.protocols.AbsolutePointerProtocol;
const AbsolutePointerState = uefi.protocols.AbsolutePointerState;
const GraphicsOutputProtocol = uefi.protocols.GraphicsOutputProtocol;
const GraphicsOutputBltPixel = uefi.protocols.GraphicsOutputBltPixel;
const GraphicsOutputBltOperation = uefi.protocols.GraphicsOutputBltOperation;

pub fn main() void {
    const boot_services = uefi.system_table.boot_services.?;
    var pointer: *AbsolutePointerProtocol = undefined;
    var graphics: *GraphicsOutputProtocol = undefined;
    var pointer_state = AbsolutePointerState{};
    var selected: u8 = 0;
    const colors = [16]GraphicsOutputBltPixel{
        GraphicsOutputBltPixel{ .blue = 0x00, .green = 0x00, .red = 0x00, .reserved = 0 },
        GraphicsOutputBltPixel{ .blue = 0xaa, .green = 0x00, .red = 0x00, .reserved = 0 },
        GraphicsOutputBltPixel{ .blue = 0x00, .green = 0xaa, .red = 0x00, .reserved = 0 },
        GraphicsOutputBltPixel{ .blue = 0xaa, .green = 0xaa, .red = 0x00, .reserved = 0 },
        GraphicsOutputBltPixel{ .blue = 0x00, .green = 0x00, .red = 0xaa, .reserved = 0 },
        GraphicsOutputBltPixel{ .blue = 0xaa, .green = 0x00, .red = 0xaa, .reserved = 0 },
        GraphicsOutputBltPixel{ .blue = 0x00, .green = 0x55, .red = 0xaa, .reserved = 0 },
        GraphicsOutputBltPixel{ .blue = 0xaa, .green = 0xaa, .red = 0xaa, .reserved = 0 },
        GraphicsOutputBltPixel{ .blue = 0x55, .green = 0x55, .red = 0x55, .reserved = 0 },
        GraphicsOutputBltPixel{ .blue = 0xff, .green = 0x55, .red = 0x55, .reserved = 0 },
        GraphicsOutputBltPixel{ .blue = 0x55, .green = 0xff, .red = 0x55, .reserved = 0 },
        GraphicsOutputBltPixel{ .blue = 0xff, .green = 0xff, .red = 0x55, .reserved = 0 },
        GraphicsOutputBltPixel{ .blue = 0x55, .green = 0x55, .red = 0xff, .reserved = 0 },
        GraphicsOutputBltPixel{ .blue = 0xff, .green = 0x55, .red = 0xff, .reserved = 0 },
        GraphicsOutputBltPixel{ .blue = 0x55, .green = 0xff, .red = 0xff, .reserved = 0 },
        GraphicsOutputBltPixel{ .blue = 0xff, .green = 0xff, .red = 0xff, .reserved = 0 },
    };

    // Disable watchdog
    _ = boot_services.setWatchdogTimer(0, 0, 0, null);

    // Set pointers to protocols
    _ = boot_services.locateProtocol(&AbsolutePointerProtocol.guid, null, @ptrCast(*?*c_void, &pointer));
    _ = boot_services.locateProtocol(&GraphicsOutputProtocol.guid, null, @ptrCast(*?*c_void, &graphics));

    // Draw color picker in the uppermost 16th of screen
    var i: u8 = 0;
    while (i < 16) : (i += 1) {
        var c = [1]GraphicsOutputBltPixel{colors[i]};
        _ = graphics.blt(&c, GraphicsOutputBltOperation.BltVideoFill, 0, 0, i * graphics.mode.info.horizontal_resolution / 16, 0, graphics.mode.info.horizontal_resolution / 16, graphics.mode.info.vertical_resolution / 16, 0);
    }

    var index: usize = undefined;
    while (boot_services.waitForEvent(1, @ptrCast([*]uefi.Event, &pointer.wait_for_input), &index) == 0) {
        _ = pointer.getState(&pointer_state);
        if (graphics.mode.info.vertical_resolution * pointer_state.current_y / (pointer.mode.absolute_max_y - pointer.mode.absolute_min_y) < graphics.mode.info.vertical_resolution / 16) {
            // If the color picker has been touched, set selected color
            selected = @intCast(u8, 16 * pointer_state.current_x / (pointer.mode.absolute_max_x - pointer.mode.absolute_min_x + 1));
        } else if (graphics.mode.info.horizontal_resolution * pointer_state.current_x / (pointer.mode.absolute_max_x - pointer.mode.absolute_min_x) >= 2 and graphics.mode.info.horizontal_resolution * pointer_state.current_x / (pointer.mode.absolute_max_x - pointer.mode.absolute_min_x) < graphics.mode.info.horizontal_resolution - 2 and graphics.mode.info.vertical_resolution * pointer_state.current_y / (pointer.mode.absolute_max_y - pointer.mode.absolute_min_y) < graphics.mode.info.vertical_resolution - 2) {
            // Else if touch was at least 2 pixels into the drawing area, draw
            var c = [1]GraphicsOutputBltPixel{colors[selected]};
            _ = graphics.blt(&c, GraphicsOutputBltOperation.BltVideoFill, 0, 0, graphics.mode.info.horizontal_resolution * pointer_state.current_x / (pointer.mode.absolute_max_x - pointer.mode.absolute_min_x) - 2, graphics.mode.info.vertical_resolution * pointer_state.current_y / (pointer.mode.absolute_max_y - pointer.mode.absolute_min_y) - 2, 5, 5, 0);
        }
    }
}

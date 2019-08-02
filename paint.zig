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
    var pointer_state = AbsolutePointerState.init();
    var color = [1]GraphicsOutputBltPixel{GraphicsOutputBltPixel{
        .blue = 0,
        .green = 0,
        .red = 0,
        .reserved = 0,
    }};
    const rainbow = [16]GraphicsOutputBltPixel{
        GraphicsOutputBltPixel{ .blue = 0x00, .green = 0x00, .red = 0x00, .reserved = 0 },
        GraphicsOutputBltPixel{ .blue = 0x00, .green = 0x00, .red = 0xaa, .reserved = 0 },
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

    _ = boot_services.locateProtocol(&AbsolutePointerProtocol.guid, null, @ptrCast(*?*c_void, &pointer));
    _ = boot_services.locateProtocol(&GraphicsOutputProtocol.guid, null, @ptrCast(*?*c_void, &graphics));

    var i: u8 = 0;
    while (i < 16) : (i += 1) {
        var c = [1]GraphicsOutputBltPixel{rainbow[i]};
        _ = graphics.blt(&c, GraphicsOutputBltOperation.BltVideoFill, 0, 0, i * graphics.mode.info.horizontal_resolution / 16, 0, graphics.mode.info.horizontal_resolution / 16, graphics.mode.info.vertical_resolution / 16, 0);
    }

    while (true) {
        if (pointer.getState(&pointer_state) == 0) {
            if (graphics.mode.info.vertical_resolution * pointer_state.current_y / (pointer.mode.absolute_max_y - pointer.mode.absolute_min_y) < graphics.mode.info.vertical_resolution / 16) {
                color[0] = rainbow[16 * pointer_state.current_x / (pointer.mode.absolute_max_x - pointer.mode.absolute_min_x + 1)];
            } else if (graphics.mode.info.horizontal_resolution * pointer_state.current_x / (pointer.mode.absolute_max_x - pointer.mode.absolute_min_x) >= 2 and graphics.mode.info.horizontal_resolution * pointer_state.current_x / (pointer.mode.absolute_max_x - pointer.mode.absolute_min_x) < graphics.mode.info.horizontal_resolution - 2 and graphics.mode.info.vertical_resolution * pointer_state.current_y / (pointer.mode.absolute_max_y - pointer.mode.absolute_min_y) < graphics.mode.info.vertical_resolution - 2) {
                _ = graphics.blt(&color, GraphicsOutputBltOperation.BltVideoFill, 0, 0, graphics.mode.info.horizontal_resolution * pointer_state.current_x / (pointer.mode.absolute_max_x - pointer.mode.absolute_min_x) - 2, graphics.mode.info.vertical_resolution * pointer_state.current_y / (pointer.mode.absolute_max_y - pointer.mode.absolute_min_y) - 2, 5, 5, 0);
            }
        }
        _ = boot_services.stall(10 * 1000);
    }
}

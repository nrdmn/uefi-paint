const Builder = @import("std").build.Builder;
const Target = @import("std").build.Target;
const CrossTarget = @import("std").build.CrossTarget;
const builtin = @import("builtin");

pub fn build(b: *Builder) void {
    const exe = b.addExecutable("bootx64", "paint.zig");
    exe.setBuildMode(b.standardReleaseOptions());
    exe.setTheTarget(Target{
        .Cross = CrossTarget{
            .arch = builtin.Arch.x86_64,
            .os = builtin.Os.uefi,
            .abi = builtin.Abi.none,
        },
    });
    exe.setOutputDir("EFI/Boot");
    b.default_step.dependOn(&exe.step);
}

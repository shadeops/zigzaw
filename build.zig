const std = @import("std");
const raylib_build = @import("ext/raylib/src/build.zig");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const raylib = raylib_build.addRaylib(b, target);
    raylib.setBuildMode(mode);

    const exe = b.addExecutable("zigzaw", "src/main.zig");
    exe.linkLibrary(raylib);
    exe.setTarget(target);
    exe.setBuildMode(mode);

    exe.addIncludePath("ext/raylib/src");
    exe.linkLibC();
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/tests.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}

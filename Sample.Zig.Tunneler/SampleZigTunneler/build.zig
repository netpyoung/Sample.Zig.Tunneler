const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});
    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "SampleZigTunneler",
        .root_module = root_module,
    });

    { // setup SDL
        const dynamic_link_opts: std.Build.Module.LinkSystemLibraryOptions = .{
            .preferred_link_mode = .dynamic,
            .search_strategy = .mode_first,
            .use_pkg_config = .no,
        };
        const sdl_path = b.path("../../SDL3/");
        exe.addIncludePath(sdl_path.join(b.allocator, "include") catch unreachable);
        exe.addLibraryPath(sdl_path.join(b.allocator, "lib/x64") catch unreachable);
        const bin = sdl_path.join(b.allocator, "lib/x64/SDL3.dll") catch unreachable;
        b.installBinFile(bin.src_path.sub_path, "SDL3.dll");
        exe.root_module.linkSystemLibrary("SDL3", dynamic_link_opts);
        exe.linkLibC();
    }

    if (optimize != .Debug) {
        if (target.result.os.tag == .windows) {
            // hide console window
            exe.subsystem = .Windows;
            exe.entry = .{ .symbol_name = "mainCRTStartup" };
        }

        b.getInstallStep().dependOn(&b.addInstallArtifact(exe, .{ .pdb_dir = .disabled }).step);
    } else {
        b.installArtifact(exe);
    }

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_module = root_module,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}

const std = @import("std");
const rlz = @import("raylib_zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
        .linux_display_backend = .X11,
    });
    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib");

    //web exports are completely separate
    if (target.query.os_tag == .emscripten) {
        const exe_lib = try rlz.emcc.compileForEmscripten(
            b,
            "space_researcher",
            "src/main_web.zig",
            target,
            optimize,
        );

        exe_lib.linkLibrary(raylib_artifact);
        exe_lib.root_module.addImport("raylib", raylib);

        // Note that raylib itself is not actually added to the exe_lib output file, so it also needs to be linked with emscripten.
        const link_step = try rlz.emcc.linkWithEmscripten(
            b,
            &[_]*std.Build.Step.Compile{ exe_lib, raylib_artifact },
        );
        //this lets your program access files like "resources/my-image.png":
        // link_step.addArg("--emrun");
        link_step.addArg("-sERROR_ON_UNDEFINED_SYMBOLS=0");
        link_step.addArg("--shell-file");
        link_step.addArg("src/minshell.html");
        link_step.addArg("--embed-file");
        link_step.addArg("resources/");

        b.getInstallStep().dependOn(&link_step.step);
        const run_step = try rlz.emcc.emscriptenRunStep(b);
        run_step.addArg("--no_browser");
        run_step.step.dependOn(&link_step.step);
        const run_option = b.step("run", "Run space_researcher");
        run_option.dependOn(&run_step.step);
        return;
    }

    const exe = b.addExecutable(.{
        .name = "space_researcher",
        .root_module = b.createModule(
            .{
                .root_source_file = b.path("src/main.zig"),
                .optimize = optimize,
                .target = target,
            },
        ),
    });
    const test_step = b.addTest(.{
        .name = "space_researcher",
        .root_module = b.createModule(
            .{
                .root_source_file = b.path("src/main_test.zig"),
                .optimize = optimize,
                .target = target,
            },
        ),
    });

    const content_path = "resources/";
    const install_content_step = b.addInstallDirectory(.{
        .source_dir = b.path(content_path),
        .install_dir = .prefix,
        .install_subdir = "resources/",
    });
    exe.step.dependOn(&install_content_step.step);
    test_step.step.dependOn(&install_content_step.step);

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);

    test_step.linkLibrary(raylib_artifact);
    test_step.root_module.addImport("raylib", raylib);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run space_researcher");
    run_step.dependOn(&run_cmd.step);

    const test_cmd = b.addRunArtifact(test_step);
    const run_test_step = b.step("test", "Test space_researcher");
    run_test_step.dependOn(&test_cmd.step);

    b.installArtifact(exe);
}

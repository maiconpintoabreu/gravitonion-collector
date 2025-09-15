const ProjectName = "gravitonion_collector";
const std = @import("std");
const rlz = @import("raylib_zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const exe_mod = b.createModule(.{
        .root_source_file = if (target.query.os_tag == .emscripten) b.path("src/main_web.zig") else b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("raylib", raylib);
    exe_mod.linkLibrary(raylib_artifact);

    const run_step = b.step("run", "Run the app");

    //web exports are completely separate
    if (target.query.os_tag == .emscripten) {
        const emsdk = rlz.emsdk;
        const wasm = b.addLibrary(.{
            .name = "index",
            .root_module = exe_mod,
        });

        const install_dir: std.Build.InstallDir = .{ .custom = "web" };
        var emcc_flags = emsdk.emccDefaultFlags(b.allocator, .{ .optimize = optimize });
        const emcc_settings = emsdk.emccDefaultSettings(b.allocator, .{ .optimize = optimize, .es3 = false });
        emcc_flags.put("-sSTACK_SIZE=131072", {}) catch unreachable;

        const emcc_step = emsdk.emccStep(b, raylib_artifact, wasm, .{
            .optimize = optimize,
            .flags = emcc_flags,
            .settings = emcc_settings,
            .shell_file_path = b.path("src/minshell.html"),
            .install_dir = install_dir,
            .embed_paths = &.{.{ .src_path = "resources/" }},
        });
        b.getInstallStep().dependOn(emcc_step);

        const html_filename = try std.fmt.allocPrint(b.allocator, "index.html", .{});
        const emrun_step = emsdk.emrunStep(
            b,
            b.getInstallPath(install_dir, html_filename),
            &.{},
        );

        emrun_step.dependOn(emcc_step);
        run_step.dependOn(emrun_step);
    } else {
        const exe = b.addExecutable(.{
            .name = ProjectName,
            .root_module = exe_mod,
            .use_llvm = if (optimize == .Debug) true else false,
            .use_lld = if (optimize == .Debug) true else false,
        });

        const test_filters = b.option([]const []const u8, "test-filter", "Skip tests that do not match any filter") orelse &[0][]const u8{};

        const test_step = b.addTest(.{
            .name = "gravitonion_collector",
            .filters = test_filters,
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

        test_step.linkLibrary(raylib_artifact);
        test_step.root_module.addImport("raylib", raylib);

        const test_cmd = b.addRunArtifact(test_step);
        const run_test_step = b.step("test", "Test gravitonion_collector");
        run_test_step.dependOn(&test_cmd.step);
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        run_step.dependOn(&run_cmd.step);
    }
}

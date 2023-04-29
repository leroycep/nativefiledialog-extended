const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const use_portal = b.option(bool, "portal", "When targeting Linux, use xdg-file-dialog-portal instead of GTK [default: false]") orelse false;

    const lib = b.addStaticLibrary(.{
        .name = "nfd",
        .target = target,
        .optimize = optimize,
    });
    lib.linkLibCpp();
    lib.addIncludePath("src/include");
    lib.installHeader("src/include/nfd.h", "nfd.h");
    lib.installHeader("src/include/nfd.hpp", "nfd.hpp");
    switch (lib.target_info.target.os.tag) {
        .windows => {
            lib.addCSourceFile("src/nfd_win.cpp", &.{});
            lib.linkSystemLibrary("ole32");
            lib.linkSystemLibrary("uuid");
        },
        .macos => {
            lib.addCSourceFile("src/nfd_cocoa.m", &.{});
            lib.linkFramework("AppKit");
            // TODO: Check if this actually works on MacOS
        },
        else => if (use_portal) {
            lib.addCSourceFile("src/nfd_portal.cpp", &.{});
            lib.linkSystemLibrary("dbus-1");
        } else {
            lib.addCSourceFile("src/nfd_gtk.cpp", &.{});
            lib.linkSystemLibrary("gtk+-3.0");
        },
    }

    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "test_opendialog",
        .target = target,
        .optimize = optimize,
    });
    exe.addCSourceFile("test/test_opendialog.c", &.{});
    exe.linkLibrary(lib);
    b.installArtifact(exe);
}

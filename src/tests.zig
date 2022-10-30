const std = @import("std");

const main = @import("main.zig");
const Frog = main.Frog;

test "frog fits" {
    const a = Frog{
        .left_arm = .white,
        .left_side = .yellow,
        .left_leg = .orange,
        .right_leg = .red,
        .right_side = .blue,
        .right_arm = .red,
        .body = .green,
    };
    const b1 = Frog{
        .left_arm = .white,
        .left_side = .blue,
        .left_leg = .white,
        .right_leg = .yellow,
        .right_side = .white,
        .right_arm = .yellow,
        .body = .orange,
    };
    const b2 = Frog{
        .left_arm = .white,
        .left_side = .blue,
        .left_leg = .orange,
        .right_leg = .yellow,
        .right_side = .orange,
        .right_arm = .yellow,
        .body = .green,
    };
    const b3 = Frog{
        .left_arm = .orange,
        .left_side = .yellow,
        .left_leg = .orange,
        .right_leg = .red,
        .right_side = .white,
        .right_arm = .red,
        .body = .blue,
    };
    const b4 = Frog{
        .left_arm = .blue,
        .left_side = .red,
        .left_leg = .white,
        .right_leg = .blue,
        .right_side = .yellow,
        .right_arm = .white,
        .body = .green,
    };
    const b5 = Frog{
        .left_arm = .orange,
        .left_side = .red,
        .left_leg = .blue,
        .right_leg = .white,
        .right_side = .blue,
        .right_arm = .red,
        .body = .yellow,
    };
    const b6 = Frog{
        .left_arm = .orange,
        .left_side = .yellow,
        .left_leg = .white,
        .right_leg = .red,
        .right_side = .orange,
        .right_arm = .red,
        .body = .blue,
    };
    try std.testing.expect(a.fits(.upper_right, b1));
    try std.testing.expect(a.fits(.upper_left, b2));
    try std.testing.expect(a.fits(.left, b3));
    try std.testing.expect(a.fits(.lower_left, b4));
    try std.testing.expect(a.fits(.lower_right, b5));
    try std.testing.expect(a.fits(.right, b6));

    try std.testing.expect(!a.fits(.upper_left, b1));
    try std.testing.expect(!a.fits(.upper_left, b3));
    try std.testing.expect(!a.fits(.upper_left, b4));
}

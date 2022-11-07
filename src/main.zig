const std = @import("std");

const ray = @cImport(
    @cInclude("raylib.h"),
);

const NamedColor = enum {
    red,
    orange,
    yellow,
    blue,
    green,
    white,
    unknown,
};

const HexCoord = enum {
    right,
    upper_right,
    upper_left,
    left,
    lower_left,
    lower_right,
    middle,
};

pub const Frog = struct {
    left_arm: NamedColor = .unknown,
    left_side: NamedColor = .unknown,
    left_leg: NamedColor = .unknown,
    right_leg: NamedColor = .unknown,
    right_side: NamedColor = .unknown,
    right_arm: NamedColor = .unknown,
    body: NamedColor = .unknown,

    // a's side fits with b
    pub fn fits(a: Frog, fit: HexCoord, b: Frog) bool {
        return switch (fit) {
            .right => a.left_arm == b.left_leg and a.right_arm == b.right_leg,
            .left => a.left_leg == b.left_arm and a.right_leg == b.right_arm,
            .upper_right => a.left_arm == b.right_side and a.left_side == b.right_leg,
            .upper_left => a.left_leg == b.right_side and a.left_side == b.right_arm,
            .lower_left => a.right_leg == b.left_side and a.right_side == b.left_arm,
            .lower_right => a.right_arm == b.left_side and a.right_side == b.left_leg,
            else => false,
        };
    }

    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        return std.fmt.format(writer, "{s} {s} {s} {s} {s} {s} {s}", .{
            @tagName(self.left_arm),
            @tagName(self.left_side),
            @tagName(self.left_leg),
            @tagName(self.right_leg),
            @tagName(self.right_side),
            @tagName(self.right_arm),
            @tagName(self.body),
        });
    }
};

const TexturedFrog = struct {
    frog: Frog,
    tex: ray.Texture,
    free: bool,
};

// Various measurements and dimensions

// The ratio of a hex with the pointy side pointing up is
// sqrt(3) : 2  (x : y)
// But we'll normalize our x coordinate so we'll be working with the following -
// Width & height of a hex
const hex_width = 1.0;
const hex_height = 2.0 / @sqrt(3.0);

// Distance to the hex one column over is 1 hex.
const hex_col_width = hex_width;
// Distance to the next hex row is 3/4th a hex
const hex_row_height = hex_height * 3.0 / 4.0;
// We could also use hex_row_height = @sqrt(3.0)/2.0
// this is because
// sqrt(3) == 3/sqrt(3)
// (2 * sqrt(3)) /3    == 2/sqrt(3) = hex_height
// (2*3*sqrt(3))/(3*4) == sqrt(3)/2 = hex_row_height

// Every other row has an offset of half the hex_width
const hex_row_col_offset = hex_width / 2.0;

// The board doesn't end nicely on the edge of a hex.
// So we need to define the size of the frog relative to a hex.
// Using the Rubik lines on the frog we can see that a hex contains 6 Rubik divisions
const frog_divs_x = 9.0;
const frog_divs_y = 7.0;
const frog_hex_divs = 6.0;
const frog_hex_div_width = hex_width / frog_hex_divs;
const frog_hex_div_height = hex_height / frog_hex_divs;
const frog_hex_width = frog_hex_div_width * frog_divs_x; // 1.5
const frog_hex_height = frog_hex_div_height * frog_divs_y;

const frogs_per_row = 11;
const frogs_per_col = 11;

// The board dimensions in hexs is
const board_hex_width = 11.0 * hex_width;

// The board doesn't align perfectly with the hexs but do on a frog
// division line, the board is 10 units plus two frog hex divisions
const board_hex_offset = frog_hex_div_height * 2.0;
const board_hex_height = 10.0 * hex_row_height + board_hex_offset;

// Frog UV coordinates within "frog space" is from the frog's feet to nose in the x-axis
// and from the outer edges of the frog's arms.
// We'll use the frog_divs to as a ruler to pick the center of the Rubik side. 
const body_uv = ray.Vector2{ .x = 6.0 / frog_divs_x, .y = 0.5 };
const left_arm_uv = ray.Vector2{ .x = 6.5 / frog_divs_x, .y = 0.75 / frog_divs_y };
const left_side_uv = ray.Vector2{ .x = 5.5 / frog_divs_x, .y = 0.75 / frog_divs_y };
const left_leg_uv = ray.Vector2{ .x = 0.5 / frog_divs_x, .y = 1.75 / frog_divs_y };
const right_arm_uv = ray.Vector2{ .x = left_arm_uv.x, .y = 1.0 - left_arm_uv.y };
const right_side_uv = ray.Vector2{ .x = left_side_uv.x, .y = 1.0 - left_side_uv.y };
const right_leg_uv = ray.Vector2{ .x = left_leg_uv.x, .y = 1.0 - left_leg_uv.y };

fn to_pixel_coord(f: f32, i: i32) i32 {
    return @floatToInt(i32, f * @intToFloat(f32, i));
}

fn guessColor(color: ray.Color) !NamedColor {
    if (color.r > 128 and color.g > 128 and color.b > 128) return .white;
    if (color.r > 190 and color.g > 170 and color.b < 5) return .yellow;
    if (color.r > 190 and color.g > 128 and color.b < 5) return .orange;
    if (color.r > 190 and color.g > 0 and color.b < 30) return .red;
    if (color.r < 5 and color.g > 128 and color.b > 30) return .green;
    if (color.r < 5 and color.g > 30 and color.b > 128) return .blue;
    return error.UnknownColor;
}

fn sampleFrogColor(img: ray.Image, coord: ray.Vector2) !NamedColor {
    if (coord.x < 0.0 or coord.x >= 1.0 or coord.y < 0.0 or coord.y >= 1.0)
        return error.OutOfBounds;
    const color = ray.GetImageColor(
        img,
        to_pixel_coord(coord.x, img.width),
        to_pixel_coord(coord.y, img.height),
    );
    return guessColor(color);
}

fn createFrog(img: ray.Image) !Frog {
    var frog = Frog{};

    frog.left_arm = try sampleFrogColor(img, left_arm_uv);
    frog.left_side = try sampleFrogColor(img, left_side_uv);
    frog.left_leg = try sampleFrogColor(img, left_leg_uv);
    frog.right_leg = try sampleFrogColor(img, right_leg_uv);
    frog.right_side = try sampleFrogColor(img, right_side_uv);
    frog.right_arm = try sampleFrogColor(img, right_arm_uv);
    frog.body = try sampleFrogColor(img, body_uv);

    return frog;
}

fn offset_scale_uv(frog_uv: ray.Vector2, offset: ray.Vector2, scale: ray.Vector2) ray.Vector2 {
    const uv = ray.Vector2{
        .x = (frog_uv.x * frog_hex_width + offset.x) * scale.x,
        .y = (frog_uv.y * frog_hex_height + offset.y) * scale.y,
    };
    return uv;
}

fn createBorderFrog(img: ray.Image, row: usize, col: usize) Frog {
    var frog = Frog{};

    const scale = ray.Vector2{ .x = 1.0 / board_hex_width, .y = 1.0 / board_hex_height };
    var offset = ray.Vector2{ .x = 0.0, .y = 0.0 };

    // We convert each row / col to "frog space" where the upper left corner is 0,0
    offset.x = hex_col_width * @intToFloat(f32, col) - 0.5 * @intToFloat(f32, @mod(row, 2));
    offset.y = hex_row_height * @intToFloat(f32, row) - frog_hex_div_height * 2.5;

    frog.left_arm = sampleFrogColor(img, offset_scale_uv(left_arm_uv, offset, scale)) catch .unknown;
    frog.left_side = sampleFrogColor(img, offset_scale_uv(left_side_uv, offset, scale)) catch .unknown;
    frog.left_leg = sampleFrogColor(img, offset_scale_uv(left_leg_uv, offset, scale)) catch .unknown;
    frog.right_leg = sampleFrogColor(img, offset_scale_uv(right_leg_uv, offset, scale)) catch .unknown;
    frog.right_side = sampleFrogColor(img, offset_scale_uv(right_side_uv, offset, scale)) catch .unknown;
    frog.right_arm = sampleFrogColor(img, offset_scale_uv(right_arm_uv, offset, scale)) catch .unknown;
    frog.body = sampleFrogColor(img, offset_scale_uv(body_uv, offset, scale)) catch .unknown;

    return frog;
}

fn build_border(img: ray.Image, constraints: []Frog) void {
    // top row
    var i: usize = 0;
    var k: usize = 0;
    while (i < frogs_per_row) : ({
        i += 1;
        k += 1;
    }) {
        constraints[i] = createBorderFrog(img, 0, k);
    }

    // left side
    i = frogs_per_row;
    k = 1;
    while (i < (frogs_per_col - 1) * frogs_per_row) : ({
        i += frogs_per_row;
        k += 1;
    }) {
        constraints[i] = createBorderFrog(img, k, 0);
    }

    // right side
    i = 2 * frogs_per_row - 1;
    k = 1;
    while (i < (frogs_per_col - 1) * frogs_per_row) : ({
        i += frogs_per_row;
        k += 1;
    }) {
        constraints[i] = createBorderFrog(img, k, frogs_per_row - 1);
    }

    // bottom row
    i = frogs_per_row * (frogs_per_col - 1);
    k = 0;
    while (i < frogs_per_col * frogs_per_row) : ({
        i += 1;
        k += 1;
    }) {
        constraints[i] = createBorderFrog(img, frogs_per_col - 1, k);
    }
}

fn solve(constraints: []Frog, frogs: []TexturedFrog, stack: []?u8, pos: usize) usize {
    const col = @mod(pos, 9);
    const row = pos / 9;
    const constraint_i = col + 1 + ((row + 1) * frogs_per_row);
    const c_offset = @mod(row, 2);

    var pick: u8 = 0;
    if (stack[pos] != null) {
        pick = stack[pos].?;
        frogs[pick].free = true;
        pick += 1;
    }

    while (pick < 81) : (pick += 1) {
        if (!frogs[pick].free) continue;
        const frog = frogs[pick].frog;

        if (!frog.fits(.upper_right, constraints[constraint_i - frogs_per_row + c_offset])) continue;
        if (!frog.fits(.upper_left, constraints[constraint_i - frogs_per_row - 1 + c_offset])) continue;
        if (!frog.fits(.left, constraints[constraint_i - 1])) continue;
        if (col == 8 and !frog.fits(.right, constraints[constraint_i + 1])) continue;

        stack[pos] = pick;
        frogs[pick].free = false;
        constraints[constraint_i] = frog;
        return pos + 1;
    }

    // Nothing found, backtrack
    constraints[constraint_i] = Frog{};
    stack[pos] = null;
    return pos - 1;
}

fn reset(constraints: []Frog, stack: []?u8, frogs: []TexturedFrog, pos: *usize) void {
    for (stack) |*stack_v, i| {
        const col = @mod(i, 9);
        const row = i / 9;
        const constraint_i = col + 1 + (row + 1) * frogs_per_row;
        constraints[constraint_i] = .{};
        stack_v.* = null;
        frogs[i].free = true;
    }
    pos.* = 0;
}

pub fn main() !void {
    var prng = std.rand.DefaultPrng.init(42);
    const rand = prng.random();

    ray.SetTraceLogLevel(4);
    ray.SetConfigFlags(ray.FLAG_MSAA_4X_HINT);

    const border_img = ray.LoadImage("imgs/border.gif");
    const to_img_coord_x: f32 = @intToFloat(f32, border_img.width) / board_hex_width;
    const to_img_coord_y: f32 = @intToFloat(f32, border_img.height) / board_hex_height;

    var constraints = [_]Frog{.{}} ** (frogs_per_row * frogs_per_col);
    build_border(border_img, &constraints);

    ray.InitWindow(border_img.width, border_img.height, "zigzaw");
    ray.SetWindowState(ray.FLAG_WINDOW_ALWAYS_RUN);

    const border_tex = ray.LoadTextureFromImage(border_img);
    defer ray.UnloadTexture(border_tex);
    ray.UnloadImage(border_img);

    var tex_frogs: [81]TexturedFrog = undefined;
    var str_buf: [64:0]u8 = undefined;

    for (tex_frogs) |*tex_frog, i| {
        const img_name = try std.fmt.bufPrintZ(str_buf[0..], "imgs/piece.{}.gif", .{i});
        const frog_img = ray.LoadImage(img_name.ptr);
        defer ray.UnloadImage(frog_img);

        tex_frog.* = .{
            .frog = try createFrog(frog_img),
            .tex = ray.LoadTextureFromImage(frog_img),
            .free = true,
        };
    }

    defer {
        for (tex_frogs) |frog| {
            ray.UnloadTexture(frog.tex);
        }
    }

    var stack = [_]?u8{null} ** 81;
    var stack_pos: usize = 0;
    var paused = false;

    const fps_speeds = [_]i32{ 4, 12, 24, 60, 120, 1000, 5000 };
    var fps_target: usize = 1;
    ray.SetTargetFPS(fps_speeds[fps_target]);

    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        ray.ClearBackground(.{ .r = 64, .g = 50, .b = 59, .a = 255 });
        ray.DrawTexture(border_tex, 0, 0, ray.WHITE);
        {
            for (stack) |stack_v, i| {
                const frog_idx = stack_v orelse continue;
                const xf = @intToFloat(f32, @mod(i, 9));
                const y = i / 9;
                const yf = @intToFloat(f32, y);
                const col_offset = hex_row_col_offset * @intToFloat(f32, @mod(y, 2));
                ray.DrawTextureV(
                    tex_frogs[frog_idx].tex,
                    .{
                        .x = to_img_coord_x * (hex_row_col_offset + xf + col_offset),
                        .y = to_img_coord_y * (board_hex_offset + (yf * hex_row_height)),
                    },
                    ray.WHITE,
                );
            }
        }

        ray.EndDrawing();

        if (stack_pos < 81 and !paused) {
            stack_pos = solve(&constraints, &tex_frogs, &stack, stack_pos);
        }

        var key_pressed = ray.GetKeyPressed();
        while (key_pressed != 0) {
            defer key_pressed = ray.GetKeyPressed();
            switch (key_pressed) {
                ' ' => paused = !paused,
                'R' => {
                    rand.shuffle(TexturedFrog, &tex_frogs);
                    reset(&constraints, &stack, &tex_frogs, &stack_pos);
                },
                ray.KEY_UP => {
                    fps_target = @min(fps_speeds.len - 1, fps_target + 1);
                    ray.SetTargetFPS(fps_speeds[fps_target]);
                },
                ray.KEY_DOWN => {
                    fps_target = @max(fps_target, 1) - 1;
                    ray.SetTargetFPS(fps_speeds[fps_target]);
                },
                else => continue,
            }
        }
    }
}

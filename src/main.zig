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

pub const Frog = struct {
    left_arm: NamedColor = .unknown,
    left_side: NamedColor = .unknown,
    left_leg: NamedColor = .unknown,
    right_leg: NamedColor = .unknown,
    right_side: NamedColor = .unknown,
    right_arm: NamedColor = .unknown,
    body: NamedColor = .unknown,

    /// a's side fits with b
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

fn to_pixel_coord(f: f32, i: i32) i32 {
    return @floatToInt(i32, f * @intToFloat(f32, i));
}

fn guessColor(img: ray.Image, coord: ray.Vector2) !NamedColor {
    const color = ray.GetImageColor(
        img,
        to_pixel_coord(coord.x, img.width),
        to_pixel_coord(coord.y, img.height),
    );
    if (color.r > 128 and color.g > 128 and color.b > 128) return .white;
    if (color.r > 190 and color.g > 170 and color.b < 5) return .yellow;
    if (color.r > 190 and color.g > 128 and color.b < 5) return .orange;
    if (color.r > 190 and color.g > 0 and color.b < 30) return .red;
    if (color.r < 5 and color.g > 128 and color.b > 30) return .green;
    if (color.r < 5 and color.g > 30 and color.b > 128) return .blue;
    return error.UnknownColor;
}

fn createFrog(img: ray.Image) !Frog {
    var frog = Frog{};

    frog.left_arm = try guessColor(img, left_arm_uv);
    frog.left_side = try guessColor(img, left_side_uv);
    frog.left_leg = try guessColor(img, left_leg_uv);
    frog.right_leg = try guessColor(img, right_leg_uv);
    frog.right_side = try guessColor(img, right_side_uv);
    frog.right_arm = try guessColor(img, right_arm_uv);
    frog.body = try guessColor(img, body_uv);

    return frog;
}


// Various measurements and dimensions

// The ratio of a hex with pointing sides pointing up is
// sqrt(3) : 2  (x : y)
// But we'll normalize our x coordinate so we'll be working with the following -
// Wwdth & height of a hex
const hex_width = 1.0;
//const hex_height = 2.0 / @sqrt(3);
//
//// Distance to the next hex column is 1 hex.
//const hex_col_dist = hex_width;
//// Distance to the next hex row is 3/4th a hex
//const hex_row_dist = hex_height * 3.0 / 4.0;




const hex_height = @sqrt(3.0) / 2.0;

const frog_div_height = @sqrt(3.0) / 9.0;
const hex_board_offset = frog_div_height * 2.0;
const board_hex_width = 11.0 * hex_width;
const board_hex_height = 10.0 * hex_height + hex_board_offset;

const frog_hex_width = 1.5;
const frog_hex_height = frog_div_height * 7.0;

const body_uv = ray.Vector2{ .x = 0.625, .y = 0.5 };
const left_arm_uv = ray.Vector2{ .x = 0.7, .y = 0.1 };
const left_side_uv = ray.Vector2{ .x = 0.6, .y = 0.1 };
const left_leg_uv = ray.Vector2{ .x = 0.05, .y = 0.25 };
const right_arm_uv = ray.Vector2{ .x = left_arm_uv.x, .y = 1.0 - left_arm_uv.y };
const right_side_uv = ray.Vector2{ .x = left_side_uv.x, .y = 1.0 - left_side_uv.y };
const right_leg_uv = ray.Vector2{ .x = left_leg_uv.x, .y = 1.0 - left_leg_uv.y };

fn scale_to_board_uv(frog_uv: ray.Vector2) ray.Vector2 {
    return .{
        .x = frog_hex_width * frog_uv.x,
        .y = frog_hex_height * frog_uv.y,
    };
    // offsets on board
    // x = (uv.x + hex_x - (hex_x * mod(hex_y,2.0))) / board_hex_width
    // y = (uv.y + hex_y - (frog_div_height * 2.5)) / board_hex_height
    // y = (uv.y * frog_hex_height + hex_y*3/4*hex_height - frog_div_height*2.5) / board_hex_height
}

//fn build_border(img: ray.Image, constraints: []Frog) void {
//    _ = img; 
//    // top row
//
//    const left_arm_uv = ray.Vector2{ .x = 0.7, .y = 0.1 };
//    const left_side_uv = ray.Vector2{ .x = 0.6, .y = 0.1 };
//    const left_leg_uv = ray.Vector2{ .x = 0.05, .y = 0.25 };
//    
//    const right_leg_uv = ray.Vector2{ .x = 0.0375, .y = 0.04 };
//    const right_side_uv = ray.Vector2{ .x = 0.0675, .y = 0.05 };
//    const right_arm_uv = ray.Vector2{ .x = 0.1125, .y = 0.07};
//
//    const frog_width = board_hex_width / @intToFloat(f32, img.width);
//    const frog_height = 11.0 / @intToFloat(f32, img.height);
//
//    var i: usize = 0;
//    while (i<11) : (i+=1) {
//        constraints[i] = .{.left_arm = .red};
//    }
//
//    // left side
//    i = 11;
//    while (i<10*11) : (i+=11) {
//        constraints[i] = .{.left_arm = .green};
//    }
//
//    // right side
//    i = 10;
//    while (i<10*11) : (i+=11) {
//        constraints[i] = .{.left_arm = .blue};
//    }
//    
//    // bottom row
//    i = 11*10;
//    while (i<11*11) : (i+=1) {
//        constraints[i] = .{.left_arm = .yellow};
//    }
//}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa.deinit();
    }

    ray.SetTraceLogLevel(4);
    ray.SetConfigFlags(ray.FLAG_MSAA_4X_HINT);

    var border_img = ray.LoadImage("render/edge.png");
    const to_img_coord_x: f32 = @intToFloat(f32, border_img.width) / board_hex_width;
    const to_img_coord_y: f32 = @intToFloat(f32, border_img.height) / board_hex_height;

    var constraints = [_]Frog{.{}}**(11*11);
    //build_border(border_img, &constraints);
    
    for (constraints) |constraint| {
        std.debug.print("{}\n", .{constraint});
    }

    ray.InitWindow(border_img.width, border_img.height, "zigzaw");
    ray.SetWindowState(ray.FLAG_WINDOW_ALWAYS_RUN);

    var border_tex = ray.LoadTextureFromImage(border_img);
    defer ray.UnloadTexture(border_tex);
    ray.UnloadImage(border_img);

    var frog_colors: [81]Frog = undefined;
    var frogs: [81]ray.Texture = undefined;
    var str_buf: [64:0]u8 = undefined;

    for (frogs) |_, i| {
        var img_name = try std.fmt.bufPrintZ(str_buf[0..], "render/piece.{}.png", .{i});
        var frog_img = ray.LoadImage(img_name.ptr);
        defer ray.UnloadImage(frog_img);
        frogs[i] = ray.LoadTextureFromImage(frog_img);
        frog_colors[i] = try createFrog(frog_img);
    }

    defer {
        for (frogs) |frog| {
            ray.UnloadTexture(frog);
        }
    }

    //var frog_img = ray.LoadImage("render/piece.1.png");
    //var frog_tex = ray.LoadTextureFromImage(frog_img);
    //defer ray.UnloadTexture(frog_tex);
    //ray.UnloadImage(frog_img);

    //ray.SetTargetFPS(60);
    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        ray.ClearBackground(.{ .r = 64, .g = 50, .b = 59, .a = 255 });
        //ray.DrawTexture(border_tex, 0, 0, ray.WHITE);
        {
            var y: i32 = 0;
            while (y < 9) : (y += 1) {
                var x: i32 = 0;
                while (x < 9) : (x += 1) {
                    var tex_num = y * 9 + x;
                    var xf = @intToFloat(f32, x);
                    var yf = @intToFloat(f32, y);
                    var col_offset = 0.5 * @intToFloat(f32, @mod(y, 2));
                    ray.DrawTextureV(
                        frogs[@intCast(usize, tex_num)],
                        .{
                            .x = to_img_coord_x * (0.5 + xf + col_offset),
                            .y = to_img_coord_y * (hex_board_offset + (yf * hex_height)),
                        },
                        ray.WHITE,
                    );
                }
            }
        }
        ray.DrawFPS(10, 10);
        ray.EndDrawing();
    }
}


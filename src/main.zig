const std = @import("std");

const ray = @cImport(
    @cInclude("raylib.h"),
);

pub fn main() !void {
    ray.SetTraceLogLevel(4);

    const border_img = ray.LoadImage("imgs/border.gif");

    ray.InitWindow(border_img.width, border_img.height, "zigzaw");
    ray.SetWindowState(ray.FLAG_WINDOW_ALWAYS_RUN);

    const border_tex = ray.LoadTextureFromImage(border_img);
    defer ray.UnloadTexture(border_tex);
    ray.UnloadImage(border_img);

    ray.SetTargetFPS(60);

    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        ray.ClearBackground(.{ .r = 64, .g = 50, .b = 59, .a = 255 });
        ray.DrawTexture(border_tex, 0, 0, ray.WHITE);
        ray.EndDrawing();
    }
}

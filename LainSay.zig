const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;
const io = std.io;

const Lain =
    \\   \
    \\    \
    \\          _..--¯¯¯¯--.._
    \\      ,-''              `-.
    \\    ,'                     `.
    \\   ,                         \
    \\  /                           \
    \\ /          ′.                 \
    \\'          /  ││                ;
    \\;       n /│  │/         │      │
    \\│      / v    /\/`-'v√\'.│\     ,
    \\:    /v`,———         ————.^.    ;
    \\'   │  /′@@`,        ,@@ `\│    ;
    \\│  n│  '.@@/         \@@  /│\  │;
    \\` │ `    ¯¯¯          ¯¯¯  │ \/││
    \\ \ \ \                     │ /\/
    \\ '; `-\          `′       /│/ │′
    \\  `    \       —          /│  │
    \\   `    `.              .' │  │
    \\    v,_   `;._     _.-;    │  /
    \\       `'`\│-_`'-''__/^'^' │ │
    \\              ¯¯¯¯¯        │ │
    \\                           │ /
    \\                           ││
    \\                           ││
    \\                           │,
;

fn pushToSay(allocator: std.mem.Allocator, line_arr: *std.ArrayList([]const u8), dest: *std.ArrayList([]const u8)) !void {
    const line = try line_arr.toOwnedSlice();
    defer allocator.free(line);
    line_arr.* = std.ArrayList([]const u8).init(allocator);
    const line_str = try mem.join(allocator, " ", line);
    try dest.append(line_str);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("What should Lain say?: ", .{});

    var stdin = io.getStdIn();
    defer stdin.close();
    const reader = stdin.reader();
    var buffer: [420]u8 = undefined;

    const say = try reader.readUntilDelimiter(&buffer, '\n');
    const trimmed_say = mem.trim(u8, say, " ");

    var split_say = mem.splitAny(u8, trimmed_say, " ");
    var line_arr = std.ArrayList([]const u8).init(allocator);
    defer line_arr.deinit();
    var say_arr = std.ArrayList([]const u8).init(allocator);
    errdefer say_arr.deinit();
    var line_len: usize = 0;

    while (split_say.next()) |word| {
        if (word.len + line_len <= 30) {
            try line_arr.append(word);
            line_len += word.len + 1;

            if (line_len == 30 or split_say.peek() == null) {
                try pushToSay(allocator, &line_arr, &say_arr);
                line_len = 0;

                if (split_say.peek() == null) break;
            }
        } else if (word.len + line_len > 30) {
            if (word.len + line_len <= 40) {
                try line_arr.append(word);
                try pushToSay(allocator, &line_arr, &say_arr);
            } else {
                try pushToSay(allocator, &line_arr, &say_arr);
                try line_arr.append(word);
            }

            line_len = 0;
        }
    }

    const fmt_say = try say_arr.toOwnedSlice();
    const total_lines = fmt_say.len;
    var longest_line: usize = 0;
    defer allocator.free(fmt_say);
    defer for (fmt_say) |line| {
        allocator.free(line);
    };

    const say_str = try mem.join(allocator, "\n", fmt_say);
    defer allocator.free(say_str);

    for (fmt_say) |line| {
        if (line.len > longest_line) longest_line = line.len;
    }

    var top_bottom_lines = try allocator.alloc(u8, longest_line + 4);
    defer allocator.free(top_bottom_lines);

    for (0..top_bottom_lines.len) |i| {
        if (i <= 1 or i >= top_bottom_lines.len - 2) {
            top_bottom_lines[i] = ' ';
        } else {
            top_bottom_lines[i] = '-';
        }
    }

    std.debug.print("{s}\n", .{top_bottom_lines});

    if (total_lines == 1) {
        std.debug.print("< {s} >\n", .{say_str});
    } else {
        for (0..total_lines) |i| {
            const diff = longest_line - fmt_say[i].len;
            var spaces = try allocator.alloc(u8, diff);
            defer allocator.free(spaces);
            var line: []const u8 = undefined;
            defer allocator.free(line);

            for (0..diff) |j| {
                spaces[j] = ' ';
            }

            if (i == 0) {
                const fmt_line = "/ {s}{s} \\\n";
                line = try fmt.allocPrint(allocator, fmt_line, .{ fmt_say[i], spaces });
            } else if (i == total_lines - 1) {
                const fmt_line = "\\ {s}{s} /\n";
                line = try fmt.allocPrint(allocator, fmt_line, .{ fmt_say[i], spaces });
            } else {
                const fmt_line = "| {s}{s} |\n";
                line = try fmt.allocPrint(allocator, fmt_line, .{ fmt_say[i], spaces });
            }

            std.debug.print("{s}", .{line});
        }
    }

    std.debug.print("{s}\n", .{top_bottom_lines});
    std.debug.print("{s}\n", .{Lain});
}

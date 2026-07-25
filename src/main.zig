const std = @import("std");
const Io = std.Io;

fn copyAll(reader: *Io.Reader, writer: *Io.Writer) !void {
    _ = try reader.streamRemaining(writer);
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout_buf: [8 * 1024]u8 = undefined;
    var stderr_buf: [8 * 1024]u8 = undefined;

    var stdout_file = Io.File.stdout();
    var stderr_file = Io.File.stderr();

    var stdout_writer = stdout_file.writerStreaming(io, &stdout_buf);
    var stderr_writer = stderr_file.writerStreaming(io, &stderr_buf);

    var had_error: bool = false;

    var args_iter = std.process.Args.Iterator.init(init.minimal.args);
    _ = args_iter.skip(); // skip argv[0]

    var path_opt = args_iter.next();
    if (path_opt == null) {
        var stdin_buf: [8 * 1024]u8 = undefined;
        var stdin_file = Io.File.stdin();
        var stdin_reader = stdin_file.readerStreaming(io, &stdin_buf);
        copyAll(&stdin_reader.interface, &stdout_writer.interface) catch |err| {
            try stderr_writer.interface.print("cat: stdin->stdout failed: {}\n", .{err});
            had_error = true;
        };
    } else {
        while (path_opt) |path| {
            var file = Io.Dir.cwd().openFile(io, path, .{}) catch |err| {
                try stderr_writer.interface.print("cat: cannot open {s}: {}\n", .{path, err});
                had_error = true;
                path_opt = args_iter.next();
                continue;
            };
            defer file.close(io);

            var file_buf: [8 * 1024]u8 = undefined;
            var file_reader = file.readerStreaming(io, &file_buf);
            copyAll(&file_reader.interface, &stdout_writer.interface) catch |err| {
                try stderr_writer.interface.print("cat: error reading {s}: {}\n", .{path, err});
                had_error = true;
            };
            path_opt = args_iter.next();
        }
    }

    if (had_error) {
        std.process.exit(1);
    }
}

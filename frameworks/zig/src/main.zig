const std = @import("std");
const httpz = @import("httpz");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(gpa.allocator());
    defer std.process.argsFree(gpa.allocator(), args);
    if (args.len != 4) {
        std.debug.print("Usage: {s} <HOST-IPV4> <PORT> <NUM-THREADS>\n", .{args[0]});
        std.process.exit(0);
    }
    const num_threads = try std.fmt.parseInt(u32, args[3], 10);

    var server = httpz.Server().init(allocator, .{
        .address = args[1],
        .port = std.fmt.parseInt(u16, args[2], 10) catch 8080,
        .pool = .{ .max = 10000, .timeout = 5000 },
    }) catch @panic("no init server");

    // overwrite the default notFound handler
    server.notFound(notFound);
    // overwrite the default error handler
    server.errorHandler(errorHandler);

    var router = server.router();
    router.get("/", Hello);

    var pool = try allocator.create(std.Thread.Pool);
    try pool.init(.{ .allocator = allocator, .n_jobs = num_threads });
    defer pool.deinit();
    for (pool.threads) |thread| {
        try pool.spawn(run, .{&server});
        thread.join();
    }
}

fn run(server: ?*httpz.ServerCtx(void, void)) void {
    server.?.listen() catch @panic("server listen error!!");
}

fn Hello(_: *httpz.Request, res: *httpz.Response) !void {
    res.body = "Hello World!\n";
}

fn notFound(_: *httpz.Request, res: *httpz.Response) !void {
    res.status = 404;

    // you can set the body directly to a []u8, but note that the memory
    // must be valid beyond your handler. Use the res.arena if you need to allocate
    // memory for the body.
    res.body = "Not Found";
}

// note that the error handler return `void` and not `!void`
fn errorHandler(req: *httpz.Request, res: *httpz.Response, err: anyerror) void {
    res.status = 500;
    res.body = "Internal Server Error";
    std.log.warn("httpz: unhandled exception for request: {s}\nErr: {}", .{ req.url.raw, err });
}

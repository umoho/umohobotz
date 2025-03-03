const std = @import("std");

pub const DateTime = struct {
    year: i64,
    /// Range: 1...12.
    month: u8,
    /// Range: 1...31.
    day: u8,
    /// Range: 0...23.
    hour: u8,
    /// Range: 0...59.
    minute: u8,
    /// Range: 0...59.
    second: u8,
    nanosecond: u32 = 0,

    const SECONDS_PER_DAY: i64 = 86400;
    const SECONDS_PER_HOUR = 3600;
    const SECONDS_PER_MINUTE = 60;

    /// Return true if the year is a leap year.
    fn isLeapYear(year: i64) bool {
        return (@mod(year, 4) == 0 and @mod(year, 100) != 0) or (@mod(year, 400) == 0);
    }

    /// Return the number of days in a month.
    fn daysInMonth(year: i64, month: u8) u8 {
        const leap = if (month == 2) @intFromBool(isLeapYear(year)) else 0;
        return switch (month) {
            1, 3, 5, 7, 8, 10, 12 => 31,
            4, 6, 9, 11 => 30,
            2 => 28 + @as(u8, leap),
            else => unreachable,
        };
    }

    /// Convert Unix timestamp to DateTime in UTC.
    pub fn fromUnixTimestamp(seconds: i64) DateTime {
        var ts = seconds;

        // calculate year, leap year also considered.
        var year: i64 = 1970;
        while (true) {
            const days_per_year: i64 = if (isLeapYear(year)) 366 else 365;
            const seconds_per_year = days_per_year * SECONDS_PER_DAY;
            if (ts < seconds_per_year) break;
            ts -= seconds_per_year;
            year += 1;
        }

        // calculate month.
        var month: u8 = 1;
        while (month <= 12) {
            const dim = daysInMonth(year, month);
            const seconds_in_month = @as(i64, dim) * SECONDS_PER_DAY;
            if (ts < seconds_in_month) break;
            ts -= seconds_in_month;
            month += 1;
        }

        const day = @as(u8, @intCast(@divFloor(ts, SECONDS_PER_DAY) + 1));
        ts = @mod(ts, SECONDS_PER_DAY);

        const hour = @as(u8, @intCast(@divFloor(ts, SECONDS_PER_HOUR)));
        ts = @mod(ts, SECONDS_PER_HOUR);

        const minute = @as(u8, @intCast(@divFloor(ts, SECONDS_PER_MINUTE)));
        ts = @mod(ts, SECONDS_PER_MINUTE);

        const second = @as(u8, @intCast(ts));

        return .{
            .year = year,
            .month = month,
            .day = day,
            .hour = hour,
            .minute = minute,
            .second = second,
        };
    }
};

test "DateTime.fromUnixTimestamp" {
    // 2020-02-29 23:59:59 UTC
    const timestamp = 1583020799;
    const dt = DateTime.fromUnixTimestamp(timestamp);
    std.debug.assert(dt.year == 2020);
    std.debug.assert(dt.month == 2);
    std.debug.assert(dt.day == 29);
    std.debug.assert(dt.hour == 23);
    std.debug.assert(dt.minute == 59);
    std.debug.assert(dt.second == 59);
    std.debug.assert(dt.nanosecond == 0);
}

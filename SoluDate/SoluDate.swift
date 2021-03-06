//
// Created by Nguyen Thanh Hai on 5/7/17.
// Copyright (c) 2017 Nguyen Thanh Hai. All rights reserved.
//

import Foundation

public class SoluDateConverter {
    fileprivate static let PI = Double.pi

    fileprivate static func juliusDaysFromDate(_ day: Int, _ month: Int, _ year: Int) -> Int {
        let a:Int = (14 - month) / 12
        let y:Int = year + 4800 - a
        let m:Int = month + 12 * a - 3
        var jd:Int = day + (153 * m + 2)/5 + 365 * y + y/4 - y/100 + y/400 - 32045
        if (jd < 2299161) {
            jd = day + (153 * m + 2)/5 + 365 * y + y/4 - 32083
        }

        return jd
    }

    fileprivate static func dateFromJuliusDays(_ jd: Int) -> [Int] {
        var a: Int = 0
        var b: Int = 0
        var c: Int = 0
        if (jd > 2299160) {
            a = jd + 32044
            b = (4 * a + 3)/146097
            c = a - (b * 146097)/4
        } else {
            b = 0
            c = jd + 32082
        }
        let d: Int = (4 * c + 3)/1461
        let e: Int = c - (1461 * d)/4
        let m: Int = (5 * e + 2)/153
        let day: Int = e - (153 * m + 2)/5 + 1
        let month: Int = m + 3 - 12 * (m/10)
        let year: Int = b * 100 + d - 4800 + m/10
        return [day, month, year]
    }

    fileprivate static func INT(_ d: Double) -> Int {
        return Int(exactly: floor(d))!
    }

    fileprivate static func sunLongitude(_ jdn: Double) -> Double {
        return sunLongitudeAA98(jdn)
    }

    fileprivate static func sunLongitudeAA98(_ jdn: Double) -> Double {
        let T: Double = (jdn - 2451545.0 ) / 36525
        let T2: Double = T * T
        let dr: Double = SoluDateConverter.PI/180
        let M: Double = 357.52910 + 35999.05030 * T - 0.0001559 * T2 - 0.00000048 * T * T2
        let L0: Double = 280.46645 + 36000.76983 * T + 0.0003032 * T2
        var DL: Double = (1.914600 - 0.004817 * T - 0.000014 * T2) * sin(dr * M)
        DL = DL + (0.019993 - 0.000101 * T) * sin(dr * 2 * M) + 0.000290 * sin(dr * 3 * M)
        var L: Double = L0 + DL
        L = L - 360 * (Double(INT(L/360)))

        return L
    }

    fileprivate static func newMoonAA98(_ k: Int) -> Double {
        let T: Double = Double(k)/1236.85
        let T2: Double = T * T
        let T3: Double = T2 * T
        let dr: Double = SoluDateConverter.PI/180
        var Jd1: Double = 2415020.75933 + 29.53058868 * Double(k) + 0.0001178 * T2 - 0.000000155 * T3
        Jd1 = Jd1 + 0.00033 * sin((166.56 + 132.87 * T - 0.009173 * T2) * dr)
        let M: Double = 359.2242 + 29.10535608 * Double(k) - 0.0000333 * T2 - 0.00000347 * T3
        let Mpr: Double = 306.0253 + 385.81691806 * Double(k) + 0.0107306 * T2 + 0.00001236 * T3
        let F: Double = 21.2964 + 390.67050646 * Double(k) - 0.0016528 * T2 - 0.00000239 * T3
        var C1: Double = (0.1734 - 0.000393 * T) * sin(M * dr) + 0.0021 * sin(2 * dr * M)
        
        C1 = C1 - 0.4068 * sin(Mpr*dr) + 0.0161 * sin(dr * 2*Mpr)
        C1 = C1 - 0.0004 * sin(dr * 3 * Mpr)
        C1 = C1 + 0.0104 * sin(dr * 2 * F) - 0.0051 * sin(dr * (M + Mpr))
        C1 = C1 - 0.0074 * sin(dr * (M - Mpr)) + 0.0004 * sin(dr * (2 * F + M))
        C1 = C1 - 0.0004 * sin(dr * (2 * F - M)) - 0.0006 * sin(dr * (2 * F + Mpr))
        C1 = C1 + 0.0010 * sin(dr * (2 * F - Mpr)) + 0.0005 * sin(dr * (2 * Mpr + M))

        var deltat: Double = 0
        if (T < -11) {
            deltat = 0.001 + 0.000839 * T + 0.0002261 * T2 - 0.00000845 * T3 - 0.000000081 * T * T3
        } else {
            deltat = -0.000278 + 0.000265 * T + 0.000262 * T2
        }

        let JdNew: Double = Jd1 + C1 - deltat

        return JdNew
    }

    fileprivate static func newMoon(_ k:Int) -> Double {
        return newMoonAA98(k)
    }

    fileprivate static func getSunLongitude(_ dayNumber: Int,_ timeZone: Double) -> Double {
        return sunLongitude(Double(dayNumber) - 0.5 - timeZone/24)
    }

    fileprivate static func getNewMoonDay(_ k: Int, _ timeZone: Double) -> Int {
        let jd: Double = newMoon(k)
        return INT(jd + 0.5 + timeZone/24)
    }

    fileprivate static func getLunarMonth11(_ year: Int, _ timeZone: Double) -> Int {
        let off: Double = Double(juliusDaysFromDate(31, 12, year)) - 2415021.076998695
        let k: Int = INT(off / 29.530588853)
        var nm: Int = getNewMoonDay(k, timeZone)
        let sunLong: Int = INT(getSunLongitude(nm, timeZone)/30)
        if (sunLong >= 9) {
            nm = getNewMoonDay(k-1, timeZone)
        }
        return nm
    }

    fileprivate static func getLeapMonthOffset(_ a11: Int,_ timeZone: Double) -> Int {
        let k: Int = INT(0.5 + (Double(a11) - 2415021.076998695) / 29.530588853)
        var last: Int = 0
        var i: Int = 1
        var arc: Int = INT(getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone)/30)

        repeat {
            last = arc
            i = i + 1
            arc = INT(getSunLongitude(getNewMoonDay(k + i, timeZone), timeZone)/30)
        } while (arc != last && i < 14)

        return i-1
    }

    fileprivate static func convertSolar2Lunar(_ day: Int, _ month: Int, _ year: Int, _ timeZone: Double) -> [Int] {
        var lunarDay: Int = 0
        var lunarMonth: Int = 0
        var lunarYear: Int = 0
        var lunarLeap: Int = 0
        let dayNumber: Int = juliusDaysFromDate(day, month, year)
        let k: Int = INT((Double(dayNumber) - 2415021.076998695) / 29.530588853)
        var monthStart: Int = getNewMoonDay(k+1, timeZone)
        if (monthStart > dayNumber) {
            monthStart = getNewMoonDay(k, timeZone)
        }
        var a11: Int = getLunarMonth11(year, timeZone)
        var b11: Int = a11
        if (a11 >= monthStart) {
            lunarYear = year
            a11 = getLunarMonth11(year - 1, timeZone)
        } else {
            lunarYear = year + 1
            b11 = getLunarMonth11(year + 1, timeZone)
        }
        lunarDay = dayNumber-monthStart+1
        let diff: Int = INT((Double(monthStart) - Double(a11))/29)
        lunarLeap = 0
        lunarMonth = diff + 11

        if (b11 - a11 > 365) {
            let leapMonthDiff: Int = getLeapMonthOffset(a11, timeZone)
            if (diff >= leapMonthDiff) {
                lunarMonth = diff + 10
                if (diff == leapMonthDiff) {
                    lunarLeap = 1
                }
            }
        }
        if (lunarMonth > 12) {
            lunarMonth = lunarMonth - 12
        }
        if (lunarMonth >= 11 && diff < 4) {
            lunarYear = lunarYear - 1
        }

        return [lunarDay, lunarMonth, lunarYear, lunarLeap]
    }

    fileprivate static func convertLunar2Solar(_ lunarDay: Int,_ lunarMonth: Int,_ lunarYear: Int,_ lunarLeap: Int,
                                               _ timeZone: Double) ->  [Int]? {
        var a11: Int = 0
        var b11: Int = 0
        if (lunarMonth < 11) {
            a11 = getLunarMonth11(lunarYear-1, timeZone)
            b11 = getLunarMonth11(lunarYear, timeZone)
        } else {
            a11 = getLunarMonth11(lunarYear, timeZone)
            b11 = getLunarMonth11(lunarYear+1, timeZone)
        }
        let k: Int = INT(0.5 + (Double(a11) - 2415021.076998695) / 29.530588853)
        var off: Int = lunarMonth - 11
        if (off < 0) {
            off += 12
        }
        if (b11 - a11 > 365) {
            let leapOff: Int = getLeapMonthOffset(a11, timeZone)
            var leapMonth: Int = leapOff - 2
            if (leapMonth < 0) {
                leapMonth += 12
            }
            if (lunarLeap != 0 && lunarMonth != leapMonth) {
                return nil
            } else if (lunarLeap != 0 || off >= leapOff) {
                off += 1
            }
        }
        let monthStart: Int = getNewMoonDay(k+off, timeZone)

        return dateFromJuliusDays(monthStart+lunarDay-1)
    }

    fileprivate static func leapFromDate(_ day: Int,_ month: Int,_ year: Int) -> Int {
        var lunarDay: Int = 0
        var lunarMonth: Int = 0
        var lunarYear: Int = 0
        var lunarLeap: Int = 0
        let timeZone: Double = 0
        let dayNumber: Int = juliusDaysFromDate(day, month, year)
        let k: Int = INT((Double(dayNumber) - 2415021.076998695) / 29.530588853)
        var monthStart: Int = getNewMoonDay(k+1, timeZone)
        if (monthStart > dayNumber) {
            monthStart = getNewMoonDay(k, timeZone)
        }
        var a11: Int = getLunarMonth11(year, timeZone)
        var b11: Int = a11
        if (a11 >= monthStart) {
            lunarYear = year
            a11 = getLunarMonth11(year-1, timeZone)
        } else {
            lunarYear = year+1
            b11 = getLunarMonth11(year+1, timeZone)
        }
        lunarDay = dayNumber-monthStart+1
        let diff: Int = INT((Double(monthStart) - Double(a11))/29)
        lunarLeap = 0
        lunarMonth = diff + 11

        if (b11 - a11 > 365) {
            let leapMonthDiff: Int = getLeapMonthOffset(a11, timeZone)
            if (diff >= leapMonthDiff) {
                lunarMonth = diff + 10
                if (diff == leapMonthDiff) {
                    lunarLeap = 1
                }
            }
        }

        return lunarLeap
    }
}

extension SoluDateConverter {
    public static func lunarDateFromSonarDate(_ date: Date) -> Date? {
        let comps: DateComponents = Calendar.current.dateComponents([.day, .month, .year, .timeZone], from: date)
        let day = comps.day!
        let month = comps.month!
        let year = comps.year!
        let rawComs = convertSolar2Lunar(day, month, year, 7.0)
        var lunarComps = DateComponents()
        lunarComps.day = rawComs[0]
        lunarComps.month = rawComs[1]
        lunarComps.timeZone = comps.timeZone
        lunarComps.year = rawComs[2]
        let leap = rawComs[3]
        lunarComps.isLeapMonth = Bool(leap as NSNumber)
        
        let date = NSCalendar(identifier: NSCalendar.Identifier.gregorian)?.date(from: lunarComps as DateComponents)
        
        return  date
    }

    public static func sonarDateFromLunarDate(_ date: Date) -> Date? {
        let comps: DateComponents = Calendar.current.dateComponents([.day, .month, .year, .timeZone], from: date)
        let day = comps.day!
        let month = comps.month!
        let year = comps.year!
        let leap = leapFromDate(day, month, year)
        let jdComps = convertLunar2Solar(day, month, year, leap, 7.0)
        
        var date: Date?
        
        if let jdComps = jdComps {
            let c = NSDateComponents()
            c.day = jdComps[0]
            c.month = jdComps[1]
            c.year = jdComps[2]
            
            date = NSCalendar(identifier: NSCalendar.Identifier.gregorian)?.date(from: c as DateComponents)
        } else {
            date = nil
        }
        
        return  date
    }
}

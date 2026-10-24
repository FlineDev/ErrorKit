#if canImport(OSLog)
   import Foundation
   import Testing

   import ErrorKit

   @Suite("Duration helpers")
   struct DurationHelperTests {
      @Test func minutesAndHoursBuildTheirDuration() {
         #expect(Duration.minutes(30) == .seconds(1800))
         #expect(Duration.hours(2) == .seconds(7200))
      }

      @Test func timeIntervalKeepsFractionalSeconds() {
         #expect(Duration.milliseconds(1500).timeInterval == 1.5)
         #expect(Duration.hours(1).timeInterval == 3600)
      }
   }
#endif

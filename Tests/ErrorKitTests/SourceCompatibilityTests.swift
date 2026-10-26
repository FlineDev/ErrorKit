import ErrorKit
import Testing

@Suite("Source compatibility")
struct SourceCompatibilityTests {
   enum ProbeError: Error, Catching {
      case caught(Error)
   }

   struct ProbeFailure: Throwable {
      var userFriendlyMessage: String { "Operation failed." }
   }

   @Test
   func asyncCatchFunctionReference() async throws {
      let wrapper: (() async throws -> Int) async throws(ProbeError) -> Int = ProbeError.catch
      let value = try await wrapper { 42 }
      #expect(value == 42)
   }

   @Test
   func errorChainFormatterFunctionReference() {
      let formatter: (any Error) -> String = ErrorKit.errorChainDescription(for:)
      #expect(
         formatter(ProbeFailure())
            == """
            ProbeFailure [Struct]
            └─ userFriendlyMessage: "Operation failed."
            """
      )
   }
}

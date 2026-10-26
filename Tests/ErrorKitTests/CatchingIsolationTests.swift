import ErrorKit
import Testing

/// These tests mostly prove something at compile time: `catch` must accept a closure that touches actor-isolated state
/// or captures non-Sendable values. Without the inherited isolation, Swift 6 rejects both with "sending value of
/// non-Sendable type risks causing data races".
@Suite("Catching isolation")
struct CatchingIsolationTests {
   enum LoadError: Throwable, Catching {
      case caught(Error)

      var userFriendlyMessage: String { "Loading failed." }
   }

   final class Counter {
      var value = 0
   }

   @MainActor
   final class ViewModel {
      var total = 0

      func fetch() async throws -> Int { 2 }

      func refresh() async throws {
         self.total = try await LoadError.catch(isolation: #isolation) {
            try await self.fetch() + self.total
         }
      }
   }

   actor Store {
      var count = 1

      func increment() async throws -> Int {
         try await LoadError.catch(isolation: #isolation) {
            try await Task.sleep(for: .zero)
            self.count += 1
            return self.count
         }
      }
   }

   @Test
   @MainActor
   func mainActorStateIsAccessible() async throws {
      let viewModel = ViewModel()
      try await viewModel.refresh()
      #expect(viewModel.total == 2)
   }

   @Test
   func actorStateIsAccessible() async throws {
      let store = Store()
      #expect(try await store.increment() == 2)
   }

   @Test
   @MainActor
   func nonSendableCapturesStillWork() async throws {
      let counter = Counter()
      let result = try await LoadError.catch(isolation: #isolation) {
         try await Task.sleep(for: .zero)
         counter.value += 1
         return counter.value
      }
      #expect(result == 1)
      #expect(counter.value == 1)
   }

   @Test
   func errorsAreStillWrapped() async {
      struct Underlying: Error, Equatable {
         let code: Int
      }
      let expectedError = Underlying(code: 42)
      do {
         _ = try await LoadError.catch(isolation: #isolation) { () async throws -> Int in
            throw expectedError
         }
         Issue.record("Expected the underlying error to be wrapped.")
      } catch {
         switch error {
         case .caught(let underlying):
            #expect(underlying as? Underlying == expectedError)
         }
      }
   }

   @Test
   func errorsAreNotWrappedTwice() async {
      struct Underlying: Error, Equatable {
         let code: Int
      }
      let expectedError = Underlying(code: 43)
      let wrappedError = LoadError.caught(expectedError)
      do {
         _ = try await LoadError.catch(isolation: #isolation) { () async throws -> Int in
            throw wrappedError
         }
         Issue.record("Expected the already wrapped error to be thrown.")
      } catch {
         switch error {
         case .caught(let underlying):
            #expect(underlying as? Underlying == expectedError)
         }
      }
   }
}

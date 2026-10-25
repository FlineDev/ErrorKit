import Foundation
import Testing

@testable import ErrorKit

enum ErrorKitTests {
   struct SomeLocalizedError: LocalizedError {
      let errorDescription: String? = "Something failed."
      let failureReason: String? = "It failed because it wanted to."
      let recoverySuggestion: String? = "Try again later."
      let helpAnchor: String? = "https://github.com/apple/swift-error-kit#readme"
   }

   struct SomeThrowable: Throwable {
      let userFriendlyMessage: String = "Something failed hard."
   }

   enum UserFriendlyMessage {
      @Test
      static func localizedError() {
         #expect(ErrorKit.userFriendlyMessage(for: SomeLocalizedError()) == "Something failed. It failed because it wanted to. Try again later.")
      }

      #if canImport(CryptoKit)
         @Test
         static func nsError() {
            let nsError = NSError(domain: "SOME", code: 1245, userInfo: [NSLocalizedDescriptionKey: "Something failed."])
            #expect(ErrorKit.userFriendlyMessage(for: nsError) == "[SOME: 1245] Something failed.")
         }
      #endif

      @Test
      static func throwable() async throws {
         #expect(ErrorKit.userFriendlyMessage(for: SomeThrowable()) == "Something failed hard.")
      }

      @Test
      static func nested() async throws {
         let nestedError = DatabaseError.caught(FileError.caught(PermissionError.denied(permission: "~/Downloads/Profile.png")))
         #expect(
            ErrorKit.userFriendlyMessage(for: nestedError)
               == "Access to ~/Downloads/Profile.png was declined. To use this feature, please enable the permission in your device Settings."
         )
      }
   }

   enum StringInterpolation {
      @Test
      static func implicitWithStruct() async throws {
         #expect("\(SomeThrowable())" == "Something failed hard.")
      }

      @Test
      static func implicitWithNestedError() async throws {
         let nestedError = DatabaseError.caught(FileError.caught(PermissionError.denied(permission: "~/Downloads/Profile.png")))
         #expect(
            "\(nestedError)"
               == "Access to ~/Downloads/Profile.png was declined. To use this feature, please enable the permission in your device Settings."
         )
      }

      @Test
      static func chainWithStruct() async throws {
         #expect(
            "\(chain: SomeThrowable())"
               == """
               SomeThrowable [Struct]
               └─ userFriendlyMessage: "Something failed hard."
               """
         )
      }

      @Test
      static func chainWithNestedError() async throws {
         let nestedError = DatabaseError.caught(FileError.caught(PermissionError.denied(permission: "~/Downloads/Profile.png")))
         #expect(
            "\(chain: nestedError)"
               == """
               DatabaseError
               └─ FileError
                  └─ PermissionError.denied(permission: "~/Downloads/Profile.png")
                     └─ userFriendlyMessage: "Access to ~/Downloads/Profile.png was declined. To use this feature, please enable the permission in your device Settings."
               """
         )
      }
   }

   enum ErrorChainDescription {
      @Test
      static func localizedError() {
         #expect(
            ErrorKit.errorChainDescription(for: SomeLocalizedError())
               == """
               SomeLocalizedError [Struct]
               └─ userFriendlyMessage: "Something failed. It failed because it wanted to. Try again later."
               """
         )
      }

      #if canImport(CryptoKit)
         @Test
         static func nsError() {
            let nsError = NSError(domain: "SOME", code: 1245, userInfo: [NSLocalizedDescriptionKey: "Something failed."])
            let generatedErrorChainDescription = ErrorKit.errorChainDescription(for: nsError)
            let expectedErrorChainDescription = """
               NSError [Class]
               └─ userFriendlyMessage: "[SOME: 1245] Something failed."
               """
            #expect(generatedErrorChainDescription == expectedErrorChainDescription)
         }
      #endif

      @Test
      static func throwableStruct() {
         let generatedErrorChainDescription = ErrorKit.errorChainDescription(for: SomeThrowable())
         let expectedErrorChainDescription = """
            SomeThrowable [Struct]
            └─ userFriendlyMessage: "Something failed hard."
            """
         #expect(generatedErrorChainDescription == expectedErrorChainDescription)
      }

      @Test
      static func throwableEnum() {
         let generatedErrorChainDescription = ErrorKit.errorChainDescription(for: PermissionError.restricted(permission: "~/Downloads/Profile.png"))
         let expectedErrorChainDescription = """
            PermissionError.restricted(permission: "~/Downloads/Profile.png")
            └─ userFriendlyMessage: "Access to ~/Downloads/Profile.png is currently restricted. This may be due to system settings or parental controls."
            """
         #expect(generatedErrorChainDescription == expectedErrorChainDescription)
      }

      @Test
      static func shallowNested() {
         let nestedError = DatabaseError.caught(FileError.fileNotFound(fileName: "App.sqlite"))
         let generatedErrorChainDescription = ErrorKit.errorChainDescription(for: nestedError)
         let expectedErrorChainDescription = """
            DatabaseError
            └─ FileError.fileNotFound(fileName: "App.sqlite")
               └─ userFriendlyMessage: "The file App.sqlite could not be located. Please verify the file path and try again."
            """
         #expect(generatedErrorChainDescription == expectedErrorChainDescription)
      }

      @Test
      static func shallowNestedWithIndent() {
         let nestedError = DatabaseError.caught(FileError.fileNotFound(fileName: "App.sqlite"))
         let generatedErrorChainDescription = ErrorKit.errorChainDescription(for: nestedError, indent: "  ")
         let expectedErrorChainDescription = """
            DatabaseError
              └─ FileError.fileNotFound(fileName: "App.sqlite")
                 └─ userFriendlyMessage: "The file App.sqlite could not be located. Please verify the file path and try again."
            """
         #expect(generatedErrorChainDescription == expectedErrorChainDescription)
      }

      @Test
      static func deeplyNestedThrowablesWithEnumLeaf() {
         let nestedError = StateError.caught(
            OperationError.caught(
               DatabaseError.caught(
                  FileError.caught(
                     PermissionError.denied(permission: "~/Downloads/Profile.png")
                  )
               )
            )
         )
         let generatedErrorChainDescription = ErrorKit.errorChainDescription(for: nestedError)
         let expectedErrorChainDescription = """
            StateError
            └─ OperationError
               └─ DatabaseError
                  └─ FileError
                     └─ PermissionError.denied(permission: "~/Downloads/Profile.png")
                        └─ userFriendlyMessage: "Access to ~/Downloads/Profile.png was declined. To use this feature, please enable the permission in your device Settings."
            """
         #expect(generatedErrorChainDescription == expectedErrorChainDescription)
      }

      @Test
      static func deeplyNestedThrowablesWithIndent() {
         let nestedError = StateError.caught(
            OperationError.caught(
               DatabaseError.caught(
                  FileError.caught(
                     PermissionError.denied(permission: "~/Downloads/Profile.png")
                  )
               )
            )
         )
         let generatedErrorChainDescription = ErrorKit.errorChainDescription(for: nestedError, indent: ">>")
         let expectedErrorChainDescription = """
            StateError
            >>└─ OperationError
            >>   └─ DatabaseError
            >>      └─ FileError
            >>         └─ PermissionError.denied(permission: "~/Downloads/Profile.png")
            >>            └─ userFriendlyMessage: "Access to ~/Downloads/Profile.png was declined. To use this feature, please enable the permission in your device Settings."
            """
         #expect(generatedErrorChainDescription == expectedErrorChainDescription)
         #expect(ErrorKit.errorChainDescription(for: nestedError) == ErrorKit.errorChainDescription(for: nestedError, indent: ""))
      }

      @Test
      static func deeplyNestedThrowablesWithStructLeaf() {
         let nestedError = StateError.caught(
            OperationError.caught(
               DatabaseError.caught(
                  FileError.caught(
                     SomeThrowable()
                  )
               )
            )
         )
         let generatedErrorChainDescription = ErrorKit.errorChainDescription(for: nestedError)
         let expectedErrorChainDescription = """
            StateError
            └─ OperationError
               └─ DatabaseError
                  └─ FileError
                     └─ SomeThrowable [Struct]
                        └─ userFriendlyMessage: "Something failed hard."
            """
         #expect(generatedErrorChainDescription == expectedErrorChainDescription)
      }

      @Test
      static func deeplyNestedThrowablesWithLocalizedErrorLeaf() {
         let nestedError = StateError.caught(
            OperationError.caught(
               DatabaseError.caught(
                  FileError.caught(
                     SomeLocalizedError()
                  )
               )
            )
         )
         let generatedErrorChainDescription = ErrorKit.errorChainDescription(for: nestedError)
         let expectedErrorChainDescription = """
            StateError
            └─ OperationError
               └─ DatabaseError
                  └─ FileError
                     └─ SomeLocalizedError [Struct]
                        └─ userFriendlyMessage: "Something failed. It failed because it wanted to. Try again later."
            """
         #expect(generatedErrorChainDescription == expectedErrorChainDescription)
      }

      #if canImport(CryptoKit)
         @Test
         static func deeplyNestedThrowablesWithNSErrorLeaf() {
            let nsError = NSError(domain: "SOME", code: 1245, userInfo: [NSLocalizedDescriptionKey: "Something failed."])
            let nestedError = StateError.caught(
               OperationError.caught(
                  DatabaseError.caught(
                     FileError.caught(nsError)
                  )
               )
            )
            let generatedErrorChainDescription = ErrorKit.errorChainDescription(for: nestedError)
            let expectedErrorChainDescription = """
               StateError
               └─ OperationError
                  └─ DatabaseError
                     └─ FileError
                        └─ NSError [Class]
                           └─ userFriendlyMessage: "[SOME: 1245] Something failed."
               """
            #expect(generatedErrorChainDescription == expectedErrorChainDescription)
         }
      #endif
   }

   // TODO: add more tests for more specific errors such as CoreData, MapKit – and also nested errors!
}

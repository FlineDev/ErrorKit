// swift-tools-version: 6.0
import PackageDescription

let package = Package(
   name: "ErrorKit",
   defaultLocalization: "en",
   platforms: [.macOS(.v13), .iOS(.v15), .tvOS(.v15), .watchOS(.v9), .macCatalyst(.v15)],
   products: [.library(name: "ErrorKit", targets: ["ErrorKit"])],
   dependencies: [
      // CryptoKit is not available on Linux, so we need Swift Crypto
      .package(url: "https://github.com/apple/swift-crypto.git", from: "3.11.0")
   ],
   targets: [
      .target(
         name: "ErrorKit",
         dependencies: [
            .product(
               name: "Crypto",
               package: "swift-crypto",
               condition: .when(platforms: [.android, .linux, .openbsd, .wasi, .windows])
            )
         ],
         resources: [
            .process("Resources/Localizable.xcstrings"),
            .process("Resources/PrivacyInfo.xcprivacy"),
         ]
      ),
      .testTarget(name: "ErrorKitTests", dependencies: ["ErrorKit"]),
   ]
)

// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GRDBClient",
    platforms: [.iOS(.v14), .macOS(.v11), .tvOS(.v13), .watchOS(.v6)],
    products: [
      .singleTargetLibrary("GRDBClient"),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.0.0"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.24.2"),
        
        // Local Dependencies
        .package(path: "/Users/daniellyons/Developer/My Swift Packages/FileManagerClient"),
    ],
    targets: [
      
      .target(
        name: "GRDBClient",
        dependencies: [
          "FileManagerClient",
          .product(name: "Dependencies", package: "swift-dependencies"),
          .product(name: "DependenciesMacros", package: "swift-dependencies"),
          .product(name: "GRDB", package: "grdb.swift")
        ]),
      
      // MARK: Tests
//      .testTarget(
//        name: "GRDBClientTests",
//        dependencies: ["GRDBClient"]
//      ),
    ]
)

extension Product {
  static func singleTargetLibrary(_ name: String) -> Product {
    .library(name: name, targets: [name])
  }
}

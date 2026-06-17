// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "PerfectMySQL",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .library(name: "PerfectMySQL", targets: ["PerfectMySQL"])
    ],
    dependencies: [
        .package(path: "../Perfect-CRUD"),
    ],
    targets: [
        // Inline system library wrapping libmysqlclient — replaces Perfect-mysqlclient
        .systemLibrary(
            name: "mysqlclient",
            pkgConfig: "mysqlclient",
            providers: [
                .brew(["mysql-client"]),
                .apt(["libmysqlclient-dev"]),
            ]
        ),
        .target(
            name: "PerfectMySQL",
            dependencies: [
                .product(name: "PerfectCRUD", package: "Perfect-CRUD"),
                "mysqlclient",
            ]
        ),
        .testTarget(
            name: "PerfectMySQLTests",
            dependencies: [
                "PerfectMySQL",
                .product(name: "PerfectCRUD", package: "Perfect-CRUD"),
            ]
        ),
    ]
)

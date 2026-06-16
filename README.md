# Perfect-MySQL

A Swift 6 wrapper around the MySQL client library (libmysqlclient), providing both a raw MySQL API and a PerfectCRUD integration layer.

## Requirements

- Swift 6.0+
- macOS 15+ / Ubuntu 20.04+
- MySQL 8.0+ client library (libmysqlclient)

## macOS Setup

MySQL client is installed via Homebrew. It is **keg-only** (not linked into `/opt/homebrew`) so you also need `pkg-config` installed so SPM can locate the headers and libraries.

```bash
brew install mysql-client pkg-config
```

Then set `PKG_CONFIG_PATH` when building so SPM finds the `mysqlclient.pc` file:

```bash
export PKG_CONFIG_PATH="/opt/homebrew/opt/mysql-client/lib/pkgconfig:$PKG_CONFIG_PATH"
swift build
```

To make this permanent, add the export to your shell profile (`~/.zshrc` or `~/.bash_profile`).

> **Apple Silicon vs Intel:** Homebrew installs to `/opt/homebrew` on Apple Silicon and `/usr/local` on Intel. The path above is for Apple Silicon; substitute `/usr/local` if you're on an Intel Mac.

## Linux Setup

```bash
sudo apt-get install libmysqlclient-dev pkg-config
```

MySQL 8.0+ is required. On Ubuntu 20.04 and later the default `libmysqlclient-dev` package satisfies this.

## Package.swift

```swift
.package(path: "../Perfect-MySQL"),  // local resurrection path

// or when published:
// .package(url: "https://github.com/your-org/Perfect-MySQL.git", from: "4.0.0")
```

```swift
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "PerfectMySQL", package: "Perfect-MySQL"),
    ]
)
```

## Usage

### Raw MySQL API

```swift
import PerfectMySQL

let mysql = MySQL()
guard mysql.connect(host: "127.0.0.1", user: "root", password: "secret", db: "mydb") else {
    print(mysql.errorMessage())
    exit(1)
}

guard mysql.query(statement: "SELECT id, name FROM users") else {
    print(mysql.errorMessage())
    exit(1)
}

if let results = mysql.storeResults() {
    results.forEachRow { row in
        print(row[0] ?? "nil", row[1] ?? "nil")
    }
}
```

### PerfectCRUD Integration

`MySQLDatabaseConfiguration` conforms to `DatabaseConfigurationProtocol` and `Sendable`, so it works directly with PerfectCRUD's `Database` and with PerfectNIO's `Routes.db()` helper.

```swift
import PerfectCRUD
import PerfectMySQL

struct User: Codable {
    let id: Int
    var name: String
    var email: String
}

let config = try MySQLDatabaseConfiguration(
    database: "mydb",
    host: "127.0.0.1",
    username: "root",
    password: "secret"
)

let db = Database(configuration: config)
try db.create(User.self, policy: .reconcileTable)

let users = try db.table(User.self).where(\User.name == "Alice").select().map { $0 }
```

### With PerfectNIO Routes

```swift
import PerfectNIO
import PerfectNIOCRUD
import PerfectMySQL

let routes = Routes()
    .db(try MySQLDatabaseConfiguration(database: "mydb", host: "127.0.0.1")) { req, db in
        try db.table(User.self).select().map { $0 }
    }
```

## Running Tests

Tests require a live MySQL server at `127.0.0.1` with a root account (no password) and permission to create/drop a database named `test`.

```bash
# Start MySQL if needed
mysql.server start

# Run tests with PKG_CONFIG_PATH set
PKG_CONFIG_PATH=/opt/homebrew/opt/mysql-client/lib/pkgconfig swift test
```

## Notes on MySQL 8.0

MySQL 8.0 removed the `my_bool` typedef that earlier versions used for nullable bool fields. This package's inline `mysqlclient` system library target provides a compatibility shim (`typedef signed char my_bool`) so the source compiles against both old and new client versions.

## License

Apache 2.0 — see [LICENSE](LICENSE).

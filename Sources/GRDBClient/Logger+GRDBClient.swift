@_exported import OSLog

extension Logger {
  enum Category: String {
    case transactions, backups, migrations
  }
  static func grdbClient(_ category: Category) -> Self {
    Logger(subsystem: "GRDBClient", category: category.rawValue)
  }
}

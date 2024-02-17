@_exported import OSLog

extension Logger {
  static let subsystem = "GRDBClient"
  enum Category: String {
    case `default`
  }
  static func grdbClient(_ category: Category = .default) -> Self {
    Logger(subsystem: subsystem, category: category.rawValue)
  }
}


import GRDB

public protocol DBMigration {
  static var identifier: String { get }
  static func migrate(_ db: Database) throws
}

extension DBMigration {
  public static var identifier: String { "\(Self.self)" }
}

extension DatabaseMigrator {
  // ❓ Perhaps this should be moved out of the library and into apps
  public mutating func registerDBMigrations() {
#if DEBUG
    self.eraseDatabaseOnSchemaChange = true
#endif
    
//    self.registerMigration(Migration20231121.self)
  }
  
  @available(*, deprecated)
  public mutating func registerMigration(_ migration: DBMigration.Type) {
    self.registerMigration(migration.identifier, migrate: migration.migrate(_:))
  }
}


public struct UnimplementedDBMigration: DBMigration {
  public static var identifier = "unimplemented"
  public static func migrate(_ db: Database) throws {
    return
  }
}

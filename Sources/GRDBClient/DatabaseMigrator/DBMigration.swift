
import GRDB

/// Use this protocol to define a single migration to be used by a ``GRDB/DatabaseMigrator``.
///
/// A *migration* has a simple definition consisting of an `identifier` string and a migration operation
/// to be performed.
///
/// ## Defining a Migration
/// Simply create a new type which conforms to ``DBMigration``.
/// ```swift
/// public struct V1_CreateAuthors: DBMigration {
///     public static var identifier = "V1_CreateAuthors"
///     public static func migrate(_ db: Database) throws {
///         try db.create(table: "author") { t in
///             t.autoIncrementedPrimaryKey("id")
///             t.column("creationDate", .datetime)
///             t.column("name", .text)
///         }
///     }
/// }
/// ```
///
/// ## Registering Migrations
/// After migrations have been defined they should be passed as an array to ``GRDB/DatabaseMigrator/init(registeringMigrations:)``.
/// This will create the ``GRDB/DatabaseMigrator`` and register the migrations
/// in their proper order in one step.
/// ```swift
/// let migrations = [V1_CreateAuthors.self, V2_CreateBooks.self]
/// let migrator = DatabaseMigrator(registeringMigrations: migrations)
/// migrator.migrate(myDatabaseWriter) // migrate when you are ready
/// ```
public protocol DBMigration {
  static var identifier: String { get }
  @Sendable static func migrate(_ db: Database) throws
}

extension DBMigration {
  public static var identifier: String { "\(Self.self)" }
}

extension DatabaseMigrator {
    /// Creates a `DatabaseMigrator` with the desired migrations
    /// - Parameter migrations: the migrations that you would like to migrate.
    /// These migrations will be registered immediately, but will not be migrated until you call `migrate(_:)`.
    public init(registeringMigrations migrations: [DBMigration.Type]) {
        self.init()
        self.registerAllMigrations(in: migrations)
    }
    
    mutating fileprivate func registerAllMigrations(in migrations: [DBMigration.Type]) {
    for migration in migrations {
      self.registerMigration(migration)
    }
  }
  
  mutating fileprivate func registerMigration(_ migration: DBMigration.Type) {
    self.registerMigration(migration.identifier, migrate: migration.migrate(_:))
  }
}


public struct UnimplementedDBMigration: DBMigration {
  public static var identifier = "unimplemented"
  public static func migrate(_ db: Database) throws {
    return
  }
}



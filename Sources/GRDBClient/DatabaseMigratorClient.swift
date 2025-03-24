import Dependencies
import DependenciesMacros
import GRDB

extension DependencyValues {
  public var dbMigrator: DatabaseMigratorClient {
    get { self[DatabaseMigratorClient.self] }
    set { self[DatabaseMigratorClient.self] = newValue }
  }
}

/// A client for ``DBMigration``s. ⚠️ I'm not sure this client is necessary. 
@DependencyClient
public struct DatabaseMigratorClient: Sendable {
  public static let unimplemented = Self()
  
  public var migrations: () -> any DBMigration = { UnimplementedDBMigration() }
  public var register: (_ migration: DBMigration.Type) -> Void
}

extension DatabaseMigratorClient: TestDependencyKey {
  public static let testValue: DatabaseMigratorClient = {
    var dbMigrator = DatabaseMigrator()
    
    return .init(
      migrations: {
        UnimplementedDBMigration.init()
      },
      register: { migration in
        dbMigrator.registerMigration(migration.identifier, migrate: migration.migrate(_:))
      }
    )
  }()
}

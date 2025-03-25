
import Foundation
@_exported import Dependencies
@_exported import DependenciesMacros
@_exported import GRDB

public extension DependencyValues {
    var grdb: GRDBClient {
        get { self[GRDBClient.self] }
        set { self[GRDBClient.self] = newValue }
    }
}

@DependencyClient
public struct GRDBClient: Sendable {
    public static let unimplemented = Self()
    
    public var reader: @Sendable () throws -> any DatabaseReader
    public var writer: @Sendable () throws -> any DatabaseWriter
}




// MARK: Test Dependency
extension GRDBClient: TestDependencyKey {
    public static let testValue: Self = .blankDBQueue
    
    /// An empty database, with schema, inMemory
    public static let blankDBQueue: GRDBClient = {
        let writer: DatabaseQueue = {
            
            let writer: DatabaseQueue
            
            // A shared in-memory database
            // See: https://swiftpackageindex.com/groue/grdb.swift/v6.23.0/documentation/grdb/databasequeue/init(named:configuration:)
            guard let dbQueue = try? DatabaseQueue(configuration: .defaultConfig) else {
                fatalError("Failed to create DatabaseQueue")
            }
            writer = dbQueue
            return writer
        }()
        
        return Self(reader: { writer }, writer: { writer })
    }()
    
    /// Creates a ``GRDBClient`` with a connection to the SQLite file at the given path
    /// - Parameters:
    ///   - dbPath: the path to the SQLite file
    ///   - configuration: the `GRDB.Configuration` of the database connection
    ///   - migrations: the migrations you woul dlike to perform in order.
    ///  Setup your database's schema here. Pass an empty array if you would like to skip this step entirely.
    ///   - backupOptions: configure your database backup while migrating. `nil` means no backups.
    /// - Returns: the ``GRDBClient``
    public static func databasePool(
        dbPath: String,
        configuration: GRDB.Configuration,
        migrations: [any DBMigration.Type],
        backupOptions: DatabaseMigrationBackupOptions? = nil
    ) throws -> GRDBClient {
        let pool = try DatabasePool(
            path: dbPath,
            configuration: configuration
        )
        
        Self.migrate(
            id: dbPath,
            writer: pool,
            withMigrations: migrations,
            backupOptions: backupOptions
        )
        
        return GRDBClient(reader: { pool }, writer: { pool })
    }
    
    
    /// Creates a ``GRDBClient`` with an in-memory connection to a new database.
    /// - Parameters:
    ///   - dbName: the name of the new database
    ///   - migrations: the migrations you would like to perform.
    ///   Setup your in memory database's schema here. Pass an empty array if you would like to skip this step entirely.
    ///   - backupOptions: configure your database backup while migrating. `nil` means no backups.
    /// - Returns: the GRDBClient
    public static func inMemoryDatabaseQueue(
        dbName: String = "database",
        configuration: Configuration = .defaultConfig,
        migrations: [any DBMigration.Type] = [],
        backupOptions: DatabaseMigrationBackupOptions? = nil
    ) -> GRDBClient {
        guard let queue = try?  DatabaseQueue(
            named: dbName,
            configuration: configuration
        ) else {
            fatalError("Failed to create blank in memory DatabaseQueue")
        }
        
        Self.migrate(
            id: dbName,
            writer: queue,
            withMigrations: migrations,
            backupOptions: backupOptions
        )
        
        
        return GRDBClient(
            reader: { queue },
            writer: { queue }
        )
    }
    
    /// Try migrating the database
    /// - Parameters:
    ///   - id: Some string to identify the database. Usually a file path or a name for an in memory database.
    ///   - writer: the ``DatabaseWriter``
    ///   - migrations: the migrations you would like to perform in order.
    ///   - backupOptions: configure your database backup while migrating. `nil` means no backups.
    fileprivate static func migrate(
        id: String,
        writer: any DatabaseWriter,
        withMigrations migrations: [any DBMigration.Type],
        backupOptions: DatabaseMigrationBackupOptions? = nil
    ) {
        if !migrations.isEmpty { // skip migrations if there are none.
            Log.logger(.migrations).info("Performing migrations: \(migrations)")
            let migrator = DatabaseMigrator(registeringMigrations: migrations)
            
            do {
                if let backupOptions {
                    // migrate with backups
                    try migrator.migrate(
                        writer,
                        backupOptions: backupOptions
                    )
                } else {
                    // YOLO: migrate without backups
                    try migrator.migrate(writer)
                }
                
            } catch {
                let completedMigrations = try? writer.read { db in
                    try migrator.completedMigrations(db)
                }
                guard let completedMigrations else {
                    // fatal error without completed migrations if we can't fetch it
                    fatalError("""
Failed to finish migrating database: \(id)
All registered migrations: \(migrator.migrations)
Completed migrations: COULD NOT FIND COMPLETED MIGRATIONS
""")
                }
                // fatal error with debug info
                fatalError("""
Failed to finish migrating database: \(id)
All registered migrations: \(migrator.migrations)
Completed migrations: \(completedMigrations)
Incomplete migrations: \(migrator.migrations.filter { !completedMigrations.contains($0) })
""")
            }
        }
    }
}



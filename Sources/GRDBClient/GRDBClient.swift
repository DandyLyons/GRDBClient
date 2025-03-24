
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
      var migrator = DatabaseMigrator()
      migrator.registerDBMigrations()
      do {
        try migrator.migrate(writer)
      } catch {
        fatalError("Failed to migrate db")
      }
      return writer
    }()
    
    return Self(
      reader: {
        writer
      },
      writer: {
        writer
      }
    )
  }()
  
  
  public static let inMemoryCopy: GRDBClient = {
    @Dependency(\.fileManager) var fileManager
    let writer: DatabaseQueue = {
      let result: DatabaseQueue
      let folderURL: URL?
      if #available(macOS 13.0, iOS 16.0, *) {
        folderURL = try? fileManager.default
          .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
          .appending(path: "database", directoryHint: .isDirectory)
      } else {
        folderURL = try? fileManager.default
          .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
          .appendingPathComponent("database", isDirectory: true)
      }
      guard let folderURL else {
        fatalError("Failed to find database folder")
      }
      do {
        try fileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
      } catch {}
      let dbURL: URL
      let dbQueue: DatabaseQueue?
      if #available(macOS 13.0, iOS 16.0, *) {
        dbURL = folderURL.appending(path: "db.sqlite")
        dbQueue = try? DatabaseQueue(path: dbURL.path(), configuration: .defaultConfig)
      } else {
        dbURL = folderURL.appendingPathComponent("db.sqlite", isDirectory: true)
        dbQueue = try? DatabaseQueue(path: dbURL.path, configuration: .defaultConfig)
        
      }
      guard let dbQueue else {
//#if DEBUG
        fatalError("Failed to make in memory copy of database.")
//#else
//        Logger.grdbClient().error("Failed to make in memory copy of database.")
//#endif
      }
      result = dbQueue
      var migrator = DatabaseMigrator()
      migrator.registerDBMigrations()
      do {
        try migrator.migrate(result)
      } catch {
//#if DEBUG
        fatalError("Failed to make in memory copy of database.")
//#else
//        Logger.grdbClient().error("Failed to make in memory copy of database.")
//#endif
      }
      return result
    }()
    
    return GRDBClient(
      reader: {
        writer
      },
      writer: {
        writer
      }
    )
  }()
}

extension GRDB.Configuration {
  public static let defaultConfig: Self = {
    var config = Configuration()
    config.prepareDatabase { db in
      db.trace { event in
#if DEBUG
        Logger.grdbClient().debug("SQL: \(event)")
#endif
      }
    }
    return config
  }()
}

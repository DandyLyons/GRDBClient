import Dependencies
import GRDB

extension DatabaseWriter {
  /// Removes all content from each table in the database, without ending the connection
  /// or removing the tables.
  public func clearDatabase() {
    do {
      try self.write { db in
        let allTables = ["liveEvent", "platform", "liveEventPlatform"]
        for table in allTables {
          try db.execute(sql: "DELETE FROM \(table)")
          
          // reset the auto incremented primary key
          try db.execute(sql: "DELETE FROM sqlite_sequence WHERE name = ?", arguments: [table])
        }
      }
    } catch {
      Logger.grdbClient().error("Failed to clear database: \(error)")
    }
  }
}

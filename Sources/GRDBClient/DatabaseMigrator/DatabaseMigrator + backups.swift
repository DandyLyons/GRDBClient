//
//  DatabaseMigrator + backups.swift
//  GRDBClient
//
//  Created by Daniel Lyons on 2025-03-24.
//

import Foundation
import GRDB
import System
import OSLog

extension DatabaseMigrator {
    
    public func migrate(
        _ writer: any DatabaseWriter,
        backupOptions: DatabaseMigrationBackupOptions
    ) throws {
        try self.migrate(
            writer,
            andBackupDatabaseAt: backupOptions.backupFilePath,
            deleteBackupIfSuccessful: backupOptions.deleteBackupIfSuccessful,
            pagesPerStep: backupOptions.pagesPerStep,
            progress: backupOptions.progress
        )
    }
    
    /// Migrates the database while backing up to the desired URL
    /// - **Parameters**:
    ///   - writer: the ``DatabaseWriter`` (and therefore database) to perform the migration on
    ///   - databaseBackupFilePath: the location to store the backup
    ///   - deleteBackupIfSuccessful: use `false` if you would like to keep the backup even if the migration is successful
    ///   - pagesPerStep: The number of database pages copied on each backup
    ///       step. By default, all pages are copied in one single step.
    ///   - progress: An optional function that is notified of the backup
    ///       progress.
    fileprivate func migrate(
        _ writer: any DatabaseWriter,
        andBackupDatabaseAt databaseBackupFilePath: String,
        deleteBackupIfSuccessful: Bool = true,
        pagesPerStep: CInt = -1,
        progress: ((DatabaseBackupProgress) throws -> Void)? = nil
    ) throws {
        // Backup the database
        let backupDBWriter: any DatabaseWriter = try DatabaseQueue(path: databaseBackupFilePath)
        try writer.backup(
            to: backupDBWriter,
            pagesPerStep: pagesPerStep,
            progress: progress
        )
        
        do {
            // Migrate the database
            try self.migrate(writer)
            
            // Optionally Delete the backup
            if deleteBackupIfSuccessful {
                try backupDBWriter.close()
                Logger.grdbClient(.backups).info("Migration was successful. Deleting backup now.")
                try FileManager.default.removeItem(atPath: databaseBackupFilePath)
            } else {
                Logger.grdbClient(.backups).info("Migration was successful. Pre-migration backup located at: \(databaseBackupFilePath)")
            }
        } catch {
            // If migration fails, log the error and keep the backup
            Logger.grdbClient(.migrations).error("Migration failed: \(error). Backup preserved at: \(databaseBackupFilePath)")
            throw error
        }
    }
}

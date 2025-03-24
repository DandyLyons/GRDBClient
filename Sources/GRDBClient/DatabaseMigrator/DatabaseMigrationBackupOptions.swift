//
//  DatabaseMigrationBackupOptions.swift
//  GRDBClient
//
//  Created by Daniel Lyons on 2025-03-24.
//

import Foundation
import GRDB

/// Options for how you would like to handle backups during a database migration.
public struct DatabaseMigrationBackupOptions: Sendable {
    let backupFilePath: String
    let deleteBackupIfSuccessful: Bool
    let pagesPerStep: CInt
    let progress: (@Sendable (DatabaseBackupProgress) throws -> Void)?
    
    public init(
        backupFilePath: String,
        deleteBackupIfSuccessful: Bool = true,
        pagesPerStep: CInt = -1,
        progress: (@Sendable (DatabaseBackupProgress) -> Void)? = nil
    ) {
        self.backupFilePath = backupFilePath
        self.deleteBackupIfSuccessful = deleteBackupIfSuccessful
        self.pagesPerStep = pagesPerStep
        self.progress = progress
    }
}

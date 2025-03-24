//
//  Configuration+.swift
//  GRDBClient
//
//  Created by Daniel Lyons on 2025-03-24.
//

import Foundation
import GRDB


extension GRDB.Configuration {
    /// A configuration that will
    public static let defaultConfig: Self = {
        var config = Configuration()
            .foreignKeyesEnabled(true)
        config.prepareDatabase { db in
            db.trace { event in
#if DEBUG
                Logger.grdbClient(.transactions).debug("SQL: \(event)")
#endif
            }
        }
        return config
    }()
    
    public func readOnly(_ newValue: Bool) -> Self {
        var copy = self
        copy.readonly = newValue
        return copy
    }
    
    public func journalMode(_ newValue: JournalModeConfiguration) -> Self {
        var copy = self
        copy.journalMode = newValue
        return copy
    }
    
    /// A boolean value indicating whether foreign key support is enabled. The default is true.
    public func foreignKeyesEnabled(_ newValue: Bool) -> Self {
        var copy = self
        copy.foreignKeysEnabled = newValue
        return copy
    }
}

import LoggerFactory

struct Log: LoggerFactory {
    static let subsystem: String = "GRDBClient"
    
    typealias Categories = GRDBClientCategories
    
    enum GRDBClientCategories: String, StringRawRepresentable {
        case transactions, migrations, backups
    }
}

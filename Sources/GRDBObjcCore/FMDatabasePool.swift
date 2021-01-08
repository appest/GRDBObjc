//
//  FMDatabasePool.swift
//  GRDBObjcCoreMacOS
//
//  Created by Ned on 7/1/2021.
//

import GRDB

@objc
public class FMDatabasePool: NSObject {
    public let dbPool: DatabasePool
    private var _fmdbs: [(dateBase: Database, fmdb: FMDatabase)] = []
    
    private func inFMDB<T>(_ db: Database, _ block: (FMDatabase) throws -> T) rethrows -> T {
        let fmdb: FMDatabase
        if let _fmdb = _fmdbs.first(where: { item -> Bool in
            item.dateBase === db
        })?.fmdb {
            fmdb = _fmdb
        } else {
            fmdb = FMDatabase(db)
            _fmdbs.append((db, fmdb))
        }
        return try withoutActuallyEscaping(block) { block in
            try fmdb.autoclosingResultSets { try block(fmdb) }
        }
    }
    
    public init(_ dbPool: DatabasePool) {
        self.dbPool = dbPool
    }
    
    @objc public var path: String {
        return dbPool.path
    }
    
    @objc public static func databasePool(path: String) -> FMDatabasePool? {
        return try? FMDatabasePool(path: path)
    }
    
    @objc public static func databasePool(path: String) throws -> FMDatabasePool {
        return try FMDatabasePool(path: path)
    }
    
    @objc public init(path: String) throws {
        dbPool = try DatabasePool(path: path)
    }
    
    @objc public func readInDatabase(_ block: (FMDatabase) -> ()) {
        withoutActuallyEscaping(block) { block in
            try? dbPool.read { db in
                inFMDB(db, block)
            }
        }
    }
    
    @objc public func writeInDatabase(_ block: (FMDatabase) -> ()) {
        withoutActuallyEscaping(block) { block in
            try? dbPool.write { db in
                inFMDB(db, block)
            }
        }
    }
    
    @objc public func writeInTransaction(
        _ block: (FMDatabase, UnsafeMutablePointer<ObjCBool>) -> ()
    ) {
        inTransaction(transactionKind: .immediate, block)
    }
    
    @objc public func writeInDeferredTransaction(
        _ block: (FMDatabase, UnsafeMutablePointer<ObjCBool>) -> ()
    ) {
        inTransaction(transactionKind: .deferred, block)
    }
    
    func inTransaction(
        transactionKind: Database.TransactionKind = .immediate,
        _ block: (FMDatabase, UnsafeMutablePointer<ObjCBool>) -> ()
    ) {
        var crashOnErrors = false
        var logsErrors = false
        do {
            try withoutActuallyEscaping(block) { block in
                try dbPool.writeInTransaction(transactionKind) { db in
                    inFMDB(db) { fmdb in
                        var rollback: ObjCBool = false
                        let transactionCompletion = withUnsafeMutablePointer(to: &rollback) { rollbackp -> Database.TransactionCompletion in
                            block(fmdb, rollbackp)
                            return rollbackp.pointee.boolValue ? .rollback : .commit
                        }
                        crashOnErrors = fmdb.crashOnErrors
                        logsErrors = fmdb.crashOnErrors
                        return transactionCompletion
                    }
                }
            }
        } catch {
            if logsErrors { NSLog("DB Error: %@", "\(error)") }
            if crashOnErrors { fatalError("\(error)") }
        }
    }
}

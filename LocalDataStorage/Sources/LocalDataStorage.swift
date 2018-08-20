//
//  LocalDataStorage.swift
//  Nioxin
//
//  Created by Evgeniy Leychenko on 22.06.17.
//  Copyright © 2017 grossum solutions. All rights reserved.
//

import Foundation
import CoreData
import AERecord

public protocol LocalDataStorage {
    @discardableResult
    func fetchAll<ManagedType: NSManagedObject>(from objectsClass: ManagedType.Type, withPredicate predicate: NSPredicate?,
                                                orderedBy sortDescriptors: [NSSortDescriptor]?) -> [ManagedType]?
    @discardableResult
    func fetchOne<ManagedType: NSManagedObject>(from objectClass: ManagedType.Type,
                                                withPredicate predicate: NSPredicate?) -> ManagedType?
    @discardableResult
    func create<ManagedType: NSManagedObject>(into: ManagedType.Type, quantity: Int,
                                              with setup:@escaping (Int, ManagedType) -> Void) -> [ManagedType]
    func updateObjects<ManagedType: NSManagedObject>(from: ManagedType.Type, predicate: NSPredicate?,
                                                     with update:@escaping (Int, ManagedType) -> Void)
    func delete<ManagedType: NSManagedObject>(from objectsClass: ManagedType.Type, withPredicate predicate: NSPredicate?)
    func save()
}

open class DefaultLocalDataStorage: LocalDataStorage {
    
    public init() {
        do {
            try AERecord.loadCoreDataStack()
        } catch {
            print(error)
            fatalError()
        }
    }
    
    open func fetchAll<ManagedType: NSManagedObject>(from objectsClass: ManagedType.Type, withPredicate predicate: NSPredicate? = nil,
                                                     orderedBy sortDescriptors: [NSSortDescriptor]? = nil) -> [ManagedType]? {
        guard let predicate = predicate else {
            return ManagedType.all(orderedBy: sortDescriptors, in: AERecord.Context.default)
        }
        return ManagedType.all(with: predicate, orderedBy: sortDescriptors, in: AERecord.Context.default)
    }
    
    open func fetchOne<ManagedType: NSManagedObject>(from objectClass: ManagedType.Type,
                                                     withPredicate predicate: NSPredicate? = nil) -> ManagedType? {
        guard let predicate = predicate else {
            return ManagedType.first()
        }
        return ManagedType.first(with: predicate)
    }
    
    @discardableResult
    open func create<ManagedType: NSManagedObject>(into: ManagedType.Type, quantity: Int,
                                                   with setup:@escaping (Int, ManagedType) -> Void) -> [ManagedType] {
        var createdObjects: [ManagedType] = []
        for index in 0..<quantity {
            let managedObject = ManagedType.create()
            setup(index, managedObject)
            createdObjects.append(managedObject)
        }
        save()
        return createdObjects
    }
    
    open func updateObjects<ManagedType: NSManagedObject>(from: ManagedType.Type, predicate: NSPredicate? = nil,
                                                          with update:@escaping (Int, ManagedType) -> Void) {
        guard let objectsToUpdate = fetchAll(from: ManagedType.self, withPredicate: predicate, orderedBy: nil) else { return }
        objectsToUpdate.enumerated().forEach { (index, object) in
            update(index, object)
        }
        save()
    }
    
    open func delete<ManagedType: NSManagedObject>(from objectsClass: ManagedType.Type, withPredicate predicate: NSPredicate? = nil) {
        if let predicate = predicate {
            ManagedType.deleteAll(with: predicate)
        } else {
            ManagedType.deleteAll()
        }
        save()
    }
    
    open func save() {
        AERecord.saveAndWait()
    }
    
}

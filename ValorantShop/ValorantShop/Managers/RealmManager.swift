//
//  RealmManager.swift
//  ValorantShop
//
//  Created by 김건우 on 2023/09/15.
//

import RealmSwift

final class RealmManager {
    
    // MARK: - SINGLETON
    static let shared = RealmManager()
    private init() {
        let configuration = Realm.Configuration.init(
            deleteRealmIfMigrationNeeded: true
        )
        realm = try! Realm(configuration: configuration)
    }
    
    // MARK: - PROPERTIES
    
    let realm: Realm
    
    // MARK: - FUNCTIONS
    
    func create<T: Object>(_ object: T) {
        try! realm.write {
            realm.add(object)
        }
    }
    
    func read<T: Object>(of type: T.Type) -> Results<T> {
        return realm.objects(type)
    }
    
    func overwrite<T: Object>(_ object: T) {
        // 데이터를 저장하기 전, 기존 데이터 삭제하기
        self.deleteAll(of: T.self)
        // 새로운 데이터 저장하기
        self.create(object)
    }
    
    func delete<T: Object>(of type: T.Type, object: T) {
        try! realm.write {
            realm.delete(object)
        }
    }
    
    func deleteAll<T: Object>(of type: T.Type) {
        let objects = self.read(of: type)
        
        try! realm.write {
            realm.delete(objects)
        }
    }
    
    func deleteAll() {
        try! realm.write {
            realm.deleteAll()
        }
    }
}

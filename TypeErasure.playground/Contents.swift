// TYPE ERASURE
// Источник информации: https://www.donnywals.com/understanding-type-erasure-in-swift/

// Протокол некого хранилища
protocol Storage {
    // Тип, который будет храниться в хранилище
    associatedtype StoredType
    // Функция добавления обьекта в хранилище
    func input(_ object: StoredType, forKey: String)
    // Функция получения обьекта из хранилища
    func get(forKey key: String) -> StoredType?
}

// Обертка над хранилищем для реализации type erasure
class AnyStorage<StoredType>: Storage {
    // Клоужер для делегирования  функции добавления
    private let input: (StoredType, String) -> Void
    // Клоужер для делегирования  функции получения
    private let get: (String) -> StoredType?
    
    init<Store: Storage>(store: Store) where Store.StoredType == StoredType {
        self.input = store.input
        self.get = store.get
    }
    
    // Перекладываем выполнение функции добавления значения в хранилище
    func input(_ value: StoredType, forKey key: String) {
        input(value, key)
    }
    
    // Перекладываем выполнение функции получения значения из хранилища
    func get(forKey key: String) -> StoredType? {
        return get(key)
    }
}

// Некое хранилище Int значений
struct SomeIntStorage: Storage {
    typealias StoredType = Int
    
    func input(_ value: Int, forKey key: String) {
        print("Inputted \(value) in \(StoredType.Type.self) storage")
    }
    
    func get(forKey key: String) -> Int? {
        print("Got value for key \(key) in \(StoredType.Type.self) storage")
        return nil
    }
}

// Некое хранилище String значений
struct SomeStringStorage: Storage {
    typealias StoredType = String
    
    func input(_ value: String, forKey key: String) {
        print("Inputted \(value) in \(StoredType.Type.self) storage")
    }
    
    func get(forKey key: String) -> String? {
        print("Got value for key \(key) in \(StoredType.Type.self) storage")
        return nil
    }
}

// Некий менеджер по управлению хранилищем
class StorageManager<StoredType> {
    private var storage: AnyStorage<StoredType>?
    
    // Функция для установки хранилища в менеджер
    func setStorage(storage: AnyStorage<StoredType>) {
        self.storage = storage
    }
    
    // Функция "проверки работоспособности" хранилища
    func checkStorageFunctions(key: String, value: StoredType) {
        guard let storage = self.storage else { return }
        
        storage.input(value, forKey: key)
        storage.get(forKey: key)
    }
}

let intStorageManager = StorageManager<Int>()
intStorageManager.setStorage(storage: AnyStorage(store: SomeIntStorage()))
intStorageManager.checkStorageFunctions(key: "SomeKey", value: 1)

let stringStorageManager = StorageManager<String>()
stringStorageManager.setStorage(storage: AnyStorage(store: SomeStringStorage()))
stringStorageManager.checkStorageFunctions(key: "SomeKey", value: "SomeValue")

// COPY ON WRITE
// Источник информации: https://marcosantadev.com/copy-write-swift-value-types/

// Наша структура, для которой мы реализуем copy on write
struct Student {
    var grade: String
   
    init(grade: Int) {
        self.grade = "\(grade) grade"
    }
}

// Обертка ссылочного типа для нашей структуры
final class Ref<T> {
    var value: T
    
    init(value: T) {
        self.value = value
    }
}

// Обертка для ссылочного типа, реализующая copy on write
struct Box<T> {
    private var ref: Ref<T>
    init(value: T) {
        ref = Ref(value: value)
    }

    var value: T {
        get { return ref.value }
        set {
            // isKnownUniquelyReferenced - Возвращает логическое значение, указывающее, известно ли, что данный объект имеет единственную сильную ссылку, если нет, то создаем новый экземпляр
            guard isKnownUniquelyReferenced(&ref) else {
                ref = Ref(value: newValue)
                return
            }
            ref.value = newValue
        }
    }
}

let student1 = Student(grade: 1)

let boxStudent1 = Box(value: student1)
var boxStudent2 = boxStudent1
// На этом моменте у них одинаковая ссылка

boxStudent2.value.grade = "No grade"
// На этом моменте создался новый экземпляр, а следовательно и новая ссылка


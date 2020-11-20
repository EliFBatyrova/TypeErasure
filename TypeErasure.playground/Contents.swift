import Foundation

// Type Erasure

// Абстрактный наблюдатель, способный принимать оповещения
protocol Observer {
    associatedtype Event
    
    func notify(with event: Event)
}

// Обертка для стирания типов
final class AnyObserver<Event>: Observer {
    
    private var notifyClosure: (Event) -> Void
    
    init<P: Observer>(_ observer: P) where P.Event == Event {
        notifyClosure = observer.notify
    }
    
    func notify(with event: Event) {
        notifyClosure(event)
    }
}

// Эмиттер, умеющий рассылать своим подписчикам некоторые события
class Emitter<T> {
    
    private var observers: [AnyObserver<T>] = []
    
    func addObserver(_ observer: AnyObserver<T>) {
        observers.append(observer)
    }
    
    func emit(event: T) {
        observers.forEach { $0.notify(with: event) }
    }
}

// Наблюдатель, печатающий квадрат пришедшего значения
class SquareIntObserver: Observer {
    func notify(with event: Int) {
        print("Square of received value = \(event * event)")
    }
}

// Наблюдатель, печатающий корень пришедшего значения
class SquareRootIntObserver: Observer {
    func notify(with event: Int) {
        print("Square root of received value = \(sqrt(Double(event)))")
    }
}

let intEmitter = Emitter<Int>()

let squareObserver = SquareIntObserver()
let squareRootObserver = SquareRootIntObserver()

intEmitter.addObserver(AnyObserver(squareObserver))
intEmitter.addObserver(AnyObserver(squareRootObserver))

intEmitter.emit(event: 2)
intEmitter.emit(event: 4)

// Copy on write

struct Person {
    var name: String
}

// Сущность, эмулирующая ссылку на некоторый объект
class Reference<T> {
    var object: T
    
    init(_ object: T) {
        self.object = object
    }
}

struct BoxedPerson {
    
    var reference: Reference<Person>
    
    init(_ person: Person) {
        reference = Reference(person)
    }
    
    var name: String {
        get {
            return reference.object.name
        }
        set {
            if !isKnownUniquelyReferenced(&reference) {
                reference = Reference(Person(name: newValue))
            }
            else {
                reference.object.name = newValue
            }
        }
    }
}

var person = Person(name: "Ann")

var boxed = BoxedPerson(person)
var anotherBoxed = boxed

withUnsafePointer(to: &boxed.reference.object) { pointer in
    print(pointer) // 0x000060000015aed0
}

withUnsafePointer(to: &anotherBoxed.reference.object) { pointer in
    print(pointer) // 0x000060000015aed0
}

anotherBoxed.name = "Peter" // В этот момент isKnownUniquelyReferenced(&reference) вернет false, ведь anotherBoxed, будучи копией boxed уже держит вторую ссылку на Reference, поэтому сеттер создаст новый референс для новой структуры

withUnsafePointer(to: &boxed.reference.object) { pointer in
    print(pointer) // 0x000060000015aed0
}

withUnsafePointer(to: &anotherBoxed.reference.object) { pointer in
    print(pointer) // 0x0000600000148290
}


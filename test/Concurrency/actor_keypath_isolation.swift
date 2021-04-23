// RUN: %target-typecheck-verify-swift -enable-experimental-concurrency -warn-concurrency
// REQUIRES: concurrency

class Box {
    let size : Int = 0
}

actor Door {
    nonisolated let immutable : Int = 0
    let letBox : Box? = nil
    let letDict : [Int : Box] = [:]
    nonisolated let immutableNeighbor : Door? = nil


    var mutableNeighbor : Door? = nil
    var varDict : [Int : Box] = [:]
    var mutable : Int = 0
    var varBox : Box = Box()
    var getOnlyInt : Int {
        get { 0 }
    }

    @actorIndependent(unsafe) var unsafeIndependent : Int = 0

    @MainActor var globActor_mutable : Int = 0
    @MainActor let globActor_immutable : Int = 0

    @MainActor(unsafe) var unsafeGlobActor_mutable : Int = 0
    @MainActor(unsafe) let unsafeGlobActor_immutable : Int = 0

    subscript(byIndex: Int) -> Int { 0 }

    @MainActor subscript(byName: String) -> Int { 0 }

    @actorIndependent subscript(byIEEE754: Double) -> Int { 0 }
}

func attemptAccess<T, V>(_ t : T, _ f : (T) -> V) -> V {
    return f(t)
}

func tryKeyPathsMisc(d : Door) {
    // as a func
    _ = attemptAccess(d, \Door.mutable) // expected-error {{cannot form key path to actor-isolated property 'mutable'}}
    _ = attemptAccess(d, \Door.immutable)
    _ = attemptAccess(d, \Door.immutableNeighbor?.immutableNeighbor)

    // in combination with other key paths

    _ = (\Door.letBox).appending(path:  // expected-error {{cannot form key path to actor-isolated property 'letBox'}}
                                       \Box?.?.size)

    _ = (\Door.varBox).appending(path:  // expected-error {{cannot form key path to actor-isolated property 'varBox'}}
                                       \Box.size)

}

func tryKeyPathsFromAsync() async {
    _ = \Door.unsafeGlobActor_immutable
    _ = \Door.unsafeGlobActor_mutable // okay for now
}

func tryNonSendable() {
    _ = \Door.letDict[0] // expected-error {{cannot form key path to actor-isolated property 'letDict'}}
    _ = \Door.varDict[0] // expected-error {{cannot form key path to actor-isolated property 'varDict'}}
    _ = \Door.letBox!.size // expected-error {{cannot form key path to actor-isolated property 'letBox'}}
}

func tryKeypaths() {
    _ = \Door.unsafeGlobActor_immutable
    _ = \Door.unsafeGlobActor_mutable // okay for now

    _ = \Door.immutable
    _ = \Door.unsafeIndependent
    _ = \Door.globActor_immutable
    _ = \Door.[4.2]
    _ = \Door.immutableNeighbor?.immutableNeighbor?.immutableNeighbor

    _ = \Door.varBox // expected-error{{cannot form key path to actor-isolated property 'varBox'}}
    _ = \Door.mutable  // expected-error{{cannot form key path to actor-isolated property 'mutable'}}
    _ = \Door.getOnlyInt  // expected-error{{cannot form key path to actor-isolated property 'getOnlyInt'}}
    _ = \Door.mutableNeighbor?.mutableNeighbor?.mutableNeighbor // expected-error 3 {{cannot form key path to actor-isolated property 'mutableNeighbor'}}

    let _ : PartialKeyPath<Door> = \.mutable // expected-error{{cannot form key path to actor-isolated property 'mutable'}}
    let _ : AnyKeyPath = \Door.mutable  // expected-error{{cannot form key path to actor-isolated property 'mutable'}}

    _ = \Door.globActor_mutable // okay for now
    _ = \Door.[0] // expected-error{{cannot form key path to actor-isolated subscript 'subscript(_:)'}}
    _ = \Door.["hello"] // okay for now
}

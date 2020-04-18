public protocol SharedEvent: Event {
    func makeSharedEventHandle() -> SharedEventHandle
}

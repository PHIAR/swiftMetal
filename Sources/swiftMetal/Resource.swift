public protocol Resource {
    var device: Device { get }
    var label: String? { get nonmutating set }

    var allocatedSize: Int { get }
    var storageMode: StorageMode { get }
}

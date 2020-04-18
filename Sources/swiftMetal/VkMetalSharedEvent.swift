internal final class VkMetalSharedEvent: VkMetalEvent,
                                         SharedEvent {
    func makeSharedEventHandle() -> SharedEventHandle {
        return SharedEventHandle()
    }
}

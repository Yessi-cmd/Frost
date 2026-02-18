import AppKit
import Carbon.HIToolbox
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var cancellables = Set<AnyCancellable>()
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    let viewModel = FrostViewModel.shared

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.accessory)
        SafetyGuard.shared.recoverIfNeeded()

        setupStatusItem()
        setupPopover()
        observeState()
        registerGlobalHotKey()
    }

    func applicationWillTerminate(_: Notification) {
        if viewModel.isFocusMode {
            viewModel.exitFocusMode()
        }
        unregisterGlobalHotKey()
    }

    // MARK: - Status Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }

        button.image = makeIcon(name: "snowflake", template: true)
        button.imagePosition = .imageLeading
        button.action = #selector(togglePopover)
        button.target = self
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 460)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(closePopover: { [weak self] in
                self?.popover.performClose(nil)
            })
            .environmentObject(viewModel)
        )
    }

    private func observeState() {
        Publishers.CombineLatest(viewModel.$isFocusMode, viewModel.$frozenCount)
            .receive(on: RunLoop.main)
            .sink { [weak self] active, count in
                self?.updateStatusBar(active: active, frozenCount: count)
            }
            .store(in: &cancellables)
    }

    private func updateStatusBar(active: Bool, frozenCount: Int) {
        guard let button = statusItem.button else { return }

        let name = active ? "snowflake.circle.fill" : "snowflake"
        button.image = makeIcon(name: name, template: !active)
        button.contentTintColor = active ? .controlAccentColor : nil

        if active && frozenCount > 0 {
            button.title = " \(frozenCount)"
            button.imagePosition = .imageLeading
        } else {
            button.title = ""
            button.imagePosition = .imageOnly
        }
    }

    private func makeIcon(name: String, template: Bool) -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        if let image = NSImage(
            systemSymbolName: name,
            accessibilityDescription: "Frost"
        )?.withSymbolConfiguration(config) {
            image.isTemplate = template
            return image
        }
        // Fallback: always return a valid snowflake icon
        let fallback = NSImage(
            systemSymbolName: "snowflake",
            accessibilityDescription: "Frost"
        ) ?? NSImage()
        fallback.isTemplate = template
        return fallback
    }

    // MARK: - Popover

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            viewModel.refreshApps()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Global Hotkey (Cmd+Shift+F)

    private func registerGlobalHotKey() {
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        let keyCode: UInt32 = UInt32(kVK_ANSI_F)
        let hotKeyID = EventHotKeyID(signature: OSType(0x46525354), id: 1)
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef)
        guard status == noErr else { return }

        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetEventDispatcherTarget(), { (_, _, _) -> OSStatus in
            Task { @MainActor in
                FrostViewModel.shared.toggleFocusMode()
            }
            return noErr
        }, 1, &eventSpec, nil, &eventHandlerRef)
    }

    private func unregisterGlobalHotKey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = eventHandlerRef {
            RemoveEventHandler(ref)
            eventHandlerRef = nil
        }
    }
}

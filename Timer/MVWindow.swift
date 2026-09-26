import AppKit

final class MVWindow: NSPanel {
  convenience init(mainView: NSView) {
    let staysOnTop = UserDefaults.standard.bool(forKey: MVUserDefaultsKeys.staysOnTop)
    var styleMask: NSWindow.StyleMask = [.closable, .titled]
    if staysOnTop {
      styleMask.insert(.nonactivatingPanel)
    }
    let size: CGFloat = 150.0
    let titleBarHeight = Self.frameRect(
      forContentRect: NSRect(x: 0, y: 0, width: size, height: size),
      styleMask: styleMask
    ).size.height - size

    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
    let windowFrame = NSRect(
      x: screenFrame.width / 2 - size / 2,
      y: screenFrame.height / 2 - size / 2,
      width: size,
      height: size - titleBarHeight
    )

    self.init(
      contentRect: windowFrame,
      styleMask: styleMask,
      backing: .buffered,
      defer: true
    )

    // Panels hide when the app deactivates by default, timers should stay visible
    self.hidesOnDeactivate = false
    self.applyStaysOnTop(staysOnTop)

    mainView.frame = NSRect(x: 0, y: 0, width: size, height: size)

    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true

    // Create a transparent titlebar accessory to overlay the window (to capture drag events)
    let titleBarController = MVTitlebarAccessoryViewController()
    titleBarController.view.frame = NSRect(x: 0, y: 0, width: size, height: windowFrame.size.height)
    self.addTitlebarAccessoryViewController(titleBarController)

    // Hide some of the default window buttons
    self.standardWindowButton(.miniaturizeButton)?.isHidden = true
    self.standardWindowButton(.zoomButton)?.isHidden = true

    // Adjust the close button
    if let closeButton = self.standardWindowButton(.closeButton) {
      var closeFrame = closeButton.frame
      closeFrame.origin.y -= 2
      closeButton.frame = closeFrame

      // Add the main clock view as a sibling underneath the close button
      closeButton.superview?.addSubview(mainView, positioned: .below, relativeTo: closeButton)
    }
  }

  func applyStaysOnTop(_ staysOnTop: Bool) {
    self.level = staysOnTop ? .floating : .normal

    // Joining all Spaces as a full screen auxiliary window lets the timer float
    // above other apps' full screen windows. macOS only shows non-activating
    // panels there, so the style is toggled along with the behavior.
    self.collectionBehavior = staysOnTop ? [.canJoinAllSpaces, .fullScreenAuxiliary] : []
    if self.styleMask.contains(.nonactivatingPanel) != staysOnTop {
      if staysOnTop {
        self.styleMask.insert(.nonactivatingPanel)
      } else {
        self.styleMask.remove(.nonactivatingPanel)
      }
    }
  }
}

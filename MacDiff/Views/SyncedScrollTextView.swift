import SwiftUI
import AppKit

// MARK: - Scroll Sync Row View

/// NSTableRowView subclass that draws per-row diff background colors.
final class DiffRowView: NSTableRowView {
    var diffKind: DiffKind = .equal { didSet { needsDisplay = true } }

    override func drawBackground(in dirtyRect: NSRect) {
        switch diffKind {
        case .insertion:
            NSColor(calibratedRed: 0.12, green: 0.78, blue: 0.47, alpha: 0.22).setFill()
            dirtyRect.fill()
        case .deletion:
            NSColor(calibratedRed: 0.93, green: 0.28, blue: 0.28, alpha: 0.22).setFill()
            dirtyRect.fill()
        case .empty:
            NSColor.systemGray.withAlphaComponent(0.07).setFill()
            dirtyRect.fill()
        case .equal:
            super.drawBackground(in: dirtyRect)
        }
    }

    // Suppress selection highlight — row colors convey all state
    override var isSelected: Bool {
        get { false }
        set { }
    }
    override func drawSelection(in dirtyRect: NSRect) { }
}

// MARK: - Table Coordinator

/// NSTableView data-source + delegate + scroll-sync observer.
final class DiffTableCoordinator: NSObject,
                                   NSTableViewDataSource,
                                   NSTableViewDelegate {

    // Data
    var lines: [DiffLine] = []

    // Scroll sync
    let scrollSync: ScrollSyncController
    let side: FileSide
    var isSyncing = false
    weak var scrollView: NSScrollView?

    // Track last known first-row ID to avoid expensive reloadData on scroll-only updates
    var lastFirstID: UUID?
    var lastCount = 0

    static let rowHeight:     CGFloat = 20
    static let lineNumWidth:  CGFloat = 50

    init(scrollSync: ScrollSyncController, side: FileSide) {
        self.scrollSync = scrollSync
        self.side = side
    }

    // MARK: DataSource

    func numberOfRows(in tableView: NSTableView) -> Int { lines.count }

    // MARK: Delegate — Cell views

    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView? {
        guard row < lines.count else { return nil }
        let line  = lines[row]
        let colId = tableColumn?.identifier.rawValue ?? "content"

        if colId == "lineNum" {
            let id  = NSUserInterfaceItemIdentifier("lineNumCell")
            let cell = (tableView.makeView(withIdentifier: id, owner: nil) as? NSTextField)
                       ?? makeField(id: id, monospaced: true, size: 11, selectable: false)
            cell.alignment   = .right
            cell.textColor   = .tertiaryLabelColor
            cell.stringValue = line.lineNumber.map { "\($0)" } ?? ""
            return cell
        } else {
            let id   = NSUserInterfaceItemIdentifier("contentCell")
            let cell = (tableView.makeView(withIdentifier: id, owner: nil) as? NSTextField)
                       ?? makeField(id: id, monospaced: false, size: 13, selectable: true)
            cell.font        = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
            cell.textColor   = .labelColor
            cell.stringValue = line.content
            return cell
        }
    }

    // MARK: Delegate — Row views

    func tableView(_ tableView: NSTableView,
                   rowViewForRow row: Int) -> NSTableRowView? {
        let id = NSUserInterfaceItemIdentifier("DiffRowView")
        let rv = (tableView.makeView(withIdentifier: id, owner: nil) as? DiffRowView)
                 ?? DiffRowView()
        rv.identifier = id
        rv.diffKind   = row < lines.count ? lines[row].kind : .equal
        return rv
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        Self.rowHeight
    }

    // MARK: Scroll sync

    @objc func boundsDidChange(_ notification: Notification) {
        guard !isSyncing,
              let clip = notification.object as? NSClipView else { return }
        isSyncing = true
        scrollSync.update(offset: clip.bounds.origin, from: side)
        isSyncing = false
    }

    // MARK: Helper

    private func makeField(id: NSUserInterfaceItemIdentifier,
                           monospaced: Bool,
                           size: CGFloat,
                           selectable: Bool) -> NSTextField {
        let f = NSTextField()
        f.identifier      = id
        f.isEditable      = false
        f.isSelectable    = selectable
        f.isBordered      = false
        f.drawsBackground = false
        f.lineBreakMode   = .byClipping
        f.font = monospaced
            ? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
            : NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        return f
    }
}

// MARK: - DiffScrollView (NSViewRepresentable)

/// Wraps an NSScrollView + NSTableView for colored, synchronized diff display.
struct DiffScrollView: NSViewRepresentable {
    let lines:      [DiffLine]
    let scrollSync: ScrollSyncController
    /// Passed explicitly so SwiftUI detects changes and calls updateNSView.
    let syncOffset: CGPoint
    let side:       FileSide

    func makeCoordinator() -> DiffTableCoordinator {
        DiffTableCoordinator(scrollSync: scrollSync, side: side)
    }

    func makeNSView(context: Context) -> NSScrollView {
        // ── Table view ────────────────────────────────────────────────
        let tv = NSTableView()
        tv.headerView                 = nil
        tv.intercellSpacing           = .zero
        tv.usesAlternatingRowBackgroundColors = false
        tv.selectionHighlightStyle    = .none
        tv.backgroundColor            = .clear
        tv.rowHeight                  = DiffTableCoordinator.rowHeight
        tv.delegate                   = context.coordinator
        tv.dataSource                 = context.coordinator
        tv.focusRingType              = .none
        tv.allowsColumnSelection      = false
        tv.columnAutoresizingStyle    = .lastColumnOnlyAutoresizingStyle

        let numCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("lineNum"))
        numCol.title      = ""
        numCol.width      = DiffTableCoordinator.lineNumWidth
        numCol.minWidth   = DiffTableCoordinator.lineNumWidth
        numCol.maxWidth   = DiffTableCoordinator.lineNumWidth
        numCol.resizingMask = []
        tv.addTableColumn(numCol)

        let contentCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("content"))
        contentCol.title        = ""
        contentCol.resizingMask = .autoresizingMask
        tv.addTableColumn(contentCol)

        // ── Scroll view ───────────────────────────────────────────────
        let sv = NSScrollView()
        sv.documentView     = tv
        sv.hasVerticalScroller   = true
        sv.hasHorizontalScroller = true
        sv.autohidesScrollers    = true
        sv.borderType            = .noBorder
        sv.drawsBackground       = false

        // ── Sync wiring ───────────────────────────────────────────────
        sv.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(DiffTableCoordinator.boundsDidChange(_:)),
            name: NSView.boundsDidChangeNotification,
            object: sv.contentView
        )
        context.coordinator.scrollView = sv
        return sv
    }

    func updateNSView(_ sv: NSScrollView, context: Context) {
        guard let tv = sv.documentView as? NSTableView else { return }
        let coord = context.coordinator

        // Only reload when the diff result changed (detected via first-row ID + count)
        let newFirstID = lines.first?.id
        if newFirstID != coord.lastFirstID || lines.count != coord.lastCount {
            coord.lines       = lines
            coord.lastFirstID = newFirstID
            coord.lastCount   = lines.count
            tv.reloadData()
        }

        // Apply scroll sync — but only on the pane that DIDN'T trigger it
        guard !coord.isSyncing,
              scrollSync.lastUpdatedSide != side else { return }

        let target  = syncOffset
        let current = sv.contentView.bounds.origin
        guard abs(target.y - current.y) > 1.0 ||
              abs(target.x - current.x) > 1.0 else { return }

        coord.isSyncing = true
        sv.contentView.scroll(to: target)
        sv.reflectScrolledClipView(sv.contentView)
        coord.isSyncing = false
    }
}

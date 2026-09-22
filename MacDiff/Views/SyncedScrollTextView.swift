import SwiftUI
import AppKit

// MARK: - Diff Gutter View (Pinned Line Numbers)

/// Pinned left-hand gutter that renders line numbers and diff highlights without scrolling horizontally.
final class DiffGutterView: NSView {
    var lines: [DiffLine] = [] { didSet { needsDisplay = true } }
    var scrollOffsetY: CGFloat = 0 { didSet { needsDisplay = true } }
    weak var scrollView: NSScrollView?
    weak var tableView: NSTableView?

    static let rowHeight: CGFloat = 22
    static let numberWidth: CGFloat = 50
    static let signWidth: CGFloat = 18
    static var width: CGFloat { numberWidth + signWidth }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        // Avoid layer-backed drawing quirks that leave sub-pixel gaps on recent macOS.
        wantsLayer = false
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        DiffTheme.gutterBackground.setFill()
        bounds.fill()

        guard !lines.isEmpty else { return }

        let startRow = max(0, Int(scrollOffsetY / Self.rowHeight))
        let endRow   = min(lines.count - 1, Int((scrollOffsetY + bounds.height) / Self.rowHeight) + 1)
        guard startRow <= endRow else { return }

        let numberFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        let signFont   = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)

        for row in startRow...endRow {
            let line = lines[row]

            // Prefer the table's real row frame so highlights stay locked to content
            // rows (inset/plain style and fractional scroll offsets on new macOS).
            let rowY: CGFloat
            let rowH: CGFloat
            if let tv = tableView, row < tv.numberOfRows {
                let rect = tv.rect(ofRow: row)
                rowY = rect.origin.y - scrollOffsetY
                rowH = rect.height
            } else {
                rowY = CGFloat(row) * Self.rowHeight - scrollOffsetY
                rowH = Self.rowHeight
            }

            let fullRect = NSRect(x: 0, y: rowY.rounded(.towardZero), width: bounds.width, height: rowH.rounded(.up))

            DiffTheme.gutterFill(for: line.kind).setFill()
            fullRect.fill()

            let fg = DiffTheme.gutterForeground(for: line.kind)
            let signRect = NSRect(x: Self.numberWidth, y: fullRect.origin.y, width: Self.signWidth, height: fullRect.height)

            if let num = line.lineNumber {
                let str = "\(num)" as NSString
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: numberFont,
                    .foregroundColor: fg
                ]
                let strSize = str.size(withAttributes: attrs)
                // Right-align in the number column with comfortable trailing padding.
                let textRect = NSRect(
                    x: Self.numberWidth - strSize.width - 8,
                    y: fullRect.origin.y + (fullRect.height - strSize.height) / 2,
                    width: strSize.width,
                    height: strSize.height
                )
                str.draw(in: textRect, withAttributes: attrs)
            }

            let sign: String? = {
                switch line.kind {
                case .insertion: return "+"
                case .deletion:  return "−"
                default:         return nil
                }
            }()

            if let sign {
                let str = sign as NSString
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: signFont,
                    .foregroundColor: fg
                ]
                let strSize = str.size(withAttributes: attrs)
                let textRect = NSRect(
                    x: signRect.minX + (signRect.width - strSize.width) / 2,
                    y: fullRect.origin.y + (fullRect.height - strSize.height) / 2,
                    width: strSize.width,
                    height: strSize.height
                )
                str.draw(in: textRect, withAttributes: attrs)
            }
        }

        NSColor.separatorColor.withAlphaComponent(0.35).setFill()
        NSRect(x: bounds.width - 1, y: 0, width: 1, height: bounds.height).fill()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func scrollWheel(with event: NSEvent) {
        scrollView?.scrollWheel(with: event)
    }
}

// MARK: - Scroll Sync Row View

/// NSTableRowView subclass that draws per-row diff background colors across the code content area.
final class DiffRowView: NSTableRowView {
    var diffKind: DiffKind = .equal { didSet { needsDisplay = true } }

    override func drawBackground(in dirtyRect: NSRect) {
        if let fill = DiffTheme.rowFill(for: diffKind) {
            fill.setFill()
            // Fill the full row bounds (not just dirtyRect) so highlights stay
            // edge-to-edge and align with the gutter on recent macOS.
            bounds.fill()
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    // Suppress selection highlight — row colors convey all state
    override var isSelected: Bool {
        get { false }
        set { }
    }
    override func drawSelection(in dirtyRect: NSRect) { }
}

// MARK: - Diff Container View

/// Combines the pinned line-number gutter on the left with the scrollable content table on the right.
final class DiffContainerView: NSView {
    let gutterView: DiffGutterView
    let scrollView: NSScrollView
    let tableView:  NSTableView

    init(gutterView: DiffGutterView, scrollView: NSScrollView, tableView: NSTableView) {
        self.gutterView = gutterView
        self.scrollView = scrollView
        self.tableView  = tableView
        super.init(frame: .zero)

        addSubview(gutterView)
        addSubview(scrollView)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        let gw = DiffGutterView.width
        gutterView.frame = NSRect(x: 0, y: 0, width: gw, height: bounds.height)
        scrollView.frame = NSRect(x: gw, y: 0, width: max(0, bounds.width - gw), height: bounds.height)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        gutterView.needsDisplay = true
        tableView.reloadData()
        tableView.enumerateAvailableRowViews { rowView, _ in
            rowView.needsDisplay = true
        }
    }
}

// MARK: - Table Coordinator

/// NSTableView data-source + delegate + bidirectional scroll-sync observer.
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
    weak var gutterView: DiffGutterView?
    weak var tableView:  NSTableView?

    // Track last known first-row ID to avoid expensive reloadData on scroll-only updates
    var lastFirstID: UUID?
    var lastCount = 0
    var maxLineLength: Int = 0

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
        let line = lines[row]
        let id   = NSUserInterfaceItemIdentifier("contentCell")
        let cell = (tableView.makeView(withIdentifier: id, owner: nil) as? NSTextField)
                   ?? makeField(id: id)
        cell.stringValue = line.content
        cell.textColor   = DiffTheme.codeForeground
        return cell
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
        DiffGutterView.rowHeight
    }

    // MARK: Scroll sync

    @objc func boundsDidChange(_ notification: Notification) {
        guard !isSyncing,
              let clip = notification.object as? NSClipView else { return }
        isSyncing = true
        scrollSync.update(offset: clip.bounds.origin, from: side)
        gutterView?.scrollOffsetY = clip.bounds.origin.y
        isSyncing = false
    }

    func updateTableWidth() {
        guard let sv = scrollView, let tv = tableView else { return }
        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        let charWidth = ("M" as NSString).size(withAttributes: [.font: font]).width
        let neededWidth = CGFloat(maxLineLength) * charWidth + 60
        let visibleWidth = sv.contentView.bounds.width
        let finalWidth = max(visibleWidth, neededWidth)

        if let col = tv.tableColumns.first {
            if abs(col.width - finalWidth) > 1.0 {
                col.width    = finalWidth
                col.minWidth = finalWidth
            }
        }
    }

    // MARK: Helper

    private func makeField(id: NSUserInterfaceItemIdentifier) -> NSTextField {
        let f = NSTextField()
        f.identifier      = id
        f.isEditable      = false
        f.isSelectable    = true
        f.isBordered      = false
        f.drawsBackground = false
        f.lineBreakMode   = .byClipping
        f.font            = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        f.textColor       = DiffTheme.codeForeground
        return f
    }
}

// MARK: - DiffScrollView (NSViewRepresentable)

/// Wraps NSScrollView + NSTableView with a pinned gutter for colored, synchronized diff display.
struct DiffScrollView: NSViewRepresentable {
    let lines:         [DiffLine]
    let scrollSync:    ScrollSyncController
    /// Passed explicitly so SwiftUI detects changes and calls updateNSView.
    let syncOffset:    CGPoint
    let side:          FileSide
    let maxLineLength: Int

    func makeCoordinator() -> DiffTableCoordinator {
        DiffTableCoordinator(scrollSync: scrollSync, side: side)
    }

    func makeNSView(context: Context) -> DiffContainerView {
        let coord = context.coordinator
        coord.maxLineLength = maxLineLength

        // ── Table view ────────────────────────────────────────────────
        let tv = NSTableView()
        tv.headerView                 = nil
        tv.intercellSpacing           = .zero
        tv.usesAlternatingRowBackgroundColors = false
        tv.selectionHighlightStyle    = .none
        tv.backgroundColor            = .clear
        tv.rowHeight                  = DiffGutterView.rowHeight
        tv.delegate                   = coord
        tv.dataSource                 = coord
        tv.focusRingType              = .none
        tv.allowsColumnSelection      = false
        tv.columnAutoresizingStyle    = .noColumnAutoresizing
        // Plain style avoids inset row backgrounds that misalign with the gutter.
        tv.style = .plain

        let contentCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("content"))
        contentCol.title        = ""
        contentCol.resizingMask = []
        tv.addTableColumn(contentCol)

        // ── Scroll view ───────────────────────────────────────────────
        let sv = NSScrollView()
        sv.documentView          = tv
        sv.hasVerticalScroller   = true
        sv.hasHorizontalScroller = true
        sv.autohidesScrollers    = true
        sv.borderType            = .noBorder
        sv.drawsBackground       = false
        sv.automaticallyAdjustsContentInsets = false
        sv.contentInsets = .init(top: 0, left: 0, bottom: 0, right: 0)
        sv.scrollerInsets = .init(top: 0, left: 0, bottom: 0, right: 0)

        // ── Pinned gutter ─────────────────────────────────────────────
        let gutter = DiffGutterView(frame: .zero)
        gutter.scrollView = sv
        gutter.tableView = tv

        coord.scrollView = sv
        coord.tableView  = tv
        coord.gutterView = gutter

        // ── Sync wiring ───────────────────────────────────────────────
        sv.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            coord,
            selector: #selector(DiffTableCoordinator.boundsDidChange(_:)),
            name: NSView.boundsDidChangeNotification,
            object: sv.contentView
        )

        return DiffContainerView(gutterView: gutter, scrollView: sv, tableView: tv)
    }

    func updateNSView(_ container: DiffContainerView, context: Context) {
        let coord = context.coordinator
        coord.maxLineLength = maxLineLength
        coord.gutterView?.lines = lines
        coord.gutterView?.scrollOffsetY = container.scrollView.contentView.bounds.origin.y

        let tv = container.tableView
        let sv = container.scrollView

        // Only reload when the diff result changed (detected via first-row ID + count)
        let newFirstID = lines.first?.id
        if newFirstID != coord.lastFirstID || lines.count != coord.lastCount {
            coord.lines       = lines
            coord.lastFirstID = newFirstID
            coord.lastCount   = lines.count
            coord.updateTableWidth()
            tv.reloadData()
        } else {
            coord.updateTableWidth()
        }

        // Apply scroll sync (both X and Y) — but only on the pane that DIDN'T trigger it
        guard !coord.isSyncing,
              scrollSync.lastUpdatedSide != side else { return }

        let target  = syncOffset
        let current = sv.contentView.bounds.origin
        guard abs(target.y - current.y) > 0.5 ||
              abs(target.x - current.x) > 0.5 else { return }

        coord.isSyncing = true
        sv.contentView.scroll(to: target)
        sv.reflectScrolledClipView(sv.contentView)
        coord.gutterView?.scrollOffsetY = target.y
        coord.isSyncing = false
    }
}

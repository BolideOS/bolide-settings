/*
 * SnapListView — Reusable snap-to-center ListView.
 *
 * Provides the Garmin-style UX: items snap to the vertical center,
 * the centered item gets `ListView.isCurrentItem === true`.
 * Delegates should bind their `highlight` to `ListView.isCurrentItem`.
 *
 * Usage:
 *   SnapListView {
 *       model: myModel
 *       itemHeight: Dims.h(17)
 *       delegate: CompactListItem { ... highlight: ListView.isCurrentItem }
 *   }
 */

import QtQuick 2.9
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0

ListView {
    id: snapList

    property int itemHeight: Dims.h(17)

    preferredHighlightBegin: height / 2 - itemHeight / 2
    preferredHighlightEnd: height / 2 + itemHeight / 2
    highlightRangeMode: ListView.StrictlyEnforceRange
    snapMode: ListView.SnapToItem

    boundsBehavior: Flickable.DragOverBounds
    flickableDirection: Flickable.VerticalFlick
    highlight: Item {}
    clip: true
}

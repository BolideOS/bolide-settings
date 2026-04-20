/*
 * CompactListItem — Garmin-style settings menu item.
 *
 * - Smaller tinted icons with vertical separator line
 * - Gradient highlight on selected item
 * - Font weight shifts: 300 (unselected) → 450 (selected)
 */

import QtQuick 2.9
import QtGraphicalEffects 1.0
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import org.bolide.theme 1.0

Item {
    id: root
    property alias title: label.text
    property alias iconName: icon.name
    property bool highlight: false
    property int iconSize: Dims.h(10)
    property int labelFontSize: Dims.l(9)
    property color iconColor: Theme.iconActive
    signal clicked()

    width: parent ? parent.width : 0
    height: Dims.h(17)

    // ========= SEPARATOR STYLE (deepBlue / ember) =========
    // Gradient radiating from separator line toward left edge (icon area)
    LinearGradient {
        id: highlightLeft
        visible: Theme.menuHighlightStyle === "separator"
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: separator.horizontalCenter
        opacity: root.highlight || clickArea.containsPress ? 1.0 : 0.0
        start: Qt.point(width, 0)
        end: Qt.point(0, 0)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.menuHighlightColor }
            GradientStop { position: Theme.menuHighlightHold; color: Theme.menuHighlightColor }
            GradientStop { position: 1.0; color: "transparent" }
        }
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }
    }

    // Gradient radiating from separator line toward right edge (text area)
    LinearGradient {
        id: highlightRight
        visible: Theme.menuHighlightStyle === "separator"
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: separator.horizontalCenter
        anchors.right: parent.right
        opacity: root.highlight || clickArea.containsPress ? 1.0 : 0.0
        start: Qt.point(0, 0)
        end: Qt.point(width, 0)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.menuHighlightColor }
            GradientStop { position: Theme.menuHighlightHold; color: Theme.menuHighlightColor }
            GradientStop { position: 1.0; color: "transparent" }
        }
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }
    }

    // Top border — fades from separator outward
    LinearGradient {
        id: borderTopLeft
        visible: Theme.menuHighlightStyle === "separator"
        height: 1
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: separator.horizontalCenter
        opacity: root.highlight || clickArea.containsPress ? 1.0 : 0.0
        start: Qt.point(width, 0)
        end: Qt.point(0, 0)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.menuBorderColor }
            GradientStop { position: Theme.menuBorderHold; color: Theme.menuBorderColor }
            GradientStop { position: 1.0; color: Qt.rgba(Theme.menuBorderColor.r, Theme.menuBorderColor.g, Theme.menuBorderColor.b, 0) }
        }
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
    LinearGradient {
        id: borderTopRight
        visible: Theme.menuHighlightStyle === "separator"
        height: 1
        anchors.top: parent.top
        anchors.left: separator.horizontalCenter
        anchors.right: parent.right
        opacity: root.highlight || clickArea.containsPress ? 1.0 : 0.0
        start: Qt.point(0, 0)
        end: Qt.point(width, 0)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.menuBorderColor }
            GradientStop { position: Theme.menuBorderHold; color: Theme.menuBorderColor }
            GradientStop { position: 1.0; color: Qt.rgba(Theme.menuBorderColor.r, Theme.menuBorderColor.g, Theme.menuBorderColor.b, 0) }
        }
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    // Bottom border — fades from separator outward
    LinearGradient {
        id: borderBottomLeft
        visible: Theme.menuHighlightStyle === "separator"
        height: 1
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: separator.horizontalCenter
        opacity: root.highlight || clickArea.containsPress ? 1.0 : 0.0
        start: Qt.point(width, 0)
        end: Qt.point(0, 0)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.menuBorderColor }
            GradientStop { position: Theme.menuBorderHold; color: Theme.menuBorderColor }
            GradientStop { position: 1.0; color: Qt.rgba(Theme.menuBorderColor.r, Theme.menuBorderColor.g, Theme.menuBorderColor.b, 0) }
        }
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
    LinearGradient {
        id: borderBottomRight
        visible: Theme.menuHighlightStyle === "separator"
        height: 1
        anchors.bottom: parent.bottom
        anchors.left: separator.horizontalCenter
        anchors.right: parent.right
        opacity: root.highlight || clickArea.containsPress ? 1.0 : 0.0
        start: Qt.point(0, 0)
        end: Qt.point(width, 0)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.menuBorderColor }
            GradientStop { position: Theme.menuBorderHold; color: Theme.menuBorderColor }
            GradientStop { position: 1.0; color: Qt.rgba(Theme.menuBorderColor.r, Theme.menuBorderColor.g, Theme.menuBorderColor.b, 0) }
        }
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    // ========= ROUNDED STYLE (arctic) =========
    // Center-outward radial glow behind the rounded border
    RadialGradient {
        id: roundedGlow
        visible: Theme.menuHighlightStyle === "rounded"
        anchors.fill: parent
        anchors.margins: Dims.w(2)
        horizontalOffset: 0
        verticalOffset: 0
        opacity: root.highlight || clickArea.containsPress ? 1.0 : 0.0
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.menuHighlightColor }
            GradientStop { position: 0.35; color: Theme.menuHighlightColor }
            GradientStop { position: 1.0; color: "transparent" }
        }
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }
    }

    // Rounded pill border around the whole item
    Rectangle {
        id: roundedBorder
        visible: Theme.menuHighlightStyle === "rounded"
        anchors.fill: parent
        anchors.margins: Dims.w(2)
        radius: Theme.menuRoundedRadius
        color: "transparent"
        border.color: Theme.menuRoundedBorderColor
        border.width: Theme.menuRoundedBorderWidth
        opacity: root.highlight || clickArea.containsPress ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        onClicked: root.clicked()
    }

    Icon {
        id: icon
        width: iconSize
        height: width
        visible: false
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: DeviceSpecs.hasRoundScreen ? Dims.w(8) : Dims.w(5)
        }
    }

    ColorOverlay {
        anchors.fill: icon
        source: icon
        color: root.iconColor
    }

    // Vertical separator between icon and label
    // Anchor point — always at the same x position
    Item {
        id: separatorAnchor
        width: 1
        height: parent.height
        anchors {
            verticalCenter: parent.verticalCenter
            left: icon.right
            leftMargin: Dims.w(2)
        }
    }

    Rectangle {
        id: separator
        width: root.highlight ? 3 : 1
        height: parent.height
        color: root.highlight ? Theme.separatorActive : Theme.separatorInactive
        anchors {
            verticalCenter: parent.verticalCenter
            horizontalCenter: separatorAnchor.horizontalCenter
        }
    }

    Label {
        id: label
        renderType: Text.NativeRendering
        color: root.highlight ? Theme.menuSelectedText : Theme.menuUnselectedText
        anchors {
            leftMargin: Dims.w(2)
            left: separatorAnchor.right
            verticalCenter: parent.verticalCenter
        }
        font {
            pixelSize: labelFontSize
            family: Theme.fontFamily
            weight: root.highlight ? Theme.menuSelectedWeight : Theme.menuUnselectedWeight
            letterSpacing: Theme.letterSpacing
        }
    }
}

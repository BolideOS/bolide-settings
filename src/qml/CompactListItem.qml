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

Item {
    id: root
    property alias title: label.text
    property alias iconName: icon.name
    property bool highlight: false
    property int iconSize: Dims.h(10)
    property int labelFontSize: Dims.l(9)
    property color iconColor: "#FFD700"
    signal clicked()

    width: parent.width
    height: Dims.h(17)

    // Gradient radiating from separator line toward left edge (icon area)
    LinearGradient {
        id: highlightLeft
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: separator.horizontalCenter
        opacity: root.highlight || clickArea.containsPress ? 1.0 : 0.0
        start: Qt.point(width, 0)
        end: Qt.point(0, 0)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#CC1785DD" }
            GradientStop { position: 0.3; color: "#CC1785DD" }
            GradientStop { position: 1.0; color: "#00000000" }
        }
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }
    }

    // Gradient radiating from separator line toward right edge (text area)
    LinearGradient {
        id: highlightRight
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: separator.horizontalCenter
        anchors.right: parent.right
        opacity: root.highlight || clickArea.containsPress ? 1.0 : 0.0
        start: Qt.point(0, 0)
        end: Qt.point(width, 0)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#CC1785DD" }
            GradientStop { position: 0.3; color: "#CC1785DD" }
            GradientStop { position: 1.0; color: "#00000000" }
        }
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }
    }

    // Top border — fades from separator outward
    LinearGradient {
        id: borderTopLeft
        height: 1
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: separator.horizontalCenter
        opacity: root.highlight || clickArea.containsPress ? 1.0 : 0.0
        start: Qt.point(width, 0)
        end: Qt.point(0, 0)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#88FFFFFF" }
            GradientStop { position: 0.3; color: "#88FFFFFF" }
            GradientStop { position: 1.0; color: "#00FFFFFF" }
        }
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
    LinearGradient {
        id: borderTopRight
        height: 1
        anchors.top: parent.top
        anchors.left: separator.horizontalCenter
        anchors.right: parent.right
        opacity: root.highlight || clickArea.containsPress ? 1.0 : 0.0
        start: Qt.point(0, 0)
        end: Qt.point(width, 0)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#88FFFFFF" }
            GradientStop { position: 0.3; color: "#88FFFFFF" }
            GradientStop { position: 1.0; color: "#00FFFFFF" }
        }
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    // Bottom border — fades from separator outward
    LinearGradient {
        id: borderBottomLeft
        height: 1
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: separator.horizontalCenter
        opacity: root.highlight || clickArea.containsPress ? 1.0 : 0.0
        start: Qt.point(width, 0)
        end: Qt.point(0, 0)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#88FFFFFF" }
            GradientStop { position: 0.3; color: "#88FFFFFF" }
            GradientStop { position: 1.0; color: "#00FFFFFF" }
        }
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
    LinearGradient {
        id: borderBottomRight
        height: 1
        anchors.bottom: parent.bottom
        anchors.left: separator.horizontalCenter
        anchors.right: parent.right
        opacity: root.highlight || clickArea.containsPress ? 1.0 : 0.0
        start: Qt.point(0, 0)
        end: Qt.point(width, 0)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#88FFFFFF" }
            GradientStop { position: 0.3; color: "#88FFFFFF" }
            GradientStop { position: 1.0; color: "#00FFFFFF" }
        }
        Behavior on opacity { NumberAnimation { duration: 150 } }
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
        color: root.highlight ? "#FFFFFF" : "#DDffffff"
        anchors {
            verticalCenter: parent.verticalCenter
            horizontalCenter: separatorAnchor.horizontalCenter
        }
    }

    Label {
        id: label
        renderType: Text.NativeRendering
        anchors {
            leftMargin: Dims.w(2)
            left: separatorAnchor.right
            verticalCenter: parent.verticalCenter
        }
        font {
            pixelSize: labelFontSize
            family: "Roboto Condensed"
            weight: root.highlight ? 70 : 52
            letterSpacing: -0.5
        }
    }
}

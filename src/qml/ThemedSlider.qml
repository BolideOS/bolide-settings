/*
 * ThemedSlider — A themed wrapper around IntSelector.
 *
 * Adds a primary-color background behind the pill track whose opacity
 * scales with the current value: low value → nearly transparent,
 * high value → richly tinted.
 *
 * Usage:
 *   ThemedSlider {
 *       width: parent.width
 *       height: Dims.h(25)
 *       value: 50
 *       stepSize: 10
 *       onValueChanged: backend.volume = value
 *   }
 */

import QtQuick 2.9
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import org.bolide.theme 1.0

Item {
    id: root

    property int value: 0
    property int min: 0
    property int max: 100
    property int stepSize: 10
    property string unitMarker: "%"
    property bool valueLabelVisible: true
    property int minValue: 10  // optional floor (for brightness)

    // Fraction 0..1 of how "full" the slider is
    readonly property real fraction: max > min ? Math.max(0, Math.min(1, (value - min) / (max - min))) : 0

    // Themed glow behind the track — opacity scales with value
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: Dims.w(15) + Dims.l(1.8)
            rightMargin: Dims.w(15) + Dims.l(1.8)
        }
        height: parent.height * 0.60
        radius: height / 2
        color: Theme.sliderFillColor
        opacity: 0.7 + 0.3 * fraction  // TEMP: bright for debugging
    }

    IntSelector {
        id: selector
        anchors.fill: parent
        min: root.min
        max: root.max
        stepSize: root.stepSize
        unitMarker: root.unitMarker
        valueLabelVisible: root.valueLabelVisible
        value: root.value
        onValueChanged: root.value = value
    }
}

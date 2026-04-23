/*
 * Copyright (C) 2025 Timo Könnecke <github.com/eLtMosen>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.9
import QtGraphicalEffects 1.0
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import org.bolide.theme 1.0
import Nemo.Configuration 1.0
import Nemo.Mce 1.0

Item {
    id: quickPanelPage

    // Battery status components for the ValueMeter
    MceBatteryLevel { id: batteryChargePercentage }
    MceBatteryState { id: batteryChargeState }
    MceChargerType { id: mceChargerType }

    // ConfigurationValue for toggle arrays
    ConfigurationValue {
        id: sliderToggles
        key: "/desktop/bolide/quickpanel/slider"
        defaultValue: [
            "lockButton",
            "settingsButton",
            "brightnessToggle",
            "bluetoothToggle",
            "hapticsToggle",
            "wifiToggle",
            "soundToggle",
            "airplaneModeToggle",
            "aodToggle",
            "powerOffToggle",
            "rebootToggle",
            "cinemaToggle",
            "musicButton",
            "flashlightButton"
        ]
    }

    ConfigurationValue {
        id: toggleEnabled
        key: "/desktop/bolide/quickpanel/enabled"
        defaultValue: {
            "lockButton": true,
            "settingsButton": true,
            "brightnessToggle": true,
            "bluetoothToggle": true,
            "hapticsToggle": true,
            "wifiToggle": true,
            "soundToggle": true,
            "cinemaToggle": false,
            "aodToggle": true,
            "powerOffToggle": true,
            "rebootToggle": true,
            "musicButton": false,
            "flashlightButton": false,
            "airplaneModeToggle": true
        }
    }

    ConfigurationValue {
        id: options
        key: "/desktop/bolide/quickpanel/options"
        defaultValue: {
            "batteryBottom": true,
            "batteryAnimation": true,
            "batteryColored": false,
            "particleDesign": "diamonds"
        }
    }

    // Available toggle options with translatable names and icons
    property var toggleOptions: []

    // Layout properties
    property real rowHeight: Dims.h(18)
    property int draggedItemIndex: -1
    property int targetIndex: -1
    property real dragYOffset: 0
    property var draggedToggle: null
    property var particleDesigns: ["diamonds", "bubbles", "logos", "flashes"]

    Component.onCompleted: {
        populateToggleOptions();
    }

    function populateToggleOptions() {

        //% "Lock Button"
        toggleOptions["lockButton"] = ({ name: qsTrId("id-toggle-lock"), icon: "ios-unlock"});
        //% "Settings"
        toggleOptions["settingsButton"] = ({ name: qsTrId("id-toggle-settings"), icon: "ios-settings"});
        //% "Brightness"
        toggleOptions["brightnessToggle"] = ({name: qsTrId("id-toggle-brightness"), icon: "ios-sunny"});
        //% "Bluetooth"
        toggleOptions["bluetoothToggle"] = ({ name: qsTrId("id-toggle-bluetooth"), icon: "ios-bluetooth"});
        //% "Vibration"
        toggleOptions["hapticsToggle"] = ({ name: qsTrId("id-toggle-haptics"), icon: "ios-watch-vibrating"});
        if (DeviceSpecs.hasWlan) {
            //% "Wifi Toggle"
            toggleOptions["wifiToggle"] = ({ name: qsTrId("id-toggle-wifi"), icon: "ios-wifi-outline"});
        }
        if (DeviceSpecs.hasSpeaker) {
            //% "Mute Sound"
            toggleOptions["soundToggle"] = ({ name: qsTrId("id-toggle-sound"), icon: "ios-sound-indicator-high"});
        }
        //% "Cinema Mode"
        toggleOptions["cinemaToggle"] = ({ name: qsTrId("id-toggle-cinema"), icon: "ios-film-outline"});
        //% "AoD Toggle"
        toggleOptions["aodToggle"] = ({ name: qsTrId("id-always-on-display"), icon: "ios-watch-aod-on"});
        //% "Airplane Mode"
        toggleOptions["airplaneModeToggle"] = ({ name: qsTrId("id-toggle-airplane-mode"), icon: "ios-plane-outline"});
        //% "Poweroff"
        toggleOptions["powerOffToggle"] = ({ name: qsTrId("id-toggle-power-off"), icon: "ios-power-outline"});
        //% "Reboot"
        toggleOptions["rebootToggle"] = ({ name: qsTrId("id-toggle-reboot"), icon: "ios-sync"});
        //% "Music"
        toggleOptions["musicButton"] = ({ name: qsTrId("id-toggle-music"), icon: "ios-musical-notes-outline"});
        //% "Flashlight"
        toggleOptions["flashlightButton"] = ({ name: qsTrId("id-toggle-flashlight"), icon: "ios-bulb-outline"});
    }

    ListModel {
        id: slotModel
        Component.onCompleted: {
            refreshModel();
        }
    }

    // Populate the model with all toggles in a single flat list
    function refreshModel() {
        slotModel.clear();

        const togglesArray = sliderToggles.value;

        //% "Toggles"
        slotModel.append({ type: "label", labelText: qsTrId("id-toggles"), toggleId: "", listView: "" });

        // Add toggles in saved order
        for (let i = 0; i < togglesArray.length; i++) {
            const toggleId = togglesArray[i];
            if (!toggleId) continue;

            const toggle = toggleOptions[toggleId];
            if (!toggle) continue;

            slotModel.append({
                type: "toggle",
                toggleId: toggleId,
                listView: "slider",
                labelText: "",
                toggle: toggle
            });
        }

        // Add any remaining toggles not yet in the list
        for (var key in toggleOptions) {
            if (!toggleOptions.hasOwnProperty(key)) continue;
            if (isToggleInRow(key)) continue;

            const toggle = toggleOptions[key];
            if (!toggle) continue;

            slotModel.append({
                type: "toggle",
                toggleId: key,
                listView: "slider",
                labelText: "",
                toggle: toggle
            });
        }

        //% "Options"
        slotModel.append({ type: "label", labelText: qsTrId("id-options"), toggleId: "", listView: "" });
        //% "Battery Meter aligned to bottom?"
        slotModel.append({ type: "config", labelText: qsTrId("id-battery-bottom"), toggleId: "", listView: "" });
        //% "Enable colored battery?"
        slotModel.append({ type: "config", labelText: qsTrId("id-battery-colored"), toggleId: "", listView: "" });
        //% "Show battery charge animation?"
        slotModel.append({ type: "config", labelText: qsTrId("id-battery-animation"), toggleId: "", listView: "" });
        //% "Tap to cycle particle design"
        slotModel.append({ type: "cycler", labelText: qsTrId("id-particle-design"), toggleId: "", listView: "" });
        //% "Battery preview"
        slotModel.append({ type: "display", labelText: qsTrId("id-battery-preview"), toggleId: "", listView: "" });

        saveConfiguration();
        listLoader.active = true;
    }

    // Check if a toggle is in the list
    function isToggleInRow(toggleId) {
        for (let i = 0; i < slotModel.count; i++) {
            const item = slotModel.get(i);
            if (item.type === "toggle" && item.toggleId === toggleId) {
                return true;
            }
        }
        return false;
    }

    // Find the index of the options label
    function findOptionsLabelIndex() {
        for (let i = 0; i < slotModel.count; i++) {
            const item = slotModel.get(i);
            if (item.type === "label" && item.labelText === qsTrId("id-options")) {
                return i;
            }
        }
        return slotModel.count;
    }

    // Validate drop position for drag-and-drop
    function isValidDropPosition(dropIndex) {
        if (dropIndex < 1) return false;
        const item = slotModel.get(dropIndex);
        if (item.type !== "toggle") return false;
        const optionsIndex = findOptionsLabelIndex();
        if (dropIndex >= optionsIndex) return false;
        return true;
    }

    // Save the current configuration
    function saveConfiguration() {
        let toggleArray = [];

        const optionsIndex = findOptionsLabelIndex();
        for (let i = 1; i < optionsIndex; i++) {
            const item = slotModel.get(i);
            if (item.type === "toggle") {
                toggleArray.push(item.toggleId);
            }
        }

        sliderToggles.value = toggleArray;
    }

    // Handle drag-and-drop movement
    function moveItems() {
        if (draggedItemIndex === -1 || targetIndex === -1 || draggedItemIndex === targetIndex) {
            return;
        }

        const optionsLabelIndex = findOptionsLabelIndex();

        if (targetIndex === 0 || targetIndex >= optionsLabelIndex || !isValidDropPosition(targetIndex)) {
            return;
        }

        dragProxy.text = draggedToggle.name;
        dragProxy.icon = draggedToggle.icon;

        slotModel.move(draggedItemIndex, targetIndex, 1);
        draggedItemIndex = targetIndex;

        saveConfiguration();
        listLoader.item.forceLayout();
    }

    Loader {
        id: listLoader
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        active: false
        sourceComponent: ListView {
            id: slotList
            clip: true
            interactive: draggedItemIndex === -1
            model: slotModel
            cacheBuffer: Dims.h(60)
            maximumFlickVelocity: 1000
            boundsBehavior: Flickable.DragAndOvershootBounds

            Component.onCompleted: {
                forceLayout();
            }

            footer: Item {
                width: parent.width
                height: rowHeight * 1.5
            }

            Timer {
                id: autoScrollTimer
                interval: 16
                repeat: true
                running: draggedItemIndex !== -1 && scrollSpeed !== 0
                property real scrollSpeed: 0
                property real scrollThreshold: height * 0.2

                onTriggered: {
                    if (draggedItemIndex === -1 || Math.abs(scrollSpeed) <= 0.1) {
                        scrollSpeed = 0;
                        return;
                    }

                    const newContentY = contentY + scrollSpeed;
                    contentY = Math.max(0, Math.min(newContentY, contentHeight - height));
                }
            }

            displaced: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }

            add: Transition {
                NumberAnimation {
                    properties: "y,opacity"
                    from: 0
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }

            move: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }

            delegate: Item {
                id: delegateItem
                width: slotList.width
                height: type === "label" ? rowHeight :
                        type === "config" ? Math.max(rowHeight * 2, childrenRect.height) :
                        type === "cycler" ? Math.max(rowHeight * 2, childrenRect.height) :
                        type === "display" ? Math.max(rowHeight * 2, childrenRect.height) :
                        rowHeight
                property int visualIndex: index
                property bool isDragging: index === draggedItemIndex

                // Gradient highlight — left half (icon area)
                LinearGradient {
                    anchors { top: parent.top; bottom: parent.bottom; left: parent.left; right: iconRectangle.right }
                    visible: type === "toggle"
                    z: -1
                    opacity: dragArea.pressed ? 1.0 : 0.0
                    start: Qt.point(width, 0); end: Qt.point(0, 0)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.menuHighlightColor }
                        GradientStop { position: Theme.menuHighlightHold; color: Theme.menuHighlightColor }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                }
                // Gradient highlight — right half (label area)
                LinearGradient {
                    anchors { top: parent.top; bottom: parent.bottom; left: iconRectangle.right; right: parent.right }
                    visible: type === "toggle"
                    z: -1
                    opacity: dragArea.pressed ? 1.0 : 0.0
                    start: Qt.point(0, 0); end: Qt.point(width, 0)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.menuHighlightColor }
                        GradientStop { position: Theme.menuHighlightHold; color: Theme.menuHighlightColor }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                }

                // Top border — fades from icon outward
                LinearGradient {
                    height: 1; anchors { top: parent.top; left: parent.left; right: iconRectangle.right }
                    visible: type === "toggle"; z: 0
                    opacity: dragArea.pressed ? 1.0 : 0.0
                    start: Qt.point(width, 0); end: Qt.point(0, 0)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.menuBorderColor }
                        GradientStop { position: Theme.menuBorderHold; color: Theme.menuBorderColor }
                        GradientStop { position: 1.0; color: Qt.rgba(Theme.menuBorderColor.r, Theme.menuBorderColor.g, Theme.menuBorderColor.b, 0) }
                    }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                LinearGradient {
                    height: 1; anchors { top: parent.top; left: iconRectangle.right; right: parent.right }
                    visible: type === "toggle"; z: 0
                    opacity: dragArea.pressed ? 1.0 : 0.0
                    start: Qt.point(0, 0); end: Qt.point(width, 0)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.menuBorderColor }
                        GradientStop { position: Theme.menuBorderHold; color: Theme.menuBorderColor }
                        GradientStop { position: 1.0; color: Qt.rgba(Theme.menuBorderColor.r, Theme.menuBorderColor.g, Theme.menuBorderColor.b, 0) }
                    }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                // Bottom border — fades from icon outward
                LinearGradient {
                    height: 1; anchors { bottom: parent.bottom; left: parent.left; right: iconRectangle.right }
                    visible: type === "toggle"; z: 0
                    opacity: dragArea.pressed ? 1.0 : 0.0
                    start: Qt.point(width, 0); end: Qt.point(0, 0)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.menuBorderColor }
                        GradientStop { position: Theme.menuBorderHold; color: Theme.menuBorderColor }
                        GradientStop { position: 1.0; color: Qt.rgba(Theme.menuBorderColor.r, Theme.menuBorderColor.g, Theme.menuBorderColor.b, 0) }
                    }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                LinearGradient {
                    height: 1; anchors { bottom: parent.bottom; left: iconRectangle.right; right: parent.right }
                    visible: type === "toggle"; z: 0
                    opacity: dragArea.pressed ? 1.0 : 0.0
                    start: Qt.point(0, 0); end: Qt.point(width, 0)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.menuBorderColor }
                        GradientStop { position: Theme.menuBorderHold; color: Theme.menuBorderColor }
                        GradientStop { position: 1.0; color: Qt.rgba(Theme.menuBorderColor.r, Theme.menuBorderColor.g, Theme.menuBorderColor.b, 0) }
                    }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Label {
                    visible: type === "label"
                    text: labelText
                    color: Theme.textPrimary
                    font.pixelSize: Dims.l(6)
                    font.family: Theme.fontFamily
                    font.italic: true
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        verticalCenter: parent.verticalCenter
                    }
                }

                LabeledSwitch {
                    visible: type === "config"
                    width: delegateItem.width
                    height: Math.max(rowHeight * 2, implicitHeight)
                    text: labelText
                    checked: {
                        if (labelText === qsTrId("id-battery-bottom")) return options.value.batteryBottom;
                        if (labelText === qsTrId("id-battery-animation")) return options.value.batteryAnimation;
                        if (labelText === qsTrId("id-battery-colored")) return options.value.batteryColored;
                        return false;
                    }
                    onCheckedChanged: {
                        const newOptions = Object.assign({}, options.value);
                        if (labelText === qsTrId("id-battery-bottom")) {
                            newOptions.batteryBottom = checked;
                        } else if (labelText === qsTrId("id-battery-animation")) {
                            newOptions.batteryAnimation = checked;
                        } else if (labelText === qsTrId("id-battery-colored")) {
                            newOptions.batteryColored = checked;
                        }
                        options.value = newOptions;
                    }
                }

                OptionCycler {
                    visible: type === "cycler"
                    width: delegateItem.width
                    height: Math.max(rowHeight * 2, implicitHeight)
                    text: qsTrId("id-particle-design")
                    valueArray: particleDesigns
                    currentValue: options.value.particleDesign
                    opacity: options.value.batteryAnimation ? 1.0 : 0.5
                    onValueChanged: {
                        const newOptions = Object.assign({}, options.value);
                        newOptions.particleDesign = value;
                        options.value = newOptions;
                    }
                }

                ValueMeter {
                    id: valueMeter
                    visible: type === "display"
                    width: Dims.l(28) * 1.8
                    height: Dims.l(8)
                    valueLowerBound: 0
                    valueUpperBound: 100
                    value: batteryChargePercentage.percent
                    isIncreasing: mceChargerType.type != MceChargerType.None
                    enableAnimations: options.value.batteryAnimation
                    particleDesign: options.value.particleDesign
                    fillColor: {
                        if (!options.value.batteryColored) return Qt.rgba(1, 1, 1, 0.3)
                        const percent = batteryChargePercentage.percent
                        if (percent > 50) return Qt.rgba(0, 1, 0, 0.3)
                        if (percent > 20) {
                            const t = (50 - percent) / 30
                            return Qt.rgba(t, 1 - (t * 0.35), 0, 0.3)
                        }
                        const t = (20 - percent) / 20
                        return Qt.rgba(1, 0.65 * (1 - t), 0, 0.3)
                    }
                    anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter
                        topMargin: Dims.l(2)
                    }
                }

                Rectangle {
                    width: delegateItem.width
                    height: rowHeight
                    opacity: 0
                    visible: isDragging && type === "toggle"
                }

                Rectangle {
                    id: iconRectangle
                    width: Dims.w(16)
                    height: Dims.w(16)
                    radius: width / 2
                    color: Theme.surfaceDimColor
                    opacity: toggleId ? (toggleEnabled.value[toggleId] ? 0.7 : 0.3) : 0;
                    visible: type === "toggle" && toggleId !== "" && !isDragging
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: Dims.l(14)
                    }
                    Icon {
                        id: toggleIcon
                        name: toggle ? toggle.icon : null
                        width: Dims.w(10)
                        height: Dims.w(10)
                        anchors.centerIn: parent
                        color: Theme.textPrimary
                        opacity: toggleId ? (toggleEnabled.value[toggleId] ? 1.0 : 0.8) : 0;
                        visible: toggleId !== ""
                    }
                }

                Label {
                    text: toggle ? toggle.name : null
                    renderType: Text.NativeRendering
                    color: Theme.textPrimary
                    opacity: toggleId ? (toggleEnabled.value[toggleId] ? 1.0 : 0.6) : 0;
                    visible: type === "toggle" && toggleId !== "" && !isDragging
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: iconRectangle.right
                        leftMargin: Dims.l(4)
                    }
                    font {
                        pixelSize: Dims.l(9)
                        family: Theme.fontFamily
                        weight: Font.Normal
                        letterSpacing: -0.5
                    }
                }

                Timer {
                    id: longPressTimer
                    interval: 500
                    repeat: false
                    property bool dragPending: false

                    onTriggered: {
                        if (!dragPending || type !== "toggle") return;
                        dragPending = false;

                        draggedItemIndex = index;
                        targetIndex = index;
                        draggedToggle = toggle;
                        const itemPos = delegateItem.mapToItem(slotList, 0, 0);
                        dragProxy.x = 0;
                        dragProxy.y = itemPos.y;
                        dragProxy.text = toggle.name;
                        dragProxy.icon = toggle.icon;
                        dragProxy.visible = true;
                        dragYOffset = dragArea.startPos.y;
                    }
                }

                MouseArea {
                    id: dragArea
                    anchors {
                        left: type === "toggle" ? iconRectangle.left : parent.left
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                    }
                    enabled: !isDragging && type === "toggle"
                    property point startPos: Qt.point(0, 0)
                    property real pressStartTime: 0

                    onPressed: {
                        startPos = Qt.point(mouse.x, mouse.y);
                        pressStartTime = new Date().getTime();
                        longPressTimer.dragPending = true;
                        longPressTimer.start();
                    }

                    onPositionChanged: {
                        if (!longPressTimer.running && draggedItemIndex === -1) {
                            if (Math.abs(mouse.x - startPos.x) > 20 || Math.abs(mouse.y - startPos.y) > 20) {
                                longPressTimer.stop();
                            }
                            return;
                        }

                        if (draggedItemIndex === -1) return;

                        const pos = mapToItem(slotList, mouse.x, mouse.y);
                        dragProxy.y = pos.y - dragYOffset;

                        const distFromTop = pos.y;
                        const distFromBottom = slotList.height - pos.y;
                        if (distFromTop < autoScrollTimer.scrollThreshold) {
                            autoScrollTimer.scrollSpeed = -25 * (1 - distFromTop / autoScrollTimer.scrollThreshold);
                        } else if (distFromBottom < autoScrollTimer.scrollThreshold) {
                            autoScrollTimer.scrollSpeed = 25 * (1 - distFromBottom / autoScrollTimer.scrollThreshold);
                        } else {
                            autoScrollTimer.scrollSpeed = 0;
                        }

                        const dropY = pos.y + slotList.contentY;

                        if (dropY < 0) return;

                        const itemUnder = slotList.itemAt(slotList.width / 2, dropY);
                        if (!itemUnder || itemUnder.visualIndex === undefined) return;

                        let dropIndex = itemUnder.visualIndex;
                        const optionsIndex = findOptionsLabelIndex();

                        if (dropIndex >= optionsIndex) {
                            dropIndex = optionsIndex - 1;
                        }

                        if (dropIndex !== draggedItemIndex && isValidDropPosition(dropIndex)) {
                            if (dropIndex !== targetIndex) {
                                targetIndex = dropIndex;
                                moveItems();
                            }
                        }
                    }

                    // Abort drag operation
                    function abortDrag() {
                        if (draggedItemIndex === -1) return;

                        draggedItemIndex = -1;
                        targetIndex = -1;
                        dragProxy.visible = false;
                        autoScrollTimer.scrollSpeed = 0;
                        listLoader.item.forceLayout();
                    }

                    function handleDropReleased(dropY) {
                        if (dropY < 0) {
                            abortDrag();
                            return;
                        }

                        const itemUnder = slotList.itemAt(slotList.width / 2, dropY);
                        if (!itemUnder || itemUnder.visualIndex === undefined) {
                            abortDrag();
                            return;
                        }

                        let dropIndex = itemUnder.visualIndex;
                        const optionsIndex = findOptionsLabelIndex();

                        if (dropIndex >= optionsIndex) {
                            dropIndex = optionsIndex - 1;
                        }

                        if (dropIndex === draggedItemIndex || !isValidDropPosition(dropIndex)) {
                            abortDrag();
                            return;
                        }

                        targetIndex = dropIndex;
                        moveItems();
                    }

                    onReleased: {
                        const pressDuration = new Date().getTime() - pressStartTime;

                        longPressTimer.stop();

                        if (draggedItemIndex !== -1) {
                            const pos = mapToItem(slotList, mouse.x, mouse.y);
                            const dropY = pos.y + slotList.contentY;

                            handleDropReleased(dropY);
                            abortDrag();
                        } else if (type === "toggle" && toggleId && pressDuration < 500) {
                            const newEnabled = Object.assign({}, toggleEnabled.value);
                            // Ensure at least 2 toggles remain enabled
                            const optionsLabelIndex = findOptionsLabelIndex();
                            let activeCount = 0;
                            for (let i = 1; i < optionsLabelIndex; i++) {
                                const item = slotModel.get(i);
                                if (item.type === "toggle" && toggleEnabled.value[item.toggleId]) {
                                    activeCount++;
                                }
                            }
                            if (newEnabled[toggleId] && activeCount <= 2) {
                                return;
                            }
                            newEnabled[toggleId] = !newEnabled[toggleId];
                            toggleEnabled.value = newEnabled;
                        }
                    }

                    onCanceled: {
                        longPressTimer.stop();
                        autoScrollTimer.scrollSpeed = 0;
                        abortDrag();
                    }
                }
            }
        }
    }

    Item {
        id: dragProxy
        visible: false
        z: 10
        width: Dims.w(100)
        height: rowHeight
        property string text: ""
        property string icon: ""

        // Gradient highlight — left half
        LinearGradient {
            anchors { top: parent.top; bottom: parent.bottom; left: parent.left; right: dragIconRect.right }
            start: Qt.point(width, 0); end: Qt.point(0, 0)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.menuHighlightColor }
                GradientStop { position: Theme.menuHighlightHold; color: Theme.menuHighlightColor }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
        // Gradient highlight — right half
        LinearGradient {
            anchors { top: parent.top; bottom: parent.bottom; left: dragIconRect.right; right: parent.right }
            start: Qt.point(0, 0); end: Qt.point(width, 0)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.menuHighlightColor }
                GradientStop { position: Theme.menuHighlightHold; color: Theme.menuHighlightColor }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Top border — drag proxy
        LinearGradient {
            height: 1; anchors { top: parent.top; left: parent.left; right: dragIconRect.right }
            start: Qt.point(width, 0); end: Qt.point(0, 0)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.menuBorderColor }
                GradientStop { position: Theme.menuBorderHold; color: Theme.menuBorderColor }
                GradientStop { position: 1.0; color: Qt.rgba(Theme.menuBorderColor.r, Theme.menuBorderColor.g, Theme.menuBorderColor.b, 0) }
            }
        }
        LinearGradient {
            height: 1; anchors { top: parent.top; left: dragIconRect.right; right: parent.right }
            start: Qt.point(0, 0); end: Qt.point(width, 0)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.menuBorderColor }
                GradientStop { position: Theme.menuBorderHold; color: Theme.menuBorderColor }
                GradientStop { position: 1.0; color: Qt.rgba(Theme.menuBorderColor.r, Theme.menuBorderColor.g, Theme.menuBorderColor.b, 0) }
            }
        }
        // Bottom border — drag proxy
        LinearGradient {
            height: 1; anchors { bottom: parent.bottom; left: parent.left; right: dragIconRect.right }
            start: Qt.point(width, 0); end: Qt.point(0, 0)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.menuBorderColor }
                GradientStop { position: Theme.menuBorderHold; color: Theme.menuBorderColor }
                GradientStop { position: 1.0; color: Qt.rgba(Theme.menuBorderColor.r, Theme.menuBorderColor.g, Theme.menuBorderColor.b, 0) }
            }
        }
        LinearGradient {
            height: 1; anchors { bottom: parent.bottom; left: dragIconRect.right; right: parent.right }
            start: Qt.point(0, 0); end: Qt.point(width, 0)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.menuBorderColor }
                GradientStop { position: Theme.menuBorderHold; color: Theme.menuBorderColor }
                GradientStop { position: 1.0; color: Qt.rgba(Theme.menuBorderColor.r, Theme.menuBorderColor.g, Theme.menuBorderColor.b, 0) }
            }
        }

        Rectangle {
            id: dragIconRect
            width: Dims.w(16)
            height: Dims.w(16)
            radius: width / 2
            color: Theme.surfaceDimColor
            opacity: 0.8
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: Dims.l(14)
            }
            Icon {
                name: dragProxy.icon
                width: Dims.w(10)
                height: Dims.w(10)
                anchors.centerIn: parent
                color: Theme.textPrimary
                visible: dragProxy.icon !== ""
            }
        }

        Label {
            text: dragProxy.text
            renderType: Text.NativeRendering
            color: Theme.textPrimary
            opacity: 0.9
            anchors {
                verticalCenter: parent.verticalCenter
                left: dragIconRect.right
                leftMargin: Dims.l(4)
            }
            font {
                pixelSize: Dims.l(9)
                family: Theme.fontFamily
                weight: Font.Normal
                letterSpacing: -0.5
            }
        }
    }
}

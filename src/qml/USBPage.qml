/*
 * Copyright (C) 2016 - Sylvia van Os <iamsylvie@openmailbox.org>
 * Copyright (C) 2015 - Florent Revest <revestflo@gmail.com>
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
import Nemo.DBus 2.0
import Nemo.Configuration 1.0
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import org.bolide.theme 1.0

Item {
    id: root
    property var pop

    ConfigurationValue {
        id: savedMode
        key: "/org/bolideos/settings/usb-mode"
        defaultValue: "charging_only"
    }

    DBusInterface {
        id: usbmodedDbus
        bus: DBus.SystemBus
        service: "com.meego.usb_moded"
        path: "/com/meego/usb_moded"
        iface: "com.meego.usb_moded"
    }

    function modeToIndex(mode) {
        if (mode === "mtp_mode")       return 3
        if (mode === "developer_mode") return 2
        if (mode === "adb_mode")       return 1
        return 0
    }

    SnapListView {
        id: usbModeList
        anchors.fill: parent

        model: ListModel { id: modesModel }

        delegate: CompactListItem {
            title: model.title
            iconName: model.iconName
            highlight: ListView.isCurrentItem
            onClicked: {
                usbModeList.currentIndex = index
                var mode = modesModel.get(index).mode
                savedMode.value = mode
                usbmodedDbus.call("set_mode", [mode])
                usbmodedDbus.call("set_config", [mode])
                root.pop()
            }
        }

        Component.onCompleted: {
            //% "Charging only"
            modesModel.append({title: qsTrId("id-charging-only"), mode: "charging_only", iconName: "ios-flash-outline"})
            //% "ADB Mode"
            modesModel.append({title: qsTrId("id-adb-mode"), mode: "adb_mode", iconName: "ios-bug-outline"})
            //% "SSH Mode"
            modesModel.append({title: qsTrId("id-ssh-mode"), mode: "developer_mode", iconName: "ios-code-working"})
            //% "MTP Mode"
            modesModel.append({title: qsTrId("id-mtp-mode"), mode: "mtp_mode", iconName: "ios-folder-open"})

            // Try D-Bus first, fall back to saved config
            usbmodedDbus.typedCall('get_config', [], function (mode) {
                var idx = modeToIndex(mode)
                usbModeList.positionViewAtIndex(idx, ListView.Center)
                usbModeList.currentIndex = idx
            }, function () {
                // D-Bus unavailable — use locally saved mode
                var idx = modeToIndex(savedMode.value)
                usbModeList.positionViewAtIndex(idx, ListView.Center)
                usbModeList.currentIndex = idx
            })
        }
    }

    PageTitle {
        //% "USB Mode"
        text: qsTrId("id-usb-mode-page")
    }
}

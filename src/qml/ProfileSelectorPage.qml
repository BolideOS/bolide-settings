/*
 * Copyright (C) 2024 - AsteroidOS Contributors
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
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import Nemo.DBus 2.0

Item {
    id: root

    property string activeProfileId: ""

    ListModel {
        id: profilesModel
    }

    DBusInterface {
        id: powerd
        bus: DBus.SystemBus
        service: "org.bolideos.powerd"
        path: "/org/bolideos/powerd"
        iface: "org.bolideos.powerd.ProfileManager"

        signalsEnabled: true

        function handleError(error) {
            console.log("Profile Selector D-Bus error:", error)
        }

        function loadData() {
            typedCall("GetActiveProfile", [], function(result) {
                activeProfileId = result
            }, handleError)

            typedCall("GetProfiles", [], function(result) {
                var profiles = JSON.parse(result)
                profilesModel.clear()
                for (var i = 0; i < profiles.length; i++) {
                    profilesModel.append(profiles[i])
                }
            }, handleError)
        }

        function activeProfileChanged(newId) {
            activeProfileId = newId
        }

        function profilesChanged() {
            loadData()
        }

        Component.onCompleted: {
            loadData()
        }
    }

    SnapListView {
        id: profileListView
        anchors.fill: parent
        model: profilesModel

        delegate: CompactListItem {
            title: model.name
            iconName: model.icon || "ios-battery-full"
            highlight: ListView.isCurrentItem

            onClicked: {
                powerd.typedCall("SetActiveProfile",
                    [{"type": "s", "value": model.id}],
                    function(success) {
                        if (success) {
                            activeProfileId = model.id
                            layerStack.pop(root)
                        }
                    }, powerd.handleError)
            }
        }

        Item {
            id: emptyState
            anchors.centerIn: parent
            width: parent.width * 0.8
            visible: profilesModel.count === 0

            Column {
                anchors.centerIn: parent
                spacing: Dims.h(3)
                width: parent.width

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    //% "No profiles available"
                    text: qsTrId("id-no-profiles")
                    font.pixelSize: Dims.l(6)
                    font.family: "Roboto Condensed"
                    wrapMode: Text.WordWrap
                }

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    //% "Service may be unavailable"
                    text: qsTrId("id-service-may-be-unavailable")
                    font.pixelSize: Dims.l(4)
                    font.family: "Roboto Condensed"
                    opacity: 0.6
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    PageHeader {
        //% "Select Profile"
        text: qsTrId("id-select-profile")
    }
}

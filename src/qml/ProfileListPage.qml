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
import org.bolide.theme 1.0
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
            console.log("Profile List D-Bus error:", error)
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

    Component {
        id: profileEditLayer
        ProfileEditPage {}
    }

    SnapListView {
        id: profileListView
        anchors.fill: parent
        model: profilesModel

        delegate: CompactListItem {
            title: model.name
            iconName: model.icon || "ios-battery-full"
            highlight: ListView.isCurrentItem

            property bool isBuiltin: model.builtin === true

            onClicked: {
                profileListView.currentIndex = index
                layerStack.push(profileEditLayer, {profileId: model.id})
            }

            MouseArea {
                anchors.fill: parent
                onPressAndHold: {
                    if (!parent.isBuiltin) {
                        deleteRemorse.execute(parent, "", function() {
                            powerd.typedCall("DeleteProfile",
                                [{"type": "s", "value": model.id}],
                                function(success) {
                                    if (success) {
                                        powerd.loadData()
                                    }
                                }, powerd.handleError)
                        })
                    }
                }
                onClicked: parent.clicked()
            }

            RemorseTimer {
                id: deleteRemorse
            }
        }

        footer: CompactListItem {
            //% "Add New Profile"
            title: qsTrId("id-add-new-profile")
            iconName: "ios-add-circle-outline"
            highlight: false

            onClicked: {
                layerStack.push(profileEditLayer, {profileId: "", isNewProfile: true})
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
                    font.family: Theme.fontFamily
                    wrapMode: Text.WordWrap
                }

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    //% "Service may be unavailable"
                    text: qsTrId("id-service-may-be-unavailable")
                    font.pixelSize: Dims.l(4)
                    font.family: Theme.fontFamily
                    opacity: 0.6
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    PageTitle {
        //% "Profiles"
        text: qsTrId("id-profiles")
    }
}

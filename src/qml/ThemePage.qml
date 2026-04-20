/*
 * ThemePage.qml — Theme selector for BolideOS Settings.
 */

import QtQuick 2.9
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import org.bolide.theme 1.0
import Nemo.Configuration 1.0

Item {
    id: root

    ConfigurationValue {
        id: themeConfig
        key: "/org/bolideos/settings/theme"
        defaultValue: "deepBlue"
    }

    SnapListView {
        id: themeList
        anchors.fill: parent
        model: Theme.themeNames

        delegate: CompactListItem {
            title: Theme.themeLabel(modelData)
            iconName: "ios-color-palette-outline"
            highlight: ListView.isCurrentItem
            onClicked: {
                themeList.currentIndex = index
                Theme.loadTheme(modelData)
                themeConfig.value = modelData
            }
        }

        Component.onCompleted: {
            var saved = themeConfig.value
            var idx = -1
            for (var i = 0; i < Theme.themeNames.length; i++) {
                if (Theme.themeNames[i] === saved) { idx = i; break }
            }
            if (idx >= 0) {
                positionViewAtIndex(idx, ListView.Center)
                currentIndex = idx
            }
        }
    }
}

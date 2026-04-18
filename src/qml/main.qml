/*
 * Copyright (C) 2023 - Timo Könnecke <github.com/eLtMosen>
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
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import org.bolide.settings 1.0
import Nemo.Configuration 1.0

Application {
    id: app

    centerColor: "#0044A6"
    outerColor: "#00010C"

    ConfigurationValue {
        id: options
        key: "/desktop/bolide/quickpanel/options"
        defaultValue: {
            "batteryBottom": true,
            "batteryAnimation": true,
            "batteryColored": false
        }
    }

    Component { id: quickPanelLayer;         QuickPanelPage { } }
    Component { id: timeLayer;                  TimePage       { } }
    Component { id: dateLayer;                  DatePage       { } }
    Component { id: timezoneLayer;              TimezonePage   { } }
    Component { id: languageLayer;              LanguagePage   { } }
    Component { id: bluetoothLayer;             BluetoothPage  { } }
    Component { id: displayLayer;               DisplayPage    { } }
    Component { id: soundLayer;                 SoundPage      { } }
    Component { id: nightstandLayer;            NightstandPage { } }
    Component { id: nightstandWatchfaceLayer;   NightstandWatchfacePage { } }
    Component { id: unitsLayer;                 UnitsPage      { } }
    Component { id: wallpaperLayer;             WallpaperPage  { } }
    Component { id: watchfaceLayer;             WatchfacePage  { } }
    Component { id: launcherLayer;              LauncherPage   { } }
    Component { id: usbLayer;                   USBPage        { } }
    Component { id: powerLayer;                 PowerPage      { } }
    Component { id: powerManagerLayer;          PowerManagerPage { } }
    Component { id: aboutLayer;                 AboutPage      { } }

    TiltToWake { id: tiltToWake }

    LayerStack {
        id: layerStack

        firstPage: firstPageComponent
    }

    Component {
        id: firstPageComponent

        SnapListView {
            id: settingsList

            model: ListModel { id: menuModel }

            delegate: CompactListItem {
                title: model.title
                iconName: model.pageKey === "quickpanel"
                    ? (options.value.batteryBottom ? "ios-quickpanel-batterybottom" : "ios-quickpanel-batterytop")
                    : model.iconName
                highlight: ListView.isCurrentItem
                onClicked: {
                    settingsList.currentIndex = index
                    settingsList.openPage(model.pageKey)
                }
            }

            Component.onCompleted: {
                //% "Display"
                menuModel.append({title: qsTrId("id-display-page"), iconName: "ios-display-outline", pageKey: "display"})
                //% "Nightstand"
                menuModel.append({title: qsTrId("id-nightstand-page"), iconName: "ios-moon-outline", pageKey: "nightstand"})
                //% "Quick Panel"
                menuModel.append({title: qsTrId("id-quickpanel-page"), iconName: "ios-quickpanel-batterybottom", pageKey: "quickpanel"})
                if (DeviceSpecs.hasSpeaker) {
                    //% "Sound"
                    menuModel.append({title: qsTrId("id-sound-page"), iconName: "ios-sound-outline", pageKey: "sound"})
                }
                //% "Wallpaper"
                menuModel.append({title: qsTrId("id-wallpaper-page"), iconName: "ios-wallpaper-outline", pageKey: "wallpaper"})
                //% "Watchface"
                menuModel.append({title: qsTrId("id-watchface-page"), iconName: "ios-watchface-outline", pageKey: "watchface"})
                //% "Launcher"
                menuModel.append({title: qsTrId("id-launcher-page"), iconName: "ios-launcher-outline", pageKey: "launcher"})
                //% "Time"
                menuModel.append({title: qsTrId("id-time-page"), iconName: "ios-clock-outline", pageKey: "time"})
                //% "Date"
                menuModel.append({title: qsTrId("id-date-page"), iconName: "ios-date-outline", pageKey: "date"})
                //% "Units"
                menuModel.append({title: qsTrId("id-units-page"), iconName: "ios-units-outline", pageKey: "units"})
                //% "Language"
                menuModel.append({title: qsTrId("id-language-page"), iconName: "ios-earth-outline", pageKey: "language"})
                //% "Time zone"
                menuModel.append({title: qsTrId("id-timezone-page"), iconName: "ios-globe-outline", pageKey: "timezone"})
                //% "Bluetooth"
                menuModel.append({title: qsTrId("id-bluetooth-page"), iconName: "ios-bluetooth-outline", pageKey: "bluetooth"})
                //% "USB"
                menuModel.append({title: qsTrId("id-usb-page"), iconName: "ios-usb", pageKey: "usb"})
                //% "Power"
                menuModel.append({title: qsTrId("id-power-page"), iconName: "ios-power-outline", pageKey: "power"})
                //% "Power Manager"
                menuModel.append({title: qsTrId("id-power-manager-page"), iconName: "ios-battery-full", pageKey: "powermanager"})
                //% "About"
                menuModel.append({title: qsTrId("id-about-page"), iconName: "ios-help-circle-outline", pageKey: "about"})
            }

            function openPage(key) {
                var pages = {
                    "display": displayLayer,
                    "nightstand": nightstandLayer,
                    "quickpanel": quickPanelLayer,
                    "sound": soundLayer,
                    "wallpaper": wallpaperLayer,
                    "watchface": watchfaceLayer,
                    "launcher": launcherLayer,
                    "time": timeLayer,
                    "date": dateLayer,
                    "units": unitsLayer,
                    "language": languageLayer,
                    "timezone": timezoneLayer,
                    "bluetooth": bluetoothLayer,
                    "usb": usbLayer,
                    "power": powerLayer,
                    "powermanager": powerManagerLayer,
                    "about": aboutLayer
                }
                if (pages[key]) layerStack.push(pages[key])
            }
        }
    }
    function backToMainMenu() {
        while (layerStack.layers.length > 0) {
            layerStack.pop(layerStack.currentLayer)
        }
    }
}

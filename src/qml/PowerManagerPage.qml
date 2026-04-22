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
import QtGraphicalEffects 1.0
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import org.bolide.theme 1.0
import Nemo.DBus 2.0

Item {
    id: root

    property string activeProfileId: ""
    property string activeProfileName: ""
    property string activeProfileIcon: "ios-battery-full"
    property real profilePowerScore: 0.0   // 0.0 (eco) → 1.0 (max drain)
    property int batteryLevel: 0
    property bool batteryCharging: false
    property string drainRate: ""
    property real drainRatePerHour: 0
    property var batteryHistory: []
    property bool serviceAvailable: false
    property bool isEmulator: false
    property int menuFocus: 0

    // Battery health properties
    property int healthPercent: -1
    property int learnedCapacityMah: -1
    property int designCapacityMah: -1
    property int cycleCount: 0
    property string healthConfidence: "unavailable"
    property int healthSampleCount: 0

    // Estimate drain rate (%/hr) from profile power score when no observed data.
    // score 0.0 (max_battery) → ~0.4%/hr (~10 days)
    // score 0.5 (smartwatch)  → ~2.5%/hr (~40 hrs)
    // score 1.0 (performance) → ~8%/hr   (~12 hrs)
    // Uses exponential curve: rate = 0.4 * exp(3.0 * score)
    function estimatedDrainRate() {
        if (drainRatePerHour > 0) return drainRatePerHour
        return 0.4 * Math.exp(3.0 * profilePowerScore)
    }

    property bool usingEstimate: drainRatePerHour <= 0 && !batteryCharging

    // Compute 0–1 power score from profile sensors + radios + system flags.
    // Higher values = more power consumption = warmer card color.
    //
    // Color zones by design intent:
    //   GREEN  (0.0–0.3) — sensors only, all radios off
    //   YELLOW (0.3–0.6) — BLE on (any mode)
    //   RED    (0.6–1.0) — GPS or WiFi on
    function computePowerScore(profile) {
        var score = 0

        // --- Big-ticket radios: these define the color zone ---
        if (profile.radios) {
            var r = profile.radios
            // GPS sensor on → instant red territory
            if (profile.sensors && profile.sensors.gps && profile.sensors.gps !== "off")
                score += 0.35   // pushes into 0.6+ red zone
            // WiFi on → red territory
            if (r.wifi && r.wifi.state === "on")
                score += 0.30   // pushes into 0.6+ red zone
            // BLE on → yellow territory
            if (r.ble && r.ble.state === "on")
                score += 0.20   // pushes into 0.3+ yellow zone
            // LTE on → heavy
            if (r.lte && r.lte.state === "always")
                score += 0.25
            else if (r.lte && r.lte.state === "calls_only")
                score += 0.10
            // NFC on → minor
            if (r.nfc && r.nfc.state === "on")
                score += 0.03
        }

        // --- Sensors (contribute up to ~0.30 total) ---
        if (profile.sensors) {
            var sensors = profile.sensors
            var sensorWeights = {
                "heart_rate":    0.06,
                "spo2":          0.05,
                "gyroscope":     0.04,
                "accelerometer": 0.03,
                "compass":       0.03,
                "barometer":     0.02,
                "ambient_light": 0.02,
                "hrv":           0.03
            }
            // GPS already counted above in radios section
            var modeFrac = {
                "off": 0.0,
                "low": 0.25, "sleep_only": 0.25, "periodic": 0.35, "on_demand": 0.25,
                "medium": 0.50,
                "high": 0.75, "always": 0.75, "continuous": 1.0,
                "workout": 1.0
            }
            for (var sName in sensorWeights) {
                if (sensors[sName] !== undefined) {
                    var frac = modeFrac[sensors[sName]]
                    score += sensorWeights[sName] * (frac !== undefined ? frac : 0)
                }
            }
        }

        // --- System flags (contribute up to ~0.10) ---
        if (profile.system) {
            if (profile.system.always_on_display) score += 0.06
            if (profile.system.tilt_to_wake) score += 0.02
        }

        // --- CPU (contribute up to ~0.10) ---
        if (profile.cpu) {
            var govScores = { "powersave": 0.0, "auto": 0.03, "schedutil": 0.03,
                              "ondemand": 0.05, "performance": 0.08 }
            if (govScores[profile.cpu.governor] !== undefined)
                score += govScores[profile.cpu.governor]
            // More cores = more power
            if (profile.cpu.max_cores <= 0) score += 0.02 // all cores
        }

        // --- Processes (contribute up to ~0.05) ---
        if (profile.processes) {
            if (profile.processes.audio_enabled) score += 0.02
            if (profile.processes.pulseaudio !== "stopped") score += 0.02
        }

        return Math.min(score, 1.0)
    }

    // Map power score (0→1) to a Theme graded color: green → yellow → red
    function powerScoreColor(t) {
        var lo  = Theme.gradeLow
        var mid = Theme.gradeMid
        var hi  = Theme.gradeHigh
        var r, g, b
        if (t <= 0.5) {
            var f = t / 0.5
            r = lo.r + f * (mid.r - lo.r)
            g = lo.g + f * (mid.g - lo.g)
            b = lo.b + f * (mid.b - lo.b)
        } else {
            var f2 = (t - 0.5) / 0.5
            r = mid.r + f2 * (hi.r - mid.r)
            g = mid.g + f2 * (hi.g - mid.g)
            b = mid.b + f2 * (hi.b - mid.b)
        }
        return Qt.rgba(r, g, b, 1.0)
    }

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
            console.log("Power Manager D-Bus error:", error)
            serviceAvailable = false
        }

        function loadProfiles() {
            typedCall("GetProfiles", [], function(result) {
                serviceAvailable = true
                var profiles = JSON.parse(result)
                profilesModel.clear()
                for (var i = 0; i < profiles.length; i++) {
                    profilesModel.append(profiles[i])
                }
            }, handleError)
        }

        function loadActiveProfile() {
            typedCall("GetActiveProfile", [], function(result) {
                serviceAvailable = true
                activeProfileId = result
                console.log("PowerManager: activeProfileId = " + activeProfileId)

                typedCall("GetProfile", [{"type": "s", "value": activeProfileId}], function(profileJson) {
                    var profile = JSON.parse(profileJson)
                    activeProfileName = profile.name
                    activeProfileIcon = profile.icon || "ios-battery-full"
                    profilePowerScore = computePowerScore(profile)
                    console.log("PowerScore: " + profilePowerScore.toFixed(3) +
                                " color: " + powerScoreColor(profilePowerScore) +
                                " opacity: " + Theme.cardGradientOpacity)
                }, function(err) {
                    console.log("PowerManager: GetProfile failed: " + err)
                })
            }, function(err) {
                console.log("PowerManager: GetActiveProfile failed: " + err)
            })
        }

        function loadBatteryState() {
            typedCall("GetCurrentState", [], function(result) {
                var state = JSON.parse(result)
                if (state.battery) {
                    batteryLevel = state.battery.level || 0
                    batteryCharging = state.battery.charging || false
                    // Health data included in current state
                    if (state.battery.health_percent !== undefined) {
                        healthPercent = state.battery.health_percent
                    }
                    if (state.battery.learned_capacity_mah !== undefined) {
                        learnedCapacityMah = state.battery.learned_capacity_mah
                    }
                    if (state.battery.design_capacity_mah !== undefined) {
                        designCapacityMah = state.battery.design_capacity_mah
                    }
                    if (state.battery.cycle_count !== undefined) {
                        cycleCount = state.battery.cycle_count
                    }
                    if (state.battery.health_confidence !== undefined) {
                        healthConfidence = state.battery.health_confidence
                    }
                }
            }, handleError)
            
            typedCall("GetBatteryPrediction", [], function(result) {
                var prediction = JSON.parse(result)
                if (prediction.drain_rate_percent_per_hour) {
                    drainRatePerHour = prediction.drain_rate_percent_per_hour
                    drainRate = drainRatePerHour.toFixed(1) + "%/h"
                } else {
                    drainRatePerHour = 0
                    drainRate = ""
                }
            }, handleError)
        }

        function loadBatteryHealth() {
            typedCall("GetBatteryHealth", [], function(result) {
                var health = JSON.parse(result)
                if (health.health_percent !== undefined)
                    healthPercent = health.health_percent
                if (health.learned_capacity_mah !== undefined)
                    learnedCapacityMah = health.learned_capacity_mah
                if (health.design_capacity_mah !== undefined)
                    designCapacityMah = health.design_capacity_mah
                if (health.cycle_count !== undefined)
                    cycleCount = health.cycle_count
                if (health.confidence !== undefined)
                    healthConfidence = health.confidence
                if (health.sample_count !== undefined)
                    healthSampleCount = health.sample_count

                // On emulator with no real fuel gauge, generate demo data
                if (isEmulator && healthPercent <= 0) {
                    healthPercent = 87
                    learnedCapacityMah = 361
                    designCapacityMah = 415
                    cycleCount = 142
                    healthConfidence = "high"
                    healthSampleCount = 45
                }
            }, function() {
                if (isEmulator) {
                    healthPercent = 87
                    learnedCapacityMah = 361
                    designCapacityMah = 415
                    cycleCount = 142
                    healthConfidence = "high"
                    healthSampleCount = 45
                }
            })
        }

        function loadBatteryHistory() {
            typedCall("GetBatteryHistory",
                [{"type": "i", "value": 168}],
                function(result) {
                    var data = JSON.parse(result)
                    if (data.length > 0) {
                        batteryHistory = data
                    } else if (isEmulator) {
                        batteryHistory = generateSimulatedHistory()
                    }
                }, function() {
                    if (isEmulator) {
                        batteryHistory = generateSimulatedHistory()
                    }
                })
        }

        function activeProfileChanged(newId) {
            activeProfileId = newId
            loadActiveProfile()
        }

        function profilesChanged() {
            loadProfiles()
        }

        function batteryLevelChanged(newLevel, isCharging) {
            batteryLevel = newLevel
            batteryCharging = isCharging
            loadBatteryState()
            loadBatteryHistory()
        }

        function batteryHealthChanged(newHealth, newLearned, newDesign) {
            healthPercent = newHealth
            learnedCapacityMah = newLearned
            designCapacityMah = newDesign
            loadBatteryHealth()
        }

        Component.onCompleted: {
            detectEmulator()
            loadProfiles()
            loadActiveProfile()
            loadBatteryState()
            loadBatteryHistory()
            loadBatteryHealth()
        }
    }

    // Detect emulator by reading /etc/hostname (set to "emulator" in QEMU builds,
    // real watches have device codenames like "catfish", "beluga", "sturgeon", etc.)
    function detectEmulator() {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                var hostname = (xhr.responseText || "").trim()
                isEmulator = (hostname === "emulator")
                if (isEmulator) {
                    console.log("PowerManager: Running on emulator — simulation data available")
                    // Re-try history now that we know we're on emulator
                    if (batteryHistory.length === 0) {
                        powerd.loadBatteryHistory()
                    }
                    // Load demo health data on emulator
                    if (healthPercent <= 0) {
                        powerd.loadBatteryHealth()
                    }
                }
            }
        }
        xhr.open("GET", "file:///etc/hostname")
        xhr.send()
    }

    // Generate realistic 7-day simulated battery data for graph preview.
    // ONLY called when isEmulator is true (QEMU build) — never on real hardware.
    // Points every 2 hours matching daemon heartbeat interval.
    // Pattern: ~2 days drain → 2h charge → ~3 days drain → 2h charge → drain to now
    function generateSimulatedHistory() {
        if (!isEmulator) return []

        var now = Math.floor(Date.now() / 1000)
        var data = []
        var t = now - 7 * 24 * 3600
        var level = 100
        var STEP = 7200          // 2 hours
        var HOUR = 3600

        // Helper: drain rate per 2h step (base %/h * 2 + tiny noise)
        function drainStep(basePerHour) {
            return (basePerHour + (Math.random() - 0.5) * 0.3) * 2
        }
        // Helper: charge rate per 2h step
        function chargeStep(basePerHour) {
            return (basePerHour + (Math.random() - 0.5) * 2) * 2
        }

        // Phase 1: Drain ~2 days (48h) at ~2%/h
        var phase1End = t + 48 * HOUR
        while (t < phase1End && t < now) {
            data.push({timestamp: t, level: Math.round(level * 10) / 10, charging: false, profile: "balanced"})
            level -= drainStep(2.0)
            level = Math.max(0, level)
            t += STEP
        }

        // Phase 2: Charge ~2h at ~40%/h (fast charge)
        var phase2End = t + 2 * HOUR
        while (t < phase2End && t < now) {
            data.push({timestamp: t, level: Math.round(level * 10) / 10, charging: true, profile: "balanced"})
            level += chargeStep(40)
            level = Math.min(100, level)
            t += STEP
        }

        // Phase 3: Drain ~3 days (72h) at ~1.4%/h (power saver)
        var phase3End = t + 72 * HOUR
        while (t < phase3End && t < now) {
            data.push({timestamp: t, level: Math.round(level * 10) / 10, charging: false, profile: "power_saver"})
            level -= drainStep(1.4)
            level = Math.max(0, level)
            t += STEP
        }

        // Phase 4: If battery low, charge 2h then drain remaining time
        if (t < now && level < 25) {
            var phase4End = t + 2 * HOUR
            while (t < phase4End && t < now) {
                data.push({timestamp: t, level: Math.round(level * 10) / 10, charging: true, profile: "balanced"})
                level += chargeStep(38)
                level = Math.min(100, level)
                t += STEP
            }
        }
        while (t < now) {
            data.push({timestamp: t, level: Math.round(level * 10) / 10, charging: false, profile: "balanced"})
            level -= drainStep(1.8)
            level = Math.max(0, level)
            t += STEP
        }

        // Final point at now
        var finalLevel = batteryLevel > 0 ? batteryLevel : 61
        data.push({timestamp: now, level: finalLevel, charging: false, profile: "balanced"})
        return data
    }

    Component {
        id: profileSelectorLayer
        ProfileSelectorPage {}
    }

    Component {
        id: profileListLayer
        ProfileListPage {}
    }

    Flickable {
        id: contentFlickable
        anchors.fill: parent
        anchors.bottomMargin: Dims.h(3)
        contentHeight: contentColumn.implicitHeight
        clip: true

        Column {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Dims.h(2)

            Item {
                width: parent.width
                height: Dims.h(23)
            }

            MouseArea {
                width: parent.width
                height: profileCard.height

                onClicked: layerStack.push(profileSelectorLayer)

                Rectangle {
                    id: profileCard
                    width: parent.width - Dims.w(4)
                    height: profileCardColumn.height + Dims.h(3)
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 4
                    color: "transparent"
                    border.color: Theme.graphBorderColor
                    border.width: 1

                    // Dynamic gradient: green (eco) → yellow → red (power-hungry)
                    LinearGradient {
                        id: powerGradientBg
                        anchors.fill: parent
                        anchors.margins: 1
                        start: Qt.point(0, 0)
                        end: Qt.point(0, height)
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(
                                powerScoreColor(profilePowerScore).r,
                                powerScoreColor(profilePowerScore).g,
                                powerScoreColor(profilePowerScore).b,
                                Theme.cardGradientOpacity) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    Column {
                        id: profileCardColumn
                        width: parent.width
                        anchors.centerIn: parent
                        spacing: Dims.h(1)

                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        //% "Active Profile"
                        text: qsTrId("id-active-profile")
                        font.pixelSize: Dims.l(6)
                        font.family: Theme.fontFamily
                        opacity: 0.6
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Dims.w(3)

                        Icon {
                            name: activeProfileIcon
                            width: Dims.l(8)
                            height: width
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: serviceAvailable ? 1.0 : 0.3
                        }

                        Label {
                            text: serviceAvailable ? activeProfileName :
                                  //% "Service unavailable"
                                  qsTrId("id-service-unavailable")
                            font.pixelSize: Dims.l(5)
                            font.family: Theme.fontFamily
                            wrapMode: Text.WordWrap
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: serviceAvailable ? 1.0 : 0.6
                        }
                    }
                    }
                }
            }

            Item {
                width: parent.width
                height: Dims.h(3)
            }

            CompactListItem {
                //% "Edit Profiles"
                title: qsTrId("id-edit-profiles")
                iconName: "ios-settings-outline"
                highlight: menuFocus === 0
                onClicked: {
                    menuFocus = 0
                    layerStack.push(profileListLayer)
                }
            }

            CompactListItem {
                //% "Automation"
                title: qsTrId("id-automation")
                iconName: "ios-timer-outline"
                highlight: menuFocus === 1
                enabled: false
                opacity: 0.5
            }

            // --- Battery Estimate ---
            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: {
                    if (batteryCharging)
                        //% "Charging"
                        return "⚡ " + qsTrId("id-charging")
                    var rate = estimatedDrainRate()
                    if (rate <= 0 || batteryLevel <= 0)
                        //% "Estimating…"
                        return qsTrId("id-estimating")
                    var hoursLeft = batteryLevel / rate
                    var prefix = usingEstimate ? "~" : "~"
                    if (hoursLeft >= 48) {
                        var days = Math.round(hoursLeft / 24 * 10) / 10
                        //% "~%1 days remaining"
                        return qsTrId("id-days-remaining").arg(days)
                    }
                    var hrs = Math.floor(hoursLeft)
                    var mins = Math.round((hoursLeft - hrs) * 60)
                    //% "~%1h %2m remaining"
                    return qsTrId("id-hours-remaining").arg(hrs).arg(mins)
                }
                font.pixelSize: Dims.l(7)
                font.family: Theme.fontFamily
                font.weight: Font.DemiBold
                color: {
                    if (batteryCharging) return Theme.healthGood
                    var rate = estimatedDrainRate()
                    if (rate <= 0) return Theme.textSecondary
                    var hoursLeft = batteryLevel / rate
                    if (hoursLeft >= 48) return Theme.healthGood
                    if (hoursLeft >= 24) return Theme.healthOk
                    return Theme.healthWarn
                }
                visible: serviceAvailable
            }

            // Show basis of estimate
            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: usingEstimate
                      //% "Based on %1 profile"
                      ? qsTrId("id-estimate-based-profile").arg(activeProfileName)
                      //% "Based on observed usage"
                      : qsTrId("id-estimate-based-observed")
                font.pixelSize: Dims.l(5)
                font.family: Theme.fontFamily
                opacity: 0.7
                visible: serviceAvailable && !batteryCharging
            }

            Item {
                width: parent.width
                height: Dims.h(45)

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: Dims.w(2)
                    anchors.rightMargin: Dims.w(2)
                    radius: 4
                    color: "transparent"
                    border.color: Theme.graphBorderColor
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 1

                        Label {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            //% "Battery Charge"
                            text: qsTrId("id-battery-charge")
                            font.pixelSize: Dims.l(6)
                            font.family: Theme.fontFamily
                            font.weight: Font.DemiBold
                            color: Theme.textAccent
                            topPadding: Dims.h(0.5)
                            bottomPadding: Dims.h(0.5)
                        }

                        BatteryHistoryGraph {
                            width: parent.width
                            height: parent.height - y
                            historyData: batteryHistory
                            currentLevel: batteryLevel
                            drainRatePerHour: root.drainRatePerHour
                            isCharging: batteryCharging
                        }
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Dims.w(3)

                Label {
                    text: batteryLevel + "%"
                    font.pixelSize: Dims.l(9)
                    font.family: Theme.fontFamily
                    font.weight: Font.Normal
                    anchors.verticalCenter: parent.verticalCenter
                }

                Label {
                    text: drainRate
                    font.pixelSize: Dims.l(6)
                    font.family: Theme.fontFamily
                    opacity: 0.6
                    anchors.verticalCenter: parent.verticalCenter
                    visible: drainRate !== "" && !batteryCharging
                }

                Label {
                    text: batteryCharging ? "⚡" : ""
                    font.pixelSize: Dims.l(5)
                    font.family: Theme.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                    visible: batteryCharging
                }
            }

            // --- Battery Health Section ---
            Item {
                width: parent.width
                height: Dims.h(3)
                visible: healthPercent > 0 || isEmulator
            }

            RowSeparator {
                visible: healthPercent > 0 || isEmulator
            }

            Column {
                id: healthSection
                width: parent.width
                spacing: Dims.h(1)
                visible: healthPercent > 0 || isEmulator

                Item { width: 1; height: Dims.h(1) }

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    //% "Battery Health"
                    text: qsTrId("id-battery-health")
                    font.pixelSize: Dims.l(8)
                    font.family: Theme.fontFamily
                }

                // Health bar
                Item {
                    width: parent.width
                    height: Dims.h(5)

                    Rectangle {
                        id: healthBarTrack
                        anchors.centerIn: parent
                        width: parent.width * 0.70
                        height: Dims.h(1.5)
                        radius: height / 2
                        color: Theme.surfaceColor

                        Rectangle {
                            id: healthBarFill
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * Math.max(0, Math.min(1, healthPercent / 100.0))
                            radius: parent.radius
                            color: healthPercent >= 80 ? Theme.healthGood :
                                   healthPercent >= 60 ? Theme.healthOk :
                                   healthPercent >= 40 ? Theme.healthWarn : Theme.healthBad

                            Behavior on width {
                                NumberAnimation { duration: 400; easing.type: Easing.OutQuad }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 300 }
                            }
                        }
                    }
                }

                // Health percentage + capacity
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Dims.w(2)

                    Label {
                        text: healthPercent > 0 ? healthPercent + "%" : "--"
                        font.pixelSize: Dims.l(12)
                        font.family: Theme.fontFamily
                        font.weight: Font.Normal
                        color: healthPercent >= 80 ? Theme.healthGood :
                               healthPercent >= 60 ? Theme.healthOk :
                               healthPercent >= 40 ? Theme.healthWarn : Theme.healthBad
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Label {
                            text: {
                                if (learnedCapacityMah > 0 && designCapacityMah > 0)
                                    return learnedCapacityMah + " / " + designCapacityMah + " mAh"
                                return ""
                            }
                            font.pixelSize: Dims.l(6)
                            font.family: Theme.fontFamily
                            opacity: 0.9
                            visible: text !== ""
                        }
                        Label {
                            text: {
                                if (cycleCount > 0)
                                    //% "%1 charge cycles"
                                    return qsTrId("id-charge-cycles").arg(cycleCount)
                                return ""
                            }
                            font.pixelSize: Dims.l(6)
                            font.family: Theme.fontFamily
                            opacity: 0.8
                            visible: text !== ""
                        }
                    }
                }

                // Confidence indicator
                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: {
                        if (healthConfidence === "high")
                            //% "Accuracy: High (%1 samples)"
                            return qsTrId("id-health-accuracy-high").arg(healthSampleCount)
                        if (healthConfidence === "medium")
                            //% "Accuracy: Medium (%1 samples)"
                            return qsTrId("id-health-accuracy-medium").arg(healthSampleCount)
                        if (healthConfidence === "low")
                            //% "Accuracy: Improving..."
                            return qsTrId("id-health-accuracy-low")
                        return ""
                    }
                    font.pixelSize: Dims.l(6)
                    font.family: Theme.fontFamily
                    opacity: 0.8
                    visible: text !== "" && healthPercent > 0
                }

                // Health status text
                Label {
                    width: parent.width * 0.85
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: {
                        if (healthPercent <= 0) return ""
                        if (healthPercent >= 90)
                            //% "Battery is in excellent condition"
                            return qsTrId("id-health-excellent")
                        if (healthPercent >= 80)
                            //% "Battery is in good condition"
                            return qsTrId("id-health-good")
                        if (healthPercent >= 60)
                            //% "Battery is showing wear — consider replacement"
                            return qsTrId("id-health-worn")
                        //% "Battery is significantly degraded"
                        return qsTrId("id-health-degraded")
                    }
                    font.pixelSize: Dims.l(6)
                    font.family: Theme.fontFamily
                    opacity: 0.85
                    visible: text !== ""
                }

                Item { width: 1; height: Dims.h(1) }
            }

            Item {
                width: parent.width
                height: Dims.h(5)
            }
        }
    }

    PageTitle {
        //% "Power Manager"
        text: qsTrId("id-power-manager-page")
    }
}

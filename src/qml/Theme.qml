/*
 * Theme.qml — Centralized theme singleton for BolideOS Settings.
 *
 * Provides all colors, fonts, and gradient parameters used across the app.
 * Supports runtime theme switching via loadTheme(name).
 * Canvas-side colors use string type (rgba format) for JS context compatibility.
 * QML-side colors use color type with hex format (#AARRGGBB).
 *
 * Policy: Foreground/text colors are never fully transparent for legibility.
 */

pragma Singleton

import QtQuick 2.12

QtObject {
    id: theme

    // Increments on theme change — Canvas watches this to trigger repaint
    property int version: 0

    // Current theme identifier
    property string currentTheme: "deepBlue"

    // Available theme keys
    readonly property var themeNames: ["deepBlue", "ember", "arctic"]

    // ================================================================
    // STATIC: FONTS (same across all themes)
    // ================================================================
    readonly property string fontFamily: "Roboto Condensed"
    readonly property real letterSpacing: -0.5

    // H1: Large display numbers (battery %, big stats)
    readonly property real h1Size: 8
    readonly property int h1Weight: 63

    // H2: Section headers, graph titles, selected items
    readonly property real h2Size: 7
    readonly property int h2Weight: 70

    // H3: Regular body text, unselected menu items
    readonly property real h3Size: 5
    readonly property int h3Weight: 52

    // Caption: Small labels, axis labels
    readonly property real captionSize: 4
    readonly property int captionWeight: 25

    // Menu item label size (Dims.l units)
    readonly property real menuFontSize: 9

    // Menu font weights
    readonly property int menuSelectedWeight: 70
    readonly property int menuUnselectedWeight: 52

    // Graph title sizing
    readonly property real graphTitleSizeFactor: 0.12
    readonly property int graphTitleWeight: 50

    // ================================================================
    // DYNAMIC: COLORS (change with theme)
    // ================================================================

    // --- App Background ---
    property color appCenterColor: "#0044A6"
    property color appOuterColor: "#00010C"

    // --- Text Colors (never fully transparent) ---
    property color textPrimary: "#FFFFFF"
    property color textSecondary: "#B3FFFFFF"
    property color textDisabled: "#59FFFFFF"
    property color textAccent: "#FFD700"

    // --- Menu Highlight Gradient ---
    property color menuHighlightColor: "#CC1785DD"
    property real menuHighlightHold: 0.3
    property string menuHighlightStyle: "separator"   // "separator" = Garmin-style, "rounded" = pill-border
    property color menuSelectedText: "#FFFFFF"
    property color menuUnselectedText: "#FFFFFF"

    // --- Menu Border Gradient ---
    property color menuBorderColor: "#88FFFFFF"
    property real menuBorderHold: 0.3

    // --- Rounded highlight (used when menuHighlightStyle === "rounded") ---
    property int menuRoundedRadius: 0
    property int menuRoundedBorderWidth: 0
    property color menuRoundedBorderColor: "transparent"

    // --- Separator Line ---
    property color separatorActive: "#FFFFFF"
    property color separatorInactive: "#DDFFFFFF"

    // --- Icons ---
    property color iconActive: "#FFD700"
    property color iconInactive: "#88FFFFFF"
    property color iconDisabled: "#44FFFFFF"

    // --- Buttons ---
    property color buttonActiveBackground: "#CC1785DD"
    property color buttonActiveForeground: "#FFFFFF"
    property color buttonInactiveBackground: "#33FFFFFF"
    property color buttonInactiveForeground: "#AAFFFFFF"

    // --- Slider fill ---
    property color sliderFillColor: "#00BFA5"

    // --- Surfaces (panel/card backgrounds) ---
    property color surfaceColor: "#333333"
    property color surfaceDimColor: "#222222"
    property real cardGradientOpacity: 0.90

    // --- Graph: QML-side (color type, hex) ---
    property color graphBorderColor: "#6650C0FF"

    // --- Graph: Canvas-side (string type, rgba for JS context) ---
    property string graphLineColor: "#FF9800"
    property string graphFillTop: "rgba(255,152,0,0.70)"
    property real graphFillHold: 0.30
    property string graphFillMid: "rgba(255,152,0,0.18)"
    property string graphFillBottom: "rgba(255,152,0,0.02)"
    property string graphGrid: "rgba(80,160,255,0.30)"
    property string graphGlow: "rgba(255,180,60,0.45)"
    property string graphTitleFill: "rgba(100,200,255,0.85)"
    property string graphXAxisLabel: "rgba(255,200,100,0.6)"
    property string graphYAxisLabel: "rgba(160,220,255,0.6)"
    property string graphChargingTop: "rgba(76,175,80,0.55)"
    property string graphChargingMid: "rgba(76,175,80,0.18)"
    property string graphChargingBottom: "rgba(76,175,80,0.01)"
    property string graphNowLine: "rgba(0,220,255,0.45)"
    property string graphNowText: "rgba(0,220,255,0.65)"
    property string graphDayLabel: "rgba(255,255,255,0.5)"
    property string graphPrediction: "#F44336"

    // --- Graded intensity colors ---
    // Use these when a value maps to a low→medium→high scale,
    // e.g. power consumption, signal strength, sensor activity.
    // gradeLow = eco / minimal, gradeMid = moderate, gradeHigh = heavy / maximum.
    property color gradeLow: "#00E676"      // bright green
    property color gradeMid: "#FFEA00"      // bright yellow
    property color gradeHigh: "#FF1744"     // bright red

    // --- Health Status Colors ---
    property color healthGood: "#4CAF50"
    property color healthOk: "#FF9800"
    property color healthWarn: "#FF5722"
    property color healthBad: "#F44336"

    // ================================================================
    // THEME DEFINITIONS
    // ================================================================
    readonly property var _themes: ({
        "deepBlue": {
            "appCenterColor": "#0044A6",
            "menuHighlightStyle": "separator",
            "menuRoundedRadius": 0,
            "menuRoundedBorderWidth": 0,
            "menuRoundedBorderColor": "transparent",
            "appOuterColor": "#00010C",
            "textPrimary": "#FFFFFF",
            "textSecondary": "#B3FFFFFF",
            "textDisabled": "#59FFFFFF",
            "textAccent": "#FFD700",
            "menuHighlightColor": "#CC1785DD",
            "menuHighlightHold": 0.3,
            "menuSelectedText": "#FFFFFF",
            "menuUnselectedText": "#FFFFFF",
            "menuBorderColor": "#88FFFFFF",
            "menuBorderHold": 0.3,
            "separatorActive": "#FFFFFF",
            "separatorInactive": "#DDFFFFFF",
            "iconActive": "#FFD700",
            "iconInactive": "#88FFFFFF",
            "iconDisabled": "#44FFFFFF",
            "buttonActiveBackground": "#CC1785DD",
            "buttonActiveForeground": "#FFFFFF",
            "buttonInactiveBackground": "#33FFFFFF",
            "buttonInactiveForeground": "#AAFFFFFF",
            "sliderFillColor": "#00BFA5",
            "surfaceColor": "#333333",
            "surfaceDimColor": "#222222",
            "cardGradientOpacity": 0.90,
            "graphBorderColor": "#6650C0FF",
            "graphLineColor": "#FF9800",
            "graphFillTop": "rgba(255,152,0,0.70)",
            "graphFillHold": 0.30,
            "graphFillMid": "rgba(255,152,0,0.18)",
            "graphFillBottom": "rgba(255,152,0,0.02)",
            "graphGrid": "rgba(80,160,255,0.30)",
            "graphGlow": "rgba(255,180,60,0.45)",
            "graphTitleFill": "rgba(100,200,255,0.85)",
            "graphXAxisLabel": "rgba(255,200,100,0.6)",
            "graphYAxisLabel": "rgba(160,220,255,0.6)",
            "graphChargingTop": "rgba(76,175,80,0.55)",
            "graphChargingMid": "rgba(76,175,80,0.18)",
            "graphChargingBottom": "rgba(76,175,80,0.01)",
            "graphNowLine": "rgba(0,220,255,0.45)",
            "graphNowText": "rgba(0,220,255,0.65)",
            "graphDayLabel": "rgba(255,255,255,0.5)",
            "graphPrediction": "#F44336",
            "gradeLow": "#00E676",
            "gradeMid": "#FFEA00",
            "gradeHigh": "#FF1744",
            "healthGood": "#4CAF50",
            "healthOk": "#FF9800",
            "healthWarn": "#FF5722",
            "healthBad": "#F44336"
        },
        "ember": {
            "appCenterColor": "#3E1800",
            "menuHighlightStyle": "separator",
            "menuRoundedRadius": 0,
            "menuRoundedBorderWidth": 0,
            "menuRoundedBorderColor": "transparent",
            "appOuterColor": "#0A0000",
            "textPrimary": "#FFF3E0",
            "textSecondary": "#B3FFF3E0",
            "textDisabled": "#59FFF3E0",
            "textAccent": "#FF8A65",
            "menuHighlightColor": "#CCFF6D00",
            "menuHighlightHold": 0.3,
            "menuSelectedText": "#FFF3E0",
            "menuUnselectedText": "#FFF3E0",
            "menuBorderColor": "#88FFB74D",
            "menuBorderHold": 0.3,
            "separatorActive": "#FFF3E0",
            "separatorInactive": "#DDFFF3E0",
            "iconActive": "#FF8A65",
            "iconInactive": "#88FFCCBC",
            "iconDisabled": "#44FFCCBC",
            "buttonActiveBackground": "#CCFF6D00",
            "buttonActiveForeground": "#FFF3E0",
            "buttonInactiveBackground": "#33FFF3E0",
            "buttonInactiveForeground": "#AAFFF3E0",
            "sliderFillColor": "#FFD740",
            "surfaceColor": "#3D2B1F",
            "surfaceDimColor": "#2B1B11",
            "cardGradientOpacity": 0.90,
            "graphBorderColor": "#66FF8A00",
            "graphLineColor": "#00E5FF",
            "graphFillTop": "rgba(0,229,255,0.65)",
            "graphFillHold": 0.30,
            "graphFillMid": "rgba(0,229,255,0.18)",
            "graphFillBottom": "rgba(0,229,255,0.02)",
            "graphGrid": "rgba(0,229,255,0.20)",
            "graphGlow": "rgba(0,229,255,0.35)",
            "graphTitleFill": "rgba(255,200,100,0.85)",
            "graphXAxisLabel": "rgba(255,180,80,0.6)",
            "graphYAxisLabel": "rgba(100,220,255,0.6)",
            "graphChargingTop": "rgba(76,175,80,0.55)",
            "graphChargingMid": "rgba(76,175,80,0.18)",
            "graphChargingBottom": "rgba(76,175,80,0.01)",
            "graphNowLine": "rgba(255,180,60,0.45)",
            "graphNowText": "rgba(255,180,60,0.65)",
            "graphDayLabel": "rgba(255,243,224,0.5)",
            "graphPrediction": "#FF5722",
            "gradeLow": "#00E676",
            "gradeMid": "#FFEA00",
            "gradeHigh": "#FF1744",
            "healthGood": "#4CAF50",
            "healthOk": "#FF9800",
            "healthWarn": "#FF5722",
            "healthBad": "#F44336"
        },
        "arctic": {
            "appCenterColor": "#004D54",
            "appOuterColor": "#00090A",
            "menuHighlightStyle": "rounded",
            "menuRoundedRadius": 12,
            "menuRoundedBorderWidth": 2,
            "menuRoundedBorderColor": "#00E676",
            "textPrimary": "#E0F7FA",
            "textSecondary": "#B3E0F7FA",
            "textDisabled": "#59E0F7FA",
            "textAccent": "#00E5FF",
            "menuHighlightColor": "#CC00BCD4",
            "menuHighlightHold": 0.4,
            "menuSelectedText": "#FFFFFF",
            "menuUnselectedText": "#E0F7FA",
            "menuBorderColor": "#8800E676",
            "menuBorderHold": 0.3,
            "separatorActive": "#00E5FF",
            "separatorInactive": "#4400BCD4",
            "iconActive": "#00E5FF",
            "iconInactive": "#8800BCD4",
            "iconDisabled": "#4400BCD4",
            "buttonActiveBackground": "#CC00BCD4",
            "buttonActiveForeground": "#FFFFFF",
            "buttonInactiveBackground": "#33E0F7FA",
            "buttonInactiveForeground": "#AAE0F7FA",
            "sliderFillColor": "#00E5FF",
            "surfaceColor": "#1A3A3A",
            "surfaceDimColor": "#0D2626",
            "cardGradientOpacity": 0.90,
            "graphBorderColor": "#6600BCD4",
            "graphLineColor": "#00E5FF",
            "graphFillTop": "rgba(0,229,255,0.70)",
            "graphFillHold": 0.30,
            "graphFillMid": "rgba(0,229,255,0.18)",
            "graphFillBottom": "rgba(0,229,255,0.02)",
            "graphGrid": "rgba(0,188,212,0.25)",
            "graphGlow": "rgba(0,229,255,0.40)",
            "graphTitleFill": "rgba(0,229,255,0.85)",
            "graphXAxisLabel": "rgba(0,229,255,0.6)",
            "graphYAxisLabel": "rgba(0,229,255,0.6)",
            "graphChargingTop": "rgba(0,230,118,0.55)",
            "graphChargingMid": "rgba(0,230,118,0.18)",
            "graphChargingBottom": "rgba(0,230,118,0.01)",
            "graphNowLine": "rgba(255,255,255,0.45)",
            "graphNowText": "rgba(255,255,255,0.65)",
            "graphDayLabel": "rgba(224,247,250,0.5)",
            "graphPrediction": "#FF5252",
            "gradeLow": "#00E676",
            "gradeMid": "#FFEA00",
            "gradeHigh": "#FF1744",
            "healthGood": "#00E676",
            "healthOk": "#FFD600",
            "healthWarn": "#FF6E40",
            "healthBad": "#FF1744"
        }
    })

    function loadTheme(name) {
        var t = _themes[name]
        if (!t) return
        currentTheme = name
        var keys = Object.keys(t)
        for (var i = 0; i < keys.length; i++) {
            theme[keys[i]] = t[keys[i]]
        }
        version++
    }

    function themeLabel(key) {
        var labels = { "deepBlue": "Deep Blue", "ember": "Ember", "arctic": "Arctic" }
        return labels[key] || key
    }
}

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

/*
 * BatteryHistoryGraph — Canvas-drawn 7-day battery history chart with
 * smooth bezier curves, gradient fill that fades from opaque near the
 * line to transparent at the bottom, and a dashed prediction line.
 */
Canvas {
    id: graph

    property var historyData: []
    property real currentLevel: 0
    property real drainRatePerHour: 0
    property bool isCharging: false
    property string titleText: ""

    // Repaint when theme changes
    property int _themeVersion: Theme.version
    on_ThemeVersionChanged: requestPaint()

    onHistoryDataChanged: requestPaint()
    onCurrentLevelChanged: requestPaint()
    onDrainRatePerHourChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        if (width <= 0 || height <= 0) return

        var leftPad   = width * 0.14
        var rightPad  = width * 0.03
        var topPad    = height * 0.08
        var bottomPad = height * 0.22

        var chartW = width - leftPad - rightPad
        var chartH = height - topPad - bottomPad
        var chartBottom = topPad + chartH

        var now = Math.floor(Date.now() / 1000)
        var historySpan = 7 * 24 * 3600
        var totalSpan   = 8 * 24 * 3600
        var startTime   = now - historySpan

        function timeToX(t) {
            return leftPad + ((t - startTime) / totalSpan) * chartW
        }
        function levelToY(l) {
            return topPad + chartH * (1.0 - l / 100.0)
        }

        // --- Grid background (Garmin-style) ---
        // Horizontal lines at 0%, 25%, 50%, 75%, 100%
        ctx.strokeStyle = Theme.graphGrid
        ctx.lineWidth = 1
        var hGridLevels = [0, 25, 50, 75, 100]
        for (var g = 0; g < hGridLevels.length; g++) {
            var gy = levelToY(hGridLevels[g])
            ctx.beginPath()
            ctx.moveTo(leftPad, gy)
            ctx.lineTo(leftPad + chartW, gy)
            ctx.stroke()
        }
        // Vertical lines — one per day
        for (var vd = 0; vd <= 7; vd++) {
            var vx = timeToX(startTime + vd * 24 * 3600)
            ctx.beginPath()
            ctx.moveTo(vx, topPad)
            ctx.lineTo(vx, chartBottom)
            ctx.stroke()
        }

        // --- Y-axis labels ---
        var fontSize = Math.max(10, Math.round(height * 0.18))
        ctx.fillStyle = Theme.graphYAxisLabel
        ctx.font = fontSize + "px " + Theme.fontFamily
        ctx.textAlign = "right"
        ctx.textBaseline = "middle"
        ctx.fillText("100", leftPad - 3, levelToY(100))
        ctx.fillText("50",  leftPad - 3, levelToY(50))

        // --- Day labels ---
        var dayFontSize = Math.max(10, Math.round(height * 0.16))
        ctx.font = dayFontSize + "px " + Theme.fontFamily
        ctx.fillStyle = Theme.graphXAxisLabel
        ctx.textAlign = "center"
        ctx.textBaseline = "top"
        var dayAbbr = ["S","M","T","W","T","F","S"]
        for (var d = 0; d < 7; d++) {
            var dayMid = startTime + d * 24 * 3600 + 12 * 3600
            var dx = timeToX(dayMid)
            var dd = new Date(dayMid * 1000)
            ctx.fillText(dayAbbr[dd.getDay()], dx, chartBottom + 3)
        }

        // --- "Now" vertical marker ---
        var nowX = timeToX(now)
        ctx.strokeStyle = Theme.graphNowLine
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.moveTo(nowX, topPad)
        ctx.lineTo(nowX, chartBottom)
        ctx.stroke()

        var nowFontSize = Math.max(10, Math.round(height * 0.16))
        ctx.font = nowFontSize + "px " + Theme.fontFamily
        ctx.fillStyle = Theme.graphNowText
        ctx.textAlign = "center"
        ctx.textBaseline = "bottom"
        ctx.fillText("now", nowX, topPad - 1)

        // --- Battery history ---
        if (historyData.length > 0) {
            var sorted = historyData.slice().sort(function(a, b) {
                return a.timestamp - b.timestamp
            })

            // Filter to visible range
            var visible = []
            var lastBefore = null
            for (var i = 0; i < sorted.length; i++) {
                if (sorted[i].timestamp < startTime) {
                    lastBefore = sorted[i]
                } else {
                    visible.push(sorted[i])
                }
            }
            if (visible.length === 0 && lastBefore)
                visible.push(lastBefore)
            if (visible.length > 0 && lastBefore && visible[0] !== lastBefore)
                visible.unshift(lastBefore)

            if (visible.length >= 2) {
                // Build point arrays
                var pts = []
                for (var i = 0; i < visible.length; i++) {
                    pts.push({
                        x: timeToX(Math.max(visible[i].timestamp, startTime)),
                        y: levelToY(visible[i].level)
                    })
                }

                // --- Smooth bezier curve using Catmull-Rom spline ---
                // --- Smooth bezier curve using Catmull-Rom spline ---
                // continuePath: draws bezier segments from current pen position
                function traceSmoothSegments(ctx, pts) {
                    if (pts.length < 2) return
                    if (pts.length === 2) {
                        ctx.lineTo(pts[1].x, pts[1].y)
                        return
                    }
                    var tension = 0.3
                    for (var i = 0; i < pts.length - 1; i++) {
                        var p0 = pts[Math.max(0, i - 1)]
                        var p1 = pts[i]
                        var p2 = pts[i + 1]
                        var p3 = pts[Math.min(pts.length - 1, i + 2)]
                        var cp1x = p1.x + (p2.x - p0.x) * tension
                        var cp1y = p1.y + (p2.y - p0.y) * tension
                        var cp2x = p2.x - (p3.x - p1.x) * tension
                        var cp2y = p2.y - (p3.y - p1.y) * tension
                        ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, p2.x, p2.y)
                    }
                }

                // --- Gradient fill under smooth curve ---
                ctx.beginPath()
                ctx.moveTo(pts[0].x, chartBottom)
                ctx.lineTo(pts[0].x, pts[0].y)
                traceSmoothSegments(ctx, pts)
                ctx.lineTo(pts[pts.length - 1].x, chartBottom)
                ctx.closePath()

                var grad = ctx.createLinearGradient(0, topPad, 0, chartBottom)
                grad.addColorStop(0.0, Theme.graphFillTop)
                grad.addColorStop(Theme.graphFillHold, Theme.graphFillTop)
                grad.addColorStop(0.65, Theme.graphFillMid)
                grad.addColorStop(1.0, Theme.graphFillBottom)
                ctx.fillStyle = grad
                ctx.fill()

                // --- Green overlay for charging segments ---
                for (var i = 0; i < visible.length - 1; i++) {
                    if (visible[i].charging) {
                        var cx1 = timeToX(visible[i].timestamp)
                        var cy1 = levelToY(visible[i].level)
                        var cx2 = timeToX(visible[i + 1].timestamp)
                        var cy2 = levelToY(visible[i + 1].level)
                        ctx.beginPath()
                        ctx.moveTo(cx1, chartBottom)
                        ctx.lineTo(cx1, cy1)
                        ctx.lineTo(cx2, cy2)
                        ctx.lineTo(cx2, chartBottom)
                        ctx.closePath()
                        var cGrad = ctx.createLinearGradient(0, Math.min(cy1, cy2), 0, chartBottom)
                        cGrad.addColorStop(0.0, Theme.graphChargingTop)
                        cGrad.addColorStop(0.5, Theme.graphChargingMid)
                        cGrad.addColorStop(1.0, Theme.graphChargingBottom)
                        ctx.fillStyle = cGrad
                        ctx.fill()
                    }
                }

                // --- Smooth stroke on top (the visible line) ---

                // --- Grid glow through gradient fill ---
                // Re-draw grid lines inside the filled area with orange tint
                ctx.save()
                ctx.beginPath()
                ctx.moveTo(pts[0].x, chartBottom)
                ctx.lineTo(pts[0].x, pts[0].y)
                traceSmoothSegments(ctx, pts)
                ctx.lineTo(pts[pts.length - 1].x, chartBottom)
                ctx.closePath()
                ctx.clip()
                ctx.lineWidth = 1
                ctx.strokeStyle = Theme.graphGlow
                for (var gh = 0; gh < hGridLevels.length; gh++) {
                    var ghy = levelToY(hGridLevels[gh])
                    ctx.beginPath()
                    ctx.moveTo(leftPad, ghy)
                    ctx.lineTo(leftPad + chartW, ghy)
                    ctx.stroke()
                }
                for (var gv = 0; gv <= 7; gv++) {
                    var gvx = timeToX(startTime + gv * 24 * 3600)
                    ctx.beginPath()
                    ctx.moveTo(gvx, topPad)
                    ctx.lineTo(gvx, chartBottom)
                    ctx.stroke()
                }
                ctx.restore()

                ctx.beginPath()
                ctx.moveTo(pts[0].x, pts[0].y)
                traceSmoothSegments(ctx, pts)
                ctx.strokeStyle = Theme.graphLineColor
                ctx.lineWidth = 2.5
                ctx.stroke()

            } else if (visible.length === 1) {
                // Single data point — draw a horizontal line from point to "now"
                var px = timeToX(Math.max(visible[0].timestamp, startTime))
                var py = levelToY(visible[0].level)
                var endX = Math.min(nowX, leftPad + chartW)

                // Gradient fill under the line
                ctx.beginPath()
                ctx.moveTo(px, chartBottom)
                ctx.lineTo(px, py)
                ctx.lineTo(endX, py)
                ctx.lineTo(endX, chartBottom)
                ctx.closePath()
                var sGrad = ctx.createLinearGradient(0, py, 0, chartBottom)
                sGrad.addColorStop(0.0, Theme.graphFillTop)
                sGrad.addColorStop(0.5, Theme.graphFillMid)
                sGrad.addColorStop(1.0, Theme.graphFillBottom)
                ctx.fillStyle = sGrad
                ctx.fill()

                // Visible line
                ctx.beginPath()
                ctx.moveTo(px, py)
                ctx.lineTo(endX, py)
                ctx.strokeStyle = Theme.graphLineColor
                ctx.lineWidth = 2.5
                ctx.stroke()

                // Dot at current position
                ctx.beginPath()
                ctx.arc(endX, py, 4, 0, 2 * Math.PI)
                ctx.fillStyle = Theme.graphLineColor
                ctx.fill()
            }
        }

        // --- Prediction dashed line ---
        if (drainRatePerHour > 0 && !isCharging && currentLevel > 0) {
            var predStartX = nowX
            var predStartY = levelToY(currentLevel)
            var hoursToEmpty = currentLevel / drainRatePerHour
            var emptyTime = now + hoursToEmpty * 3600
            var predEndX = timeToX(emptyTime)
            var predEndY = levelToY(0)

            if (predEndX > leftPad + chartW) {
                var ratio = (leftPad + chartW - predStartX) / (predEndX - predStartX)
                predEndX = leftPad + chartW
                predEndY = predStartY + ratio * (levelToY(0) - predStartY)
            }

            ctx.strokeStyle = Theme.graphPrediction
            ctx.lineWidth = 1.5
            var pdx = predEndX - predStartX
            var pdy = predEndY - predStartY
            var dist = Math.sqrt(pdx * pdx + pdy * pdy)
            if (dist > 0) {
                var dashLen = 5, gapLen = 4
                var drawn = 0, on = true
                while (drawn < dist) {
                    var segLen = on ? dashLen : gapLen
                    if (drawn + segLen > dist) segLen = dist - drawn
                    var t1 = drawn / dist
                    var t2 = (drawn + segLen) / dist
                    if (on) {
                        ctx.beginPath()
                        ctx.moveTo(predStartX + t1 * pdx, predStartY + t1 * pdy)
                        ctx.lineTo(predStartX + t2 * pdx, predStartY + t2 * pdy)
                        ctx.stroke()
                    }
                    drawn += segLen
                    on = !on
                }
            }
        }
    }
}

import QtQuick 2.9
import QtGraphicalEffects 1.0
import org.asteroid.controls 1.0
import org.asteroid.utils 1.0
import org.bolide.theme 1.0

Item {
    id: root
    property string text: ""

    height: Dims.h(20)
    anchors {
        top: parent.top
        left: parent.left
        right: parent.right
    }
    z: 1

    // Fade overlay — scrolling content dims behind the title
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#CC000000" }
            GradientStop { position: 0.6; color: "#99000000" }
            GradientStop { position: 1.0; color: "#00000000" }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 4

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.text
            font.pixelSize: Dims.l(7)
            font.family: Theme.fontFamily
            font.weight: Theme.menuSelectedWeight
            font.letterSpacing: Theme.letterSpacing
            color: Theme.textPrimary
            renderType: Text.NativeRendering
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        // Separator line directly under text
        Item {
            width: Dims.w(80)
            height: 2
            anchors.horizontalCenter: parent.horizontalCenter

            LinearGradient {
                anchors.fill: parent
                start: Qt.point(0, 0)
                end: Qt.point(parent.width, 0)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#00FFFFFF" }
                    GradientStop { position: 0.5; color: "#FFFFFFFF" }
                    GradientStop { position: 1.0; color: "#00FFFFFF" }
                }
            }
        }
    }
}

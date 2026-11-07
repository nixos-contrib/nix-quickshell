import QtQuick
import QtQuick.Shapes
import qs

// The icon of the Bluetooth, drawn like the ones of the network: the Lucide shapes, a thin line with round ends. Connected has the two bars at its sides, and
// what is off has the slash
Item {
    id: icon
    property bool connected: false
    property bool crossed: false
    property color color: Theme.barText
    property int size: Theme.statusIcon

    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 24
        height: 24
        scale: icon.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: icon.color
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: icon.crossed ? "m17 17-5 5V12l-5 5M14.5 9.5 17 7l-5-5v4.5" : "m7 7 10 10-5 5V2l5 5L7 17" }
        }
        ShapePath {
            strokeColor: icon.connected && !icon.crossed ? icon.color : "transparent"
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M18 12h3M3 12h3" }
        }
        ShapePath {
            strokeColor: icon.crossed ? icon.color : "transparent"
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: "m2 2 20 20" }
        }
    }
}

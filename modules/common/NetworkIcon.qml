import QtQuick
import QtQuick.Shapes
import qs

// The icons of the network, drawn like the speaker and the player: Lucide shapes, a thin line with round ends, the same at every size. kind is wifi,
// wired or airplane. A wifi has its waves by strength, 0 to 3 of them, and a cable or a wifi that is not connected is crossed
Item {
    id: icon
    property string kind: "wired"
    // the waves of a wifi: 0 to 3
    property int level: 3
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

        // the point of the wifi, and the waves: the nearest is the smallest
        ShapePath {
            strokeColor: icon.kind === "wifi" ? icon.color : "transparent"
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M12 20h.01" }
        }
        ShapePath {
            strokeColor: icon.kind === "wifi" && icon.level >= 1 ? icon.color : "transparent"
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M8.5 16.429a5 5 0 0 1 7 0" }
        }
        ShapePath {
            strokeColor: icon.kind === "wifi" && icon.level >= 2 ? icon.color : "transparent"
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M5 12.859a10 10 0 0 1 14 0" }
        }
        ShapePath {
            strokeColor: icon.kind === "wifi" && icon.level >= 3 ? icon.color : "transparent"
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M2 8.82a15 15 0 0 1 20 0" }
        }
        // the port of a cable, with its pins
        ShapePath {
            strokeColor: icon.kind === "wired" ? icon.color : "transparent"
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: "m15 20 3-3h2a2 2 0 0 0 2-2V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h2l3 3z" }
        }
        ShapePath {
            strokeColor: icon.kind === "wired" ? icon.color : "transparent"
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M6 8v1M10 8v1M14 8v1M18 8v1" }
        }
        // the plane of the airplane mode
        ShapePath {
            strokeColor: icon.kind === "airplane" ? icon.color : "transparent"
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: "M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z" }
        }
        // the slash of what is not connected
        ShapePath {
            strokeColor: icon.crossed ? icon.color : "transparent"
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: "m2 2 20 20" }
        }
    }
}

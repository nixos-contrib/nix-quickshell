import QtQuick
import QtQuick.Shapes
import qs

// The icons of a player, drawn like the speaker and the chevron: Lucide shapes, a thin line with round ends, the same at every size. kind is
// play, pause, previous or next. A play and a pause may be filled, as the main button of the popup is
Item {
    id: icon
    property string kind: "play"
    property color color: Theme.barText
    property bool filled: false
    property int size: Theme.statusIcon

    implicitWidth: size
    implicitHeight: size

    readonly property var shapes: ({
        "play": ["M6 3l14 9-14 9V3z"],
        "pause": ["M14 4h4v16h-4z", "M6 4h4v16H6z"],
        "previous": ["M19 20L9 12l10-8v16z", "M5 19V5"],
        "next": ["M5 4l10 8-10 8V4z", "M19 5v14"]
    })
    // the bar and the controls of the previous and the next are lines: only a play and a pause have a body to fill
    readonly property bool solid: filled && (kind === "play" || kind === "pause")

    Shape {
        width: 24
        height: 24
        scale: icon.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: icon.color
            strokeWidth: 2
            fillColor: icon.solid ? icon.color : "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: icon.shapes[icon.kind][0] }
        }
        ShapePath {
            strokeColor: icon.shapes[icon.kind].length > 1 ? icon.color : "transparent"
            strokeWidth: 2
            fillColor: icon.solid && icon.shapes[icon.kind].length > 1 ? icon.color : "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: icon.shapes[icon.kind].length > 1 ? icon.shapes[icon.kind][1] : "M0 0" }
        }
    }
}

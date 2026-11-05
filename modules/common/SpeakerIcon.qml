import QtQuick
import QtQuick.Shapes
import qs

// The speaker, drawn: the same body at every level, with one or two waves, or a cross when it is muted or at zero. The glyphs of an
// icon font have each their own size, and the icon jumped when the volume crossed a third. The shapes are the ones of Lucide
Item {
    id: icon
    property real level: 1
    property bool muted: false
    property color color: Theme.barText
    property int size: Theme.statusIcon

    readonly property bool crossed: muted || level <= 0
    readonly property int waves: crossed ? 0 : (level < 0.5 ? 1 : 2)

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
            PathSvg { path: "M11 5 6 9H2v6h4l5 4V5z" }
        }
        ShapePath {
            strokeColor: icon.waves >= 1 ? icon.color : "transparent"
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M15.54 8.46a5 5 0 0 1 0 7.07" }
        }
        ShapePath {
            strokeColor: icon.waves >= 2 ? icon.color : "transparent"
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M19.07 4.93a10 10 0 0 1 0 14.14" }
        }
        ShapePath {
            strokeColor: icon.crossed ? icon.color : "transparent"
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathSvg { path: "M22 9l-6 6M16 9l6 6" }
        }
    }
}

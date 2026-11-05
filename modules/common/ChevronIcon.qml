import QtQuick
import QtQuick.Shapes
import qs

// A chevron that points down, drawn: a thin line with round ends, as the shape of Lucide, so that it is the same at every size and
// does not depend on a glyph of a font. The same stroke as the speaker, the icon of the bar that has a drawing
Item {
    id: icon
    property color color: Theme.muted
    property int size: 16

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
            startX: 6; startY: 9
            PathLine { x: 12; y: 15 }
            PathLine { x: 18; y: 9 }
        }
    }
}

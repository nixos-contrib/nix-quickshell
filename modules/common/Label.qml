import QtQuick
import qs

// The text of the shell: one component with the five roles of the theme, so that the same thing is written the same way
// everywhere. role is heading, title, body, caption or label. strong makes the body bold
Text {
    id: label
    property string role: "body"
    property bool strong: false

    readonly property bool quiet: role === "caption" || role === "label"

    color: quiet ? Theme.muted : Theme.text
    font {
        family: Theme.font
        pixelSize: role === "heading" ? Theme.textHeading : role === "title" ? Theme.textTitle : role === "caption" ? Theme.textCaption : role === "label" ? Theme.textLabel : Theme.textBody
        weight: role === "heading" || role === "title" || strong ? Font.DemiBold : (role === "label" ? Font.Normal : Font.Normal)
        capitalization: role === "label" ? Font.AllUppercase : Font.MixedCase
        letterSpacing: role === "label" ? 0.6 : 0
    }
}

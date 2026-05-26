import QtQuick
import qs.services

Text {
    property string section: ""

    text: section
    color: Config.styling.text1
    font.pixelSize: 11
    font.bold: true
    leftPadding: Config.spacing.sm
    rightPadding: Config.spacing.sm
    topPadding: Config.spacing.xs
    bottomPadding: Config.spacing.xxs
}

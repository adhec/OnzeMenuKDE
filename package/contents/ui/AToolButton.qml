import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore

Rectangle{

    id:item

    implicitHeight: Math.floor(units.gridUnit * 1.8)
    width: Math.floor(lb.implicitWidth + units.smallSpacing * 5 + icon.width)


    border.width: 1
    border.color: mouseItem.containsMouse ? theme.highlightColor  : colorWithAlpha(theme.textColor,0.2)
    radius: 2
    color: theme.backgroundColor
    smooth: plasmoid.configuration.iconSmooth


    property alias text: lb.text
    property bool flat: false
    property alias iconName: icon.source
    property bool mirror: false

    signal clicked

    RowLayout{
        id: row
        anchors.fill: parent
        anchors.leftMargin: units.smallSpacing * 2
        anchors.rightMargin: units.smallSpacing * 2
        spacing: units.smallSpacing
        LayoutMirroring.enabled: mirror

        Label{
            id: lb
            color: theme.textColor
        }
        PlasmaCore.IconItem {
            id: icon
            implicitHeight: units.gridUnit
            implicitWidth: implicitHeight
            smooth: plasmoid.configuration.iconSmooth
        }
    }

    MouseArea {
        id: mouseItem
        hoverEnabled: true
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: item.clicked()
    }

}

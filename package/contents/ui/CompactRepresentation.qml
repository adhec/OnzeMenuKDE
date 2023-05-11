/***************************************************************************
 *   Copyright (C) 2013-2014 by Eike Hein <hein@kde.org>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.0
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PC3

Item {
    id: root

    readonly property var screenGeometry: plasmoid.screenGeometry
    readonly property bool inPanel: (plasmoid.location == PlasmaCore.Types.TopEdge
        || plasmoid.location == PlasmaCore.Types.RightEdge
        || plasmoid.location == PlasmaCore.Types.BottomEdge
        || plasmoid.location == PlasmaCore.Types.LeftEdge)
    readonly property bool vertical: (plasmoid.formFactor == PlasmaCore.Types.Vertical)
    readonly property bool useCustomButtonImage: (plasmoid.configuration.useCustomButtonImage
        && plasmoid.configuration.customButtonImage.length != 0)
    property QtObject dashWindow: null

    Plasmoid.status: dashWindow && dashWindow.visible ? PlasmaCore.Types.RequiresAttentionStatus : PlasmaCore.Types.PassiveStatus

    // Taken from DigitalClock to ensure uniform sizing when next to each other
    readonly property bool tooSmall: plasmoid.formFactor === PlasmaCore.Types.Horizontal && Math.round(2 * (root.height / 5)) <= PlasmaCore.Theme.smallestFont.pixelSize

    readonly property bool shouldHaveIcon: Plasmoid.formFactor === PlasmaCore.Types.Vertical || Plasmoid.icon !== ""
    readonly property bool shouldHaveLabel: Plasmoid.formFactor !== PlasmaCore.Types.Vertical && Plasmoid.configuration.menuLabel !== ""


   // onWidthChanged: updateSizeHints()
   // onHeightChanged: updateSizeHints()

    function updateSizeHints() {
        if (useCustomButtonImage) {
            if (vertical) {
                var scaledHeight = Math.floor(parent.width * (buttonIcon.implicitHeight / buttonIcon.implicitWidth));
                root.Layout.minimumHeight = scaledHeight;
                root.Layout.maximumHeight = scaledHeight;
                root.Layout.minimumWidth = PlasmaCore.Units.iconSizes.small;
                root.Layout.maximumWidth = inPanel ? PlasmaCore.Units.iconSizeHints.panel : -1;
            } else {
                var scaledWidth = Math.floor(parent.height * (buttonIcon.implicitWidth / buttonIcon.implicitHeight));
                root.Layout.minimumWidth = scaledWidth;
                root.Layout.maximumWidth = scaledWidth;
                root.Layout.minimumHeight = PlasmaCore.Units.iconSizes.small;
                root.Layout.maximumHeight = inPanel ? PlasmaCore.Units.iconSizeHints.panel : -1;
            }
        } else {
            root.Layout.minimumWidth = PlasmaCore.Units.iconSizes.small;
            root.Layout.maximumWidth = inPanel ? PlasmaCore.Units.iconSizeHints.panel : -1;
            root.Layout.minimumHeight = PlasmaCore.Units.iconSizes.small
            root.Layout.maximumHeight = inPanel ? PlasmaCore.Units.iconSizeHints.panel : -1;
        }
    }

    readonly property var sizing: {
        const displayedIcon = buttonIcon.valid ? buttonIcon : buttonIconFallback;

        let impWidth = 0;
        if (shouldHaveIcon) {
            impWidth += displayedIcon.width;
        }
        if (shouldHaveLabel) {
            impWidth += labelTextField.contentWidth + labelTextField.Layout.leftMargin + labelTextField.Layout.rightMargin;
        }
        const impHeight = Math.max(PlasmaCore.Units.iconSizeHints.panel, displayedIcon.height);

        // at least square, but can be wider/taller
        if (root.inPanel) {
            if (root.vertical) {
                return {
                    minimumWidth: -1,
                    maximumWidth: PlasmaCore.Units.iconSizeHints.panel,
                    minimumHeight: -1,
                    maximumHeight: impHeight,
                };
            } else { // horizontal
                return {
                    minimumWidth: impWidth,
                    maximumWidth: impWidth,
                    minimumHeight: -1,
                    maximumHeight: PlasmaCore.Units.iconSizeHints.panel,
                };
            }
        } else {
            return {
                minimumWidth: impWidth,
                maximumWidth: -1,
                minimumHeight: PlasmaCore.Units.iconSizes.small,
                maximumHeight: -1,
            };
        }
    }

    implicitWidth: PlasmaCore.Units.iconSizeHints.panel
    implicitHeight: PlasmaCore.Units.iconSizeHints.panel

    Layout.minimumWidth: sizing.minimumWidth
    Layout.maximumWidth: sizing.maximumWidth
    Layout.minimumHeight: sizing.minimumHeight
    Layout.maximumHeight: sizing.maximumHeight


    //Connections {
    //    target: PlasmaCore.Units.iconSizeHints
    //    function onPanelChanged(){ updateSizeHints()}
    //}

    PlasmaCore.IconItem {
        id: buttonIcon3

        anchors.fill: parent

        readonly property double aspectRatio: (vertical ? implicitHeight / implicitWidth
            : implicitWidth / implicitHeight)

        source: useCustomButtonImage ? plasmoid.configuration.customButtonImage : plasmoid.configuration.icon

        active: mouseArea.containsMouse

        smooth: true
        visible: false

        // A custom icon could also be rectangular. However, if a square, custom, icon is given, assume it
        // to be an icon and round it to the nearest icon size again to avoid scaling artefacts.
        roundToIconSize: !useCustomButtonImage || aspectRatio === 1

       // onSourceChanged: updateSizeHints()
    }

    RowLayout {
        id: iconLabelRow
        anchors.fill: parent
        spacing: 0

        PlasmaCore.IconItem {
            id: buttonIcon

            Layout.fillWidth: root.vertical
            Layout.fillHeight: !root.vertical
            Layout.preferredWidth: root.vertical ? -1 : height / (implicitHeight / implicitWidth)
            Layout.preferredHeight: !root.vertical ? -1 : width * (implicitHeight / implicitWidth)
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            source: useCustomButtonImage ? plasmoid.configuration.customButtonImage : plasmoid.configuration.icon
            //source: Tools.iconOrDefault(plasmoid.formFactor, plasmoid.icon)
            //active: compactRoot.containsMouse || compactDragArea.containsDrag
            roundToIconSize: implicitHeight === implicitWidth
            visible: valid
        }

        PlasmaCore.IconItem {
            id: buttonIconFallback
            // fallback is assumed to be square
            Layout.fillWidth: root.vertical
            Layout.fillHeight: !root.vertical
            Layout.preferredWidth: root.vertical ? -1 : height
            Layout.preferredHeight: !root.vertical ? -1 : width
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            source: buttonIcon.valid ? null : Tools.defaultIconName
            //active: compactRoot.containsMouse || compactDragArea.containsDrag
            visible: !buttonIcon.valid && Plasmoid.icon !== ""
        }

        PC3.Label {
            id: labelTextField

            Layout.fillHeight: true
            Layout.leftMargin: PlasmaCore.Units.smallSpacing
            Layout.rightMargin: PlasmaCore.Units.smallSpacing

            text: plasmoid.configuration.menuLabel
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
            //fontSizeMode: Text.VerticalFit
            font.pixelSize: plasmoid.configuration.textLabelFontsize
            //font.pixelSize: compactRoot.tooSmall ? PlasmaCore.Theme.defaultFont.pixelSize : PlasmaCore.Units.roundToIconSize(PlasmaCore.Units.gridUnit * 2)
            minimumPointSize: PlasmaCore.Theme.smallestFont.pointSize
            visible: root.shouldHaveLabel
        }
    }

    MouseArea
    {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
            dashWindow.visible = !dashWindow.visible;
        }
    }

    Component.onCompleted: {
        dashWindow = Qt.createQmlObject("MenuRepresentation {}", root);
        plasmoid.activated.connect(function() {
            dashWindow.visible = !dashWindow.visible;
        });
    }
}

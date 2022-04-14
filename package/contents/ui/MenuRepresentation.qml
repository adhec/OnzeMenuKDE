/***************************************************************************
 *   Copyright (C) 2014 by Weng Xuetian <wengxt@gmail.com>
 *   Copyright (C) 2013-2017 by Eike Hein <hein@kde.org>                   *
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

import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.plasma.extras 2.0 as PlasmaExtras

import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.kcoreaddons 1.0 as KCoreAddons // kuser
import org.kde.plasma.private.shell 2.0
import QtQuick.Controls.Styles 1.4

import org.kde.kwindowsystem 1.0
import QtGraphicalEffects 1.0
import org.kde.kquickcontrolsaddons 2.0

import org.kde.plasma.components 3.0 as PlasmaComponents3

PlasmaCore.Dialog {
    id: root

    objectName: "popupWindow"
    flags: Qt.WindowStaysOnTopHint
    location: PlasmaCore.Types.Floating
    hideOnWindowDeactivate: true

    property int iconSize: units.iconSizes.medium
    property int iconSizeSquare: units.iconSizes.medium
    property int tileSideHeight: units.iconSizes.large + theme.mSize(theme.defaultFont).height
                                 + (4 * units.smallSpacing)
                                 + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                                 highlightItemSvg.margins.left + highlightItemSvg.margins.right))

    property int tileSideWidth: tileSideHeight

    property int tileHeightDocuments: units.gridUnit * 2 + units.smallSpacing * 4

    property bool searching: (searchField.text != "")
    property bool readySearch: false
    property bool viewDocuments: false

    property int _margin: units.largeSpacing * 0.5

    function colorWithAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }


    onVisibleChanged: {
        if (visible) {
            reset();
            var pos = popupPosition(width, height);
            x = pos.x;
            y = pos.y;
            requestActivate();
            //animation1.start()
        }else{
            reset()
        }
    }

    onHeightChanged: {
        var pos = popupPosition(width, height);
        x = pos.x;
        y = pos.y;
    }

    onWidthChanged: {
        var pos = popupPosition(width, height);
        x = pos.x;
        y = pos.y;
    }

    onSearchingChanged: {
        if (!searching) {
            reset();
        }else{
            viewDocuments = false
            readySearch = false
        }
    }

    function reset() {
        preloadAllAppsTimer.restart();
        globalFavoritesGrid.tryActivate(0,0)
        searchField.clear();
        readySearch = false
        viewDocuments = false
    }

    function toggle(){
        root.visible = false;
    }


    function popupPosition(width, height) {
        var screenAvail = plasmoid.availableScreenRect;
        var screenGeom = plasmoid.screenGeometry;

        var screen = Qt.rect(screenAvail.x + screenGeom.x,
                             screenAvail.y + screenGeom.y,
                             screenAvail.width,
                             screenAvail.height);


        var offset = units.smallSpacing;

        // Fall back to bottom-left of screen area when the applet is on the desktop or floating.
        var x = offset;
        var y = screen.height - height - offset;
        var appletTopLeft;
        var horizMidPoint;
        var vertMidPoint;


        if (plasmoid.configuration.displayPosition === 1) {
            horizMidPoint = screen.x + (screen.width / 2);
            vertMidPoint = screen.y + (screen.height / 2);
            x = horizMidPoint - width / 2;
            y = vertMidPoint - height / 2;
        } else if (plasmoid.configuration.displayPosition === 2) {
            horizMidPoint = screen.x + (screen.width / 2);
            vertMidPoint = screen.y + (screen.height / 2);
            x = horizMidPoint - width / 2;
            y = screen.height - height - offset - panelSvg.margins.top;
        } else if (plasmoid.location === PlasmaCore.Types.BottomEdge) {
            horizMidPoint = screen.x + (screen.width / 2);
            appletTopLeft = parent.mapToGlobal(0, 0);
            x = (appletTopLeft.x < horizMidPoint) ? screen.x + offset : (screen.x + screen.width) - width - offset;
            y = screen.height - height - offset - panelSvg.margins.top;
        } else if (plasmoid.location === PlasmaCore.Types.TopEdge) {
            horizMidPoint = screen.x + (screen.width / 2);
            var appletBottomLeft = parent.mapToGlobal(0, parent.height);
            x = (appletBottomLeft.x < horizMidPoint) ? screen.x + offset : (screen.x + screen.width) - width - offset;
            y = parent.height + panelSvg.margins.bottom + offset;
        } else if (plasmoid.location === PlasmaCore.Types.LeftEdge) {
            vertMidPoint = screen.y + (screen.height / 2);
            appletTopLeft = parent.mapToGlobal(0, 0);
            x = parent.width + panelSvg.margins.right + offset;
            y = (appletTopLeft.y < vertMidPoint) ? screen.y + offset : (screen.y + screen.height) - height - offset;
        } else if (plasmoid.location === PlasmaCore.Types.RightEdge) {
            vertMidPoint = screen.y + (screen.height / 2);
            appletTopLeft = parent.mapToGlobal(0, 0);
            x = appletTopLeft.x - panelSvg.margins.left - offset - width;
            y = (appletTopLeft.y < vertMidPoint) ? screen.y + offset : (screen.y + screen.height) - height - offset;
        }

        return Qt.point(x, y);
    }


    FocusScope {

        id: focusScope

        Layout.maximumWidth:  (tileSideWidth *  plasmoid.configuration.numberColumns) + units.largeSpacing * 2
        Layout.minimumWidth:  (tileSideWidth *  plasmoid.configuration.numberColumns) + units.largeSpacing * 2

        Layout.minimumHeight: searchField.implicitHeight + topRow.height +  firstPage.height + footer.height + _margin * 6
        Layout.maximumHeight:  Layout.minimumHeight
        property bool done: false

        ScaleAnimator{id: animation1 ; target: globalFavoritesGrid ; from: 0.9; to: 1; duration: units.shortDuration*2; easing.type: Easing.InOutQuad }
        XAnimator{id: animation2; target: mainColumn ; from: focusScope.width; to: units.smallSpacing; duration: units.shortDuration*2; easing.type: Easing.OutCubic }


        focus: true

        PlasmaExtras.Heading {
            id: dummyHeading
            visible: false
            width: 0
            level: 1
        }

        TextMetrics {
            id: headingMetrics
            font: dummyHeading.font
        }

        PlasmaComponents.Menu {
            id: contextMenu
            PlasmaComponents.MenuItem {
                action: plasmoid.action("configure")
            }
        }

        Timer {
            id: preloadAllAppsTimer
            property bool done: false
            interval: 1000
            repeat: false
            onTriggered: {
                if (done) {
                    return;
                }
                for (var i = 0; i < rootModel.count; ++i) {
                    var model = rootModel.modelForRow(i);
                    if (model.description === "KICKER_ALL_MODEL") {
                        allAppsGrid.model = model;
                        done = true;
                        break;
                    }
                }
            }
            function defer() {
                if (!running && !done) {
                    restart();
                }
            }
        }

        PlasmaComponents3.TextField {
            id: searchField
            anchors.top: parent.top
            anchors.margins: _margin * 2
            anchors.horizontalCenter: parent.horizontalCenter
            focus: true
            width: tileSideWidth * plasmoid.configuration.numberColumns
            implicitHeight: units.gridUnit * 2
            placeholderText: i18n("Type here to search ...")
            placeholderTextColor: colorWithAlpha(theme.textColor,0.7)
            leftPadding: units.largeSpacing + units.iconSizes.small
            topPadding: units.gridUnit * 0.5
            verticalAlignment: Text.AlignTop
            background: Rectangle {
                color: theme.backgroundColor
                radius: 3
                border.width: 1
                border.color: colorWithAlpha(theme.textColor,0.05)
            }
            onTextChanged: {
                runnerModel.query = text;

            }
            function clear() {
                text = "";
            }
            function backspace() {
                if(searching) text = text.slice(0, -1);
                //focus = true;
            }
            function appendText(newText) {
                if (!root.visible) {
                    return;
                }
                //focus = true;
                text = text + newText;
            }
            Keys.onPressed: {
                if (event.key == Qt.Key_Space) {
                    event.accepted = true;
                } else if (event.key == Qt.Key_Down) {
                    event.accepted = true;
                    if( searching || readySearch)
                        mainColumn.visibleGrid.tryActivate(0,0);
                    else if(viewDocuments)
                        documentsFavoritesGrid.tryActivate(0,0);
                    else
                        globalFavoritesGrid.tryActivate(0,0);

                } else if (event.key == Qt.Key_Tab) {
                    event.accepted = true;
                    if( searching || readySearch)
                        mainColumn.visibleGrid.tryActivate(0,0);
                    else
                        globalFavoritesGrid.tryActivate(0,0);
                } else if (event.key == Qt.Key_Backspace) {
                    event.accepted = true;
                    if(searching)
                        searchField.backspace();
                    //else
                    //    searchField.focus = true
                } else if (event.key == Qt.Key_Escape) {
                    event.accepted = true;
                    if(searching){
                        clear()
                    } else {
                        root.toggle()
                    }
                }
            }
        }

        Rectangle{
            height: 2
            width: searchField.width
            anchors.bottom: searchField.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            color: theme.highlightColor
        }

        PlasmaCore.IconItem {
            source: 'search'
            anchors {
                left: searchField.left
                verticalCenter: searchField.verticalCenter
                leftMargin: units.smallSpacing * 2

            }
            height: units.iconSizes.small
            width: height
        }

        //
        //
        //
        //

        RowLayout{
            id: topRow
            anchors.top: searchField.bottom
            anchors.topMargin: _margin
            width: tileSideWidth * plasmoid.configuration.numberColumns
            anchors.horizontalCenter: parent.horizontalCenter
            height: btnAction.implicitHeight

            PlasmaCore.IconItem {
                source: searching || readySearch ? 'application-menu' : 'favorite'
                implicitHeight: units.iconSizes.smallMedium
                implicitWidth: units.iconSizes.smallMedium
            }

            PlasmaExtras.Heading {
                id: headLabelFavorites
                color: colorWithAlpha(theme.textColor, 0.8)
                level: 5
                text: searching || readySearch ? i18n("Search results"): i18n("Pinned")
                Layout.leftMargin: units.smallSpacing
                font.weight: Font.Bold

            }

            Item{
                Layout.fillWidth: true
            }


            AToolButton {
                id: btnAction
                flat: false
                mirror: searching || readySearch
                iconName:  searching || readySearch ?  'go-previous' : "go-next"
                text:  searching || readySearch ?  i18n("Pinned") : i18n("All apps")
                onClicked:  {
                    if(readySearch || searching){
                        readySearch = false
                        searchField.text = ''
                    }
                    else{
                        readySearch = true
                        //searchField.focus = true
                    }
                }
            }

            states: [
                State {
                    name: "small"
                    when: !viewDocuments
                    PropertyChanges { target: topRow;  opacity: 1 }
                },
                State {
                    name: "large"
                    when: viewDocuments
                    PropertyChanges { target:topRow;  opacity: 0 }
                }
            ]
            transitions: Transition {
                OpacityAnimator{ duration: units.shortDuration*2 }
            }
        }

        //
        //
        //
        //


        Column{
            id: firstPage


            width:  tileSideWidth * plasmoid.configuration.numberColumns
            height: tileSideHeight * plasmoid.configuration.numberRows  + btnAction.implicitHeight + tileHeightDocuments * 3 + _margin

            anchors.top: topRow.bottom
            anchors.topMargin: _margin
            anchors.horizontalCenter: parent.horizontalCenter
            spacing:  _margin
            visible: !readySearch && !searching
            ItemGridView {
                id: globalFavoritesGrid
                width: tileSideWidth *  plasmoid.configuration.numberColumns
                height: tileSideHeight *  plasmoid.configuration.numberRows

                cellWidth:   tileSideWidth
                cellHeight:  tileSideHeight
                iconSize:    root.iconSizeSquare
                square: true
                model: globalFavorites
                dropEnabled: true
                usesPlasmaTheme: true
                verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                //visible: !viewDocuments
                state: 'small'

                onKeyNavDown: documentsFavoritesGrid.tryActivate(0,0)
                onKeyNavUp: searchField.focus = true

                onCurrentIndexChanged: {
                    preloadAllAppsTimer.defer();
                }

                states: [
                    State {
                        name: "small"
                        when: !viewDocuments
                        PropertyChanges { target: globalFavoritesGrid; height: tileSideHeight *  plasmoid.configuration.numberRows }

                    },
                    State {
                        name: "large"
                        when: viewDocuments
                        PropertyChanges { target:globalFavoritesGrid; height: 0 }
                    }
                ]
                transitions: Transition {
                    PropertyAnimation { property: "height"; duration: units.shortDuration*2;}
                }
                Keys.onPressed: {

                    if (event.key == Qt.Key_Tab) {
                        event.accepted = true;
                        documentsFavoritesGrid.tryActivate(0,0)
                    } else if (event.key == Qt.Key_Backspace) {
                        event.accepted = true;
                        if(searching)
                            searchField.backspace();
                        else
                            searchField.focus = true
                    } else if (event.key == Qt.Key_Escape) {
                        event.accepted = true;
                        if(searching){
                            searchField.clear()
                        } else {
                            root.toggle()
                        }
                    } else if (event.text != "") {
                        event.accepted = true;
                        searchField.appendText(event.text);
                    }
                }

            }

            RowLayout{
                width: parent.width
                height: btnAction.implicitHeight

                PlasmaCore.IconItem {
                    source: 'tag' // 'format-list-unordered'
                    implicitHeight: units.iconSizes.smallMedium
                    implicitWidth: units.iconSizes.smallMedium
                }

                PlasmaExtras.Heading {
                    id: headLabelDocuments
                    color: colorWithAlpha(theme.textColor, 0.8)
                    level: 5
                    text: i18n("Recommended")
                    Layout.leftMargin: units.smallSpacing
                    font.weight: Font.Bold
                }
                Item{
                    Layout.fillWidth: true
                }
                AToolButton {
                    flat: false
                    iconName:  viewDocuments ?  'go-previous' : "go-next"
                    mirror: viewDocuments
                    text:  viewDocuments ? i18n("Back") :  i18n("More")
                    onClicked:  viewDocuments = !viewDocuments
                }
            }

            ItemGridView3 {
                id: documentsFavoritesGrid
                width: parent.width
                height:  tileHeightDocuments * 3
                cellWidth:   Math.floor(parent.width * 0.5)
                cellHeight:  tileHeightDocuments
                square: false
                model:  rootModel.modelForRow(1)
                dropEnabled: true
                usesPlasmaTheme: false
                verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                state: 'small'
                onKeyNavUp: {
                    if (viewDocuments) searchField.focus = true
                    else  globalFavoritesGrid.tryActivate(0,0);
                }

                onCurrentIndexChanged: {
                    preloadAllAppsTimer.defer();
                }

                states: [
                    State {
                        name: "small"
                        when: !viewDocuments
                        PropertyChanges { target: documentsFavoritesGrid; height: tileHeightDocuments * 3 }
                    },
                    State {
                        name: "large"
                        when: viewDocuments
                        PropertyChanges { target:documentsFavoritesGrid; height:   (Math.floor(tileSideHeight * plasmoid.configuration.numberRows/tileHeightDocuments) + 3) * tileHeightDocuments }
                    }
                ]
                transitions: Transition {
                    PropertyAnimation { property: "height"; duration: units.shortDuration*2 }
                }

                Keys.onPressed: {

                    if (event.key == Qt.Key_Tab) {
                        event.accepted = true;
                        if (viewDocuments) searchField.focus = true
                        else  globalFavoritesGrid.tryActivate(0,0);

                    }  else if (event.key == Qt.Key_Backspace) {
                        event.accepted = true;
                        if(searching)
                            searchField.backspace();
                        else
                            searchField.focus = true
                    } else if (event.key == Qt.Key_Escape) {
                        event.accepted = true;
                        if(searching){
                            searchField.clear()
                        } else {
                            root.toggle()
                        }
                    } else if (event.text != "") {
                        event.accepted = true;
                        searchField.appendText(event.text);
                    }

                }
            }
            Item{
                Layout.fillHeight: true
            }

        }

        Item{
            anchors.top: topRow.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.fill: firstPage
            visible: searching || readySearch

            onVisibleChanged: {
                if(visible) animation2.start()
            }

            Item {
                id: mainColumn
                width: parent.width
                height: parent.height
                anchors {
                    top: parent.top
                    topMargin: units.smallSpacing
                }
                property Item visibleGrid: allAppsGrid

                function tryActivate(row, col) {
                    if (visibleGrid) {
                        visibleGrid.tryActivate(row, col);
                    }
                }

                ItemMultiGridView {
                    id: allAppsGrid
                    anchors.top: parent.top
                    z: (opacity == 1.0) ? 1 : 0
                    width:  parent.width
                    height: parent.height
                    enabled: (opacity == 1.0) ? 1 : 0
                    opacity: searching ? 0 : 1
                    aCellWidth: parent.width - units.largeSpacing
                    aCellHeight: iconSize + units.smallSpacing*2
                    model: rootModel.modelForRow(2);
                    onOpacityChanged: {
                        if (opacity == 1.0) {
                            allAppsGrid.flickableItem.contentY = 0;
                            mainColumn.visibleGrid = allAppsGrid;
                        }
                    }
                    onKeyNavRight: globalFavoritesGrid.tryActivate(0,0)

                }

                ItemMultiGridView {
                    id: runnerGrid
                    anchors.fill: parent
                    z: (opacity == 1.0) ? 1 : 0
                    aCellWidth: parent.width - units.largeSpacing
                    aCellHeight: iconSize + units.smallSpacing * 2

                    enabled: (opacity == 1.0) ? 1 : 0
                    isSquare: false
                    model: runnerModel
                    grabFocus: true
                    opacity: searching ? 1.0 : 0.0
                    onOpacityChanged: {
                        if (opacity == 1.0) {
                            mainColumn.visibleGrid = runnerGrid;
                        }
                    }
                    onKeyNavRight: globalFavoritesGrid.tryActivate(0,0)
                }



                Keys.onPressed: {
                    if (event.key == Qt.Key_Tab) {
                        event.accepted = true;
                        globalFavoritesGrid.tryActivate(0,0)
                    } else if (event.key == Qt.Key_Backspace) {
                        event.accepted = true;
                        if(searching)
                            searchField.backspace();
                        else
                            searchField.focus = true
                    } else if (event.key == Qt.Key_Escape) {
                        event.accepted = true;
                        if(searching){
                            searchField.clear()
                        } else {
                            root.toggle()
                        }
                    } else if (event.text != "") {
                        event.accepted = true;
                        searchField.appendText(event.text);
                    }
                }

            }

        }


        Rectangle{
            id: footer
            width: parent.width + backgroundSvg.margins.right + backgroundSvg.margins.left
            height: units.gridUnit * 3
            x: - backgroundSvg.margins.left
            y: parent.height - height + backgroundSvg.margins.bottom
            color: colorWithAlpha(theme.textColor,0.05)

            Footer{
                anchors.fill: parent
                anchors.leftMargin: _margin*2
                anchors.rightMargin: _margin*2
            }

            Rectangle{
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: theme.textColor
                opacity: 0.15
                z:2
            }

        }

        Keys.onPressed: {
            if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                root.toggle()
            }
        }
    }

    Component.onCompleted: {
        rootModel.refreshed.connect(reset)
        kicker.reset.connect(reset);
        reset();
    }
}

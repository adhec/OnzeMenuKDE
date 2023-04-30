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
    location: plasmoid.configuration.pullupAnimation ? PlasmaCore.Types.BottomEdge : PlasmaCore.Types.Floating
    hideOnWindowDeactivate: true

    property int defaultSize: {
        switch(plasmoid.configuration.defaultSize){
        case "SmallMedium": return PlasmaCore.Units.iconSizes.smallMedium;
        case "Medium":      return PlasmaCore.Units.iconSizes.medium;
        case "Large":       return PlasmaCore.Units.iconSizes.large;
        case "Huge":        return PlasmaCore.Units.iconSizes.huge;
        default: return 64
        }
    }

    property int iconSize:       defaultSize
    property int iconSizeSquare: defaultSize
    property int tileSideHeight: defaultSize + theme.mSize(theme.defaultFont).height * 2
                                 + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                                 highlightItemSvg.margins.left + highlightItemSvg.margins.right))

    property int tileSideWidth: tileSideHeight + PlasmaCore.Units.smallSpacing*2

    property int tileHeightDocuments: PlasmaCore.Units.gridUnit * 2 + PlasmaCore.Units.smallSpacing * 4

    property bool searching: (searchField.text != "")
    property bool readySearch: false
    property bool viewDocuments: false

    property int _margin: iconSizeSquare > 33 ? PlasmaCore.Units.largeSpacing  : PlasmaCore.Units.largeSpacing * 0.5

    property bool mainViewVisible: !searching && !readySearch

    onVisibleChanged: {
        reset()
        if (visible) {
            var pos = popupPosition(width, height);
            x = pos.x;
            y = pos.y;
            requestActivate();
            if(!plasmoid.configuration.pullupAnimation)
                animation1.start()
        }else{
            //focusScope.opacity = 0
            //focusScope.y = 250
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
            if(readySearch)
                readySearch = false
        }
    }

    function colorWithAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }



    function reset() {
        globalFavoritesGrid.tryActivate(0,0)
        searchField.clear();
        readySearch = false
        viewDocuments = false
    }

    function setModels(){
        allAppsGrid.model = rootModel.modelForRow(2)
        documentsFavoritesGrid.model = rootModel.modelForRow(1)
    }

    function toggle(){
        root.visible = !root.visible;
    }

    function popupPosition(width, height) {
        var screenAvail = plasmoid.availableScreenRect;
        var screenGeom = plasmoid.screenGeometry;
        var screen = Qt.rect(screenAvail.x + screenGeom.x,
                             screenAvail.y + screenGeom.y,
                             screenAvail.width,
                             screenAvail.height);


        var offset = PlasmaCore.Units.smallSpacing;

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
            y = screen.y + screen.height - height - offset - panelSvg.margins.top;
        } else if (plasmoid.location === PlasmaCore.Types.BottomEdge) {
            horizMidPoint = screen.x + (screen.width / 2);
            appletTopLeft = parent.mapToGlobal(0, 0);
            x = (appletTopLeft.x < horizMidPoint) ? screen.x + offset : (screen.x + screen.width) - width - offset;
            y = screen.y + screen.height - height - offset - panelSvg.margins.top;
        } else if (plasmoid.location === PlasmaCore.Types.TopEdge) {
            horizMidPoint = screen.x + (screen.width / 2);
            var appletBottomLeft = parent.mapToGlobal(0, parent.height);
            x = (appletBottomLeft.x < horizMidPoint) ? screen.x + offset : (screen.x + screen.width) - width - offset;
            y = screen.y + parent.height + panelSvg.margins.bottom + offset;
        } else if (plasmoid.location === PlasmaCore.Types.LeftEdge) {
            vertMidPoint = screen.y + (screen.height / 2);
            appletTopLeft = parent.mapToGlobal(0, 0);
            x = parent.width + panelSvg.margins.right + offset;
            y = screen.y + (appletTopLeft.y < vertMidPoint) ? screen.y + offset : (screen.y + screen.height) - height - offset;
        } else if (plasmoid.location === PlasmaCore.Types.RightEdge) {
            vertMidPoint = screen.y + (screen.height / 2);
            appletTopLeft = parent.mapToGlobal(0, 0);
            x = appletTopLeft.x - panelSvg.margins.left - offset - width;
            y = screen.y + (appletTopLeft.y < vertMidPoint) ? screen.y + offset : (screen.y + screen.height) - height - offset;
        }

        return Qt.point(x, y);
    }

    FocusScope {

        id: focusScope

        Layout.maximumWidth:  (tileSideWidth *  plasmoid.configuration.numberColumns) + _margin * 2
        Layout.minimumWidth:  (tileSideWidth *  plasmoid.configuration.numberColumns) + _margin * 2

        Layout.minimumHeight: searchField.implicitHeight + topRow.height +  firstPage.height + footer.height + _margin * 5
        Layout.maximumHeight:  Layout.minimumHeight

        property bool done: false

        ScaleAnimator{id: animation1 ; target: focusScope ; from: 0.8; to: 1; duration: PlasmaCore.Units.shortDuration*3; easing.type: Easing.OutBack}

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

        PlasmaComponents3.TextField {
            id: searchField
            anchors.top: parent.top
            anchors.margins: _margin
            anchors.horizontalCenter: parent.horizontalCenter
            focus: true
            width: tileSideWidth * plasmoid.configuration.numberColumns
            implicitHeight: PlasmaCore.Units.gridUnit * 2
            placeholderText: i18n("Type here to search ...")
            placeholderTextColor: colorWithAlpha(theme.textColor,0.7)
            leftPadding: PlasmaCore.Units.largeSpacing + PlasmaCore.Units.iconSizes.small
            topPadding: PlasmaCore.Units.gridUnit * 0.5
            verticalAlignment: Text.AlignTop
            background: Rectangle {
                color: theme.backgroundColor
                radius: 3
                border.width: 1
                border.color: colorWithAlpha(theme.textColor,0.05)
            }
            onTextChanged: runnerModel.query = text;

            function clear() {
                text = "";
            }
            function backspace() {
                //focus = true;
                if(searching) text = text.slice(0, -1);
            }
            function appendText(newText) {
                if (!root.visible) {
                    return;
                }
                //focus = true;
                text = text + newText;
            }
            Keys.onPressed: {
                if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                    event.accepted = true;
                    if( searching || readySearch)
                        mainColumn.visibleGrid.tryActivate(0,0);
                    else if(viewDocuments)
                        documentsFavoritesGrid.tryActivate(0,0);
                    else
                        globalFavoritesGrid.tryActivate(0,0);
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
                leftMargin: PlasmaCore.Units.smallSpacing * 2

            }
            height: PlasmaCore.Units.iconSizes.small
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
                implicitHeight: PlasmaCore.Units.iconSizes.smallMedium
                implicitWidth: PlasmaCore.Units.iconSizes.smallMedium
            }

            PlasmaExtras.Heading {
                id: headLabelFavorites
                color: colorWithAlpha(theme.textColor, 0.8)
                level: 5
                text: searching || readySearch ? i18n("Search results"): i18n("Pinned")
                Layout.leftMargin: PlasmaCore.Units.smallSpacing
                font.weight: Font.Bold

            }

            Item{
                Layout.fillWidth: true
            }


            AToolButton {
                id: btnAction
                flat: false
                mirror: !mainViewVisible
                iconName:  mainViewVisible ?  "go-next" : 'go-previous'
                text:  mainViewVisible ? i18n("All apps") :  i18n("Pinned")
                onClicked:  {
                    if(mainViewVisible){
                        readySearch = true
                        //searchField.focus = true
                    }
                    else{
                        readySearch = false
                        searchField.text = ''
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
                OpacityAnimator{ duration: PlasmaCore.Units.shortDuration*2 }
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
            //anchors.horizontalCenter: parent.horizontalCenter
            spacing:  _margin
            //visible: mainViewVisible


            state: 'visible'
            states: [
                State {
                    name: "hidden"
                    when: !mainViewVisible
                    PropertyChanges { target: firstPage ; opacity: 0}
                    PropertyChanges { target: firstPage ; x: -firstPage.width}
                    PropertyChanges { target: firstPage ; visible: 0}
                },
                State {
                    name: "visible"
                    when: mainViewVisible
                    PropertyChanges { target: firstPage ; visible: 1}
                    PropertyChanges { target: firstPage ; opacity: 1}
                    PropertyChanges { target: firstPage ; x: _margin }
                }
            ]

            transitions: [

                Transition {
                    from: "hidden"
                    to: "visible"
                    NumberAnimation {
                        properties: "opacity,x"
                        duration: PlasmaCore.Units.shortDuration*2
                    }
                },
                Transition {
                    from: "visible"
                    to: "hidden"
                    SequentialAnimation {
                        PropertyAction {
                            target: firstPage;
                            property: "visible"
                            value: true
                        }
                        PropertyAnimation {
                            target: firstPage
                            properties: "opacity,x"
                            duration: PlasmaCore.Units.shortDuration*2
                        }
                    }

                }
            ]




            ItemGridView {
                id: globalFavoritesGrid
                width: tileSideWidth *  plasmoid.configuration.numberColumns
                height: tileSideHeight *  plasmoid.configuration.numberRows

                cellWidth:   tileSideWidth
                cellHeight:  tileSideHeight
                iconSize:    root.iconSizeSquare
                square: true
                model: plasmoid.configuration.showRecentApps ?  rootModel.modelForRow(0) : rootModel.favoritesModel
                dropEnabled: true
                usesPlasmaTheme: true
                verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                state: 'small'

                onKeyNavDown: documentsFavoritesGrid.tryActivate(0,0)
                onKeyNavUp: searchField.focus = true

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
                    PropertyAnimation { property: "height"; duration: PlasmaCore.Units.shortDuration*2;}
                }
                Keys.onPressed: {
                    if(event.modifiers & Qt.ControlModifier ||event.modifiers & Qt.ShiftModifier){
                        searchField.focus = true;
                        return
                    }

                    if (event.key === Qt.Key_Tab) {
                        event.accepted = true;
                        documentsFavoritesGrid.tryActivate(0,0)
                    } else if (event.key === Qt.Key_Backspace) {
                        event.accepted = true;
                        if(searching)
                            searchField.backspace();
                        else
                            searchField.focus = true
                    } else if (event.key === Qt.Key_Escape) {
                        event.accepted = true;
                        if(searching){
                            searchField.clear()
                        } else {
                            root.toggle()
                        }
                    } else if (event.text !== "") {
                        event.accepted = true;
                        searchField.appendText(event.text);
                    }
                }

            }

            RowLayout{
                width: parent.width
                height: btnAction.implicitHeight

                PlasmaCore.IconItem {
                    source: plasmoid.configuration.hideRecentDocs ? 'clock' : 'tag'
                    implicitHeight: PlasmaCore.Units.iconSizes.smallMedium
                    implicitWidth: PlasmaCore.Units.iconSizes.smallMedium
                }

                PlasmaExtras.Heading {
                    id: headLabelDocuments
                    color: colorWithAlpha(theme.textColor, 0.8)
                    level: 5
                    text: plasmoid.configuration.hideRecentDocs ?  i18n("Date and time") :  i18n("Recommended")
                    Layout.leftMargin: PlasmaCore.Units.smallSpacing
                    font.weight: Font.Bold
                }
                Item{
                    Layout.fillWidth: true
                }
                AToolButton {
                    visible: !plasmoid.configuration.hideRecentDocs
                    flat: false
                    iconName:  viewDocuments ?  'go-previous' : "go-next"
                    mirror: viewDocuments
                    text:  viewDocuments ? i18n("Back") :  i18n("More")
                    onClicked:  viewDocuments = !viewDocuments
                }
            }

            Clock{
                width: parent.width
                height:  tileHeightDocuments * 3
                visible: plasmoid.configuration.hideRecentDocs
            }
            ItemGridView3 {
                id: documentsFavoritesGrid
                visible: !plasmoid.configuration.hideRecentDocs
                width: parent.width
                height:  tileHeightDocuments * 3
                cellWidth:   Math.floor(parent.width * 0.5)
                cellHeight:  tileHeightDocuments
                square: false
                dropEnabled: true
                usesPlasmaTheme: false
                verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                state: 'small'
                onKeyNavUp: {
                    if (viewDocuments) searchField.focus = true
                    else  globalFavoritesGrid.tryActivate(0,0);
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
                    PropertyAnimation { property: "height"; duration: PlasmaCore.Units.shortDuration*2 }
                }

                Keys.onPressed: {
                    if(event.modifiers & Qt.ControlModifier ||event.modifiers & Qt.ShiftModifier){
                        searchField.focus = true;
                        return
                    }

                    if (event.key === Qt.Key_Tab) {
                        event.accepted = true;
                        if (viewDocuments) searchField.focus = true
                        else  globalFavoritesGrid.tryActivate(0,0);

                    }  else if (event.key === Qt.Key_Backspace) {
                        event.accepted = true;
                        if(searching)
                            searchField.backspace();
                        else
                            searchField.focus = true
                    } else if (event.key === Qt.Key_Escape) {
                        event.accepted = true;
                        if(searching){
                            searchField.clear()
                        } else {
                            root.toggle()
                        }
                    } else if (event.text !== "") {
                        event.accepted = true;
                        searchField.appendText(event.text);
                    }

                }
            }
            Item{
                Layout.fillHeight: true
            }

        }

        //
        //
        //
        //

        Item{
            id: mainLists
            anchors.top: topRow.bottom
            anchors.topMargin: _margin
            width:  tileSideWidth * plasmoid.configuration.numberColumns
            height: tileSideHeight * plasmoid.configuration.numberRows  + btnAction.implicitHeight + tileHeightDocuments * 3 + _margin

            state: 'hidden'
            states: [
                State {
                    name: "hidden"
                    when: mainViewVisible
                    PropertyChanges { target: mainLists ; opacity: 0}
                    PropertyChanges { target: mainLists ; x: mainLists.width}
                    PropertyChanges { target: mainLists ; visible: 0}
                },
                State {
                    name: "visible"
                    when: !mainViewVisible
                    PropertyChanges { target: mainLists ; visible: 1}
                    PropertyChanges { target: mainLists ; opacity: 1}
                    PropertyChanges { target: mainLists ; x: _margin }
                }
            ]

            transitions: [

                Transition {
                    from: "hidden"
                    to: "visible"
                    NumberAnimation {
                        properties: "opacity,x"
                        duration: PlasmaCore.Units.shortDuration*2

                    }
                },
                Transition {
                    from: "visible"
                    to: "hidden"
                    SequentialAnimation {
                        PropertyAction {
                            target: mainLists;
                            property: "visible"
                            value: true
                        }
                        PropertyAnimation {
                            target: mainLists
                            properties: "opacity,x"
                        }
                    }

                }
            ]


            Item {
                id: mainColumn
                width: parent.width
                height: parent.height
                anchors {
                    top: parent.top
                    topMargin: PlasmaCore.Units.smallSpacing
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
                    aCellWidth: parent.width - PlasmaCore.Units.largeSpacing
                    aCellHeight: iconSize + PlasmaCore.Units.smallSpacing*2
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
                    aCellWidth: parent.width - PlasmaCore.Units.largeSpacing
                    aCellHeight: iconSize + PlasmaCore.Units.smallSpacing * 2

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
                    if(event.modifiers & Qt.ControlModifier ||event.modifiers & Qt.ShiftModifier){
                        searchField.focus = true;
                        return
                    }

                    if (event.key === Qt.Key_Tab) {
                        event.accepted = true;
                        globalFavoritesGrid.tryActivate(0,0)
                    } else if (event.key === Qt.Key_Backspace) {
                        event.accepted = true;
                        if(searching)
                            searchField.backspace();
                        else
                            searchField.focus = true
                    } else if (event.key === Qt.Key_Escape) {
                        event.accepted = true;
                        if(searching){
                            searchField.clear()
                        } else {
                            root.toggle()
                        }
                    } else if (event.text !== "") {
                        event.accepted = true;
                        searchField.appendText(event.text);
                    }
                }

            }

        }

        //
        //
        //
        //

        Rectangle{
            id: footer
            width: parent.width + backgroundSvg.margins.right + backgroundSvg.margins.left
            height: root.iconSizeSquare + PlasmaCore.Units.smallSpacing*4 // PlasmaCore.Units.gridUnit * 3
            x: - backgroundSvg.margins.left
            y: parent.height - height + backgroundSvg.margins.bottom
            color: colorWithAlpha(theme.textColor,0.05)

            Footer{
                anchors.fill: parent
                anchors.leftMargin: _margin
                anchors.rightMargin: _margin
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
        rootModel.refreshed.connect(setModels)
        reset();
        rootModel.refresh();
    }
}


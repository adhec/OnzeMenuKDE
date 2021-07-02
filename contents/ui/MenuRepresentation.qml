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
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.plasma.extras 2.0 as PlasmaExtras

import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.kcoreaddons 1.0 as KCoreAddons // kuser
import org.kde.plasma.private.shell 2.0

import org.kde.kwindowsystem 1.0
import QtGraphicalEffects 1.0
import org.kde.kquickcontrolsaddons 2.0

import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.private.quicklaunch 1.0

PlasmaCore.Dialog {
    id: root

    objectName: "popupWindow"
    flags: Qt.WindowStaysOnTopHint
    location: PlasmaCore.Types.Floating
    hideOnWindowDeactivate: true

    property int iconSize: units.iconSizes.medium

    property int cellSizeWidth: iconSize + theme.mSize(theme.defaultFont).height
                           + units.largeSpacing * 2.5
                           + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                           highlightItemSvg.margins.left + highlightItemSvg.margins.right))

    property int cellSizeHeight: iconSize + theme.mSize(theme.defaultFont).height
                           + units.largeSpacing * 2
                           + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                           highlightItemSvg.margins.left + highlightItemSvg.margins.right))

    property bool searching: (searchField.text != "")
    property bool readySearch: false


    onVisibleChanged: {
        reset();
        if (visible) {
            var pos = popupPosition(width, height);
            x = pos.x;
            y = pos.y;
            requestActivate();
            reset();
            animation1.start()
            readySearch = false
            preloadAllAppsTimer.restart();

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
        }
    }


    function reset() {
        searchField.text = "";
        gridViewFavorites.tryActivate(0,0)
    }

    function reload(){
        allAppsGrid.model = null
        preloadAllAppsTime.done = false
        preloadAllAppsTime.defer()
    }

    function toggle(){
        root.visible = !visible
    }


    function popupPosition(width, height) {
        var screenAvail = plasmoid.availableScreenRect;
        var screenGeom = plasmoid.screenGeometry;

        var screen = Qt.rect(screenAvail.x + screenGeom.x,
                             screenAvail.y + screenGeom.y,
                             screenAvail.width,
                             screenAvail.height);


        var offset = units.largeSpacing/2;

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
        Layout.minimumWidth:  (cellSizeWidth *  plasmoid.configuration.numberColumns) +  units.largeSpacing * 2
        Layout.maximumWidth:  (cellSizeWidth *  plasmoid.configuration.numberColumns) +  units.largeSpacing * 2
        Layout.minimumHeight: (cellSizeHeight *  plasmoid.configuration.numberRows) + topRow.height  + bottomRow.height +  units.largeSpacing * 7 + documentsFavoritesGrid.height + headLabelDocuments.height
        Layout.maximumHeight: (cellSizeHeight *  plasmoid.configuration.numberRows) + topRow.height  + bottomRow.height +  units.largeSpacing * 7 + documentsFavoritesGrid.height + headLabelDocuments.height

        focus: true

        KCoreAddons.KUser {   id: kuser  }
        Logic {   id: logic }

        OpacityAnimator { id: animation1; target: focusScope; from: 0; to: 1; }

        PlasmaCore.DataSource {
            id: pmEngine
            engine: "powermanagement"
            connectedSources: ["PowerDevil", "Sleep States"]
            function performOperation(what) {
                var service = serviceForSource("PowerDevil")
                var operation = service.operationDescription(what)
                service.startOperationCall(operation)
            }
        }

        PlasmaCore.DataSource {
            id: executable
            engine: "executable"
            connectedSources: []
            onNewData: {
                var exitCode = data["exit code"]
                var exitStatus = data["exit status"]
                var stdout = data["stdout"]
                var stderr = data["stderr"]
                exited(sourceName, exitCode, exitStatus, stdout, stderr)
                disconnectSource(sourceName)
            }
            function exec(cmd) {
                if (cmd) {
                    connectSource(cmd)
                }
            }
            signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)
        }

        PlasmaComponents.Highlight {
            id: delegateHighlight
            visible: false
            z: -1 // otherwise it shows ontop of the icon/label and tints them slightly
        }

        PlasmaExtras.Heading {
            id: dummyHeading
            visible: false
            width: 0
            level: 5
        }

        TextMetrics {
            id: headingMetrics
            font: dummyHeading.font
        }

        ActionMenu {
            id: actionMenu
            onActionClicked: visualParent.actionTriggered(actionId, actionArgument)
            onClosed: {
                if (pageList.currentItem) {
                    pageList.currentItem.itemGrid.currentIndex = -1;
                }
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
                        documentsFavoritesGrid.model = rootModel.modelForRow(1);
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

        RowLayout{
            id: topRow
            height: units.gridUnit * 2
            anchors{
                top: parent.top
                left: parent.left
                right: parent.right
                margins: units.largeSpacing
                bottomMargin: 0
            }

            PlasmaExtras.Heading {
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                color: theme.textColor
                level: 5
                font.bold: true
                font.weight: Font.Bold
                text: "Pinned"
                visible: !searching && !readySearch
            }

            Item{
                Layout.fillWidth: true
            }

            PlasmaComponents.TextField {
                id: searchField
                visible: searching || readySearch

                Layout.fillWidth: true
                placeholderText: i18n("Search ...")
                //font.pointSize: 14 // fixme: QTBUG font size in plasmaComponent3
                text: ""
                onTextChanged: {
                    runnerModel.query = text;
                }

                Keys.onPressed: {
                    if (event.key == Qt.Key_Down) {
                        event.accepted = true;
                        mainScrollArea.tryActivate(0, 0);
                    } else if (event.key == Qt.Key_Return || event.key == Qt.Key_Enter) {
                        if (text != "" && mainScrollArea.visibleGrid.count > 0) {
                            event.accepted = true;
                            //pageList.currentItem.itemGrid.tryActivate(0, 0);
                            //pageList.currentItem.itemGrid.model.trigger(0, "", null);

                            mainScrollArea.tryActivate(0, 0);
                            mainScrollArea.visibleGrid.itemGrid.model.trigger(0, "", null);

                            root.visible = false;

                        }
                    } else if (event.key == Qt.Key_Tab) {
                        event.accepted = true;
                        mainScrollArea.tryActivate(0, 0);
                    } else if (event.key == Qt.Key_Backtab) {
                        event.accepted = true;
                        if (!searching) {
                            readySearch = false;
                        }
                    }
                }

                function backspace() {
                    if (!root.visible || !searching) {
                        return;
                    }
                    focus = true;
                    text = text.slice(0, -1);
                }

                function appendText(newText) {
                    if (!root.visible) {
                        return;
                    }
                    focus = true;
                    text = text + newText;
                }
            }


            PlasmaComponents3.ToolButton {
                id: btnAction
                flat: false
                icon.name:  searching || readySearch ?  'go-previous' : "go-next"
                text:  searching || readySearch ?  'Pinned' : 'All apps'
                onClicked:  {
                    if(readySearch || searching){
                        readySearch = false
                        searchField.text = ''
                    }
                    else{
                        readySearch = true
                        searchField.focus = true
                    }
                }
            }
        }


        Item{
            id: mainScrollArea

            anchors {
                top: topRow.bottom
                left: parent.left
                right: parent.right
                margins: units.largeSpacing
                bottomMargin: 0
            }

            width: (cellSizeWidth * plasmoid.configuration.numberColumns)
            height: cellSizeHeight * (plasmoid.configuration.numberRows + 2)
            visible: searching || readySearch
            property Item visibleGrid: allAppsGrid

            function tryActivate(row, col) {
                if (visibleGrid) {
                    visibleGrid.tryActivate(row, col);
                }
            }



            ItemMultiGridView {
                id: allAppsGrid
                anchors.fill: parent
                enabled: (opacity == 1.0) ? 1 : 0
                opacity: readySearch && !searching ? 1 : 0
                model: rootModel.modelForRow(2);
                onOpacityChanged: {
                    if (opacity == 1.0) {
                        allAppsGrid.flickableItem.contentY = 0;
                        mainScrollArea.visibleGrid = allAppsGrid;
                    }
                }

            }

            ItemMultiGridView {
                id: runnerGrid
                anchors.top: parent.top
                width:  parent.width
                height: Math.min(implicitHeight, parent.height)
                enabled: (opacity == 1.0) ? 1 : 0
                model: runnerModel
                grabFocus: true
                opacity: searching ? 1.0 : 0.0
                onOpacityChanged: {
                    if (opacity == 1.0) {
                        mainScrollArea.visibleGrid = runnerGrid;
                    }
                }
                onKeyNavRight: globalFavoritesGrid.tryActivate(0,0)
            }

        }




        ItemGridView {
            id: gridViewFavorites

            anchors {
                top: topRow.bottom
                left: parent.left
                right: parent.right
                margins: units.largeSpacing
                bottomMargin: 0
            }

            focus: true
            width: cellSizeWidth * plasmoid.configuration.numberColumns
            height: cellSizeHeight * plasmoid.configuration.numberRows

            usesPlasmaTheme: false
            cellWidth: cellSizeWidth
            cellHeight: cellSizeHeight
            square: true
            iconSize: units.iconSizes.large

            visible: !(searching  || readySearch)
            horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
            verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

            dragEnabled: false
            model: globalFavorites

            onKeyNavDown: {
                documentsFavoritesGrid.tryActivate(0,0)
            }

            Keys.onPressed: {
                if (event.key == Qt.Key_Backspace) {
                    event.accepted = true;
                    searchField.backspace();
                } else if (event.key == Qt.Key_Tab) {
                    event.accepted = true;
                    documentsFavoritesGrid.tryActivate(0,0);
                } else if (event.key == Qt.Key_Escape) {
                    event.accepted = true;
                    if(searching){
                        searchField.clear()
                    } else {
                        root.visible = false;
                    }
                } else if (event.text != "") {
                    event.accepted = true;
                    searchField.appendText(event.text);
                }

            }
        }

        PlasmaExtras.Heading {
            id: headLabelDocuments
            anchors {
                margins: units.largeSpacing
                left: parent.left
                bottom: documentsFavoritesGrid.top
            }
            color: theme.textColor
            level: 5
            visible: !readySearch && !searching
            font.bold: true
            font.weight: Font.Bold
            text:  "Recent " + '(' + documentsFavoritesGrid.model.count + ')'
        }


        ItemGridView {
            id: documentsFavoritesGrid
            property int rows: 3
            anchors{
                left: parent.left
                right: parent.right
                margins: units.largeSpacing
                bottom: divider.top
            }
            //width: cellSize * plasmoid.configuration.numberColumns
            height: (units.iconSizes.medium + units.smallSpacing * 2) * 3
            cellWidth:    parent.width * 0.46
            cellHeight:   units.iconSizes.medium + units.smallSpacing * 2
            iconSize:    units.iconSizes.medium

            verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff
            model: rootModel.modelForRow(1);
            usesPlasmaTheme: false
            dragEnabled: false
            visible: !readySearch && !searching

            onKeyNavUp: {
                gridViewFavorites.tryActivate(0,0)
            }


            Keys.onPressed: {
                if (event.key == Qt.Key_Backspace) {
                    event.accepted = true;
                    searchField.backspace();
                } else  if (event.key == Qt.Key_Tab) {
                    event.accepted = true;
                    gridViewFavorites.tryActivate(0,0);
                } else if (event.key == Qt.Key_Escape) {
                    event.accepted = true;
                    if(searching){
                        searchField.clear()
                    } else {
                        root.visible = false;
                    }
                } else if (event.text != "") {
                    event.accepted = true;
                    searchField.appendText(event.text);
                }
            }
        }

        Rectangle{
            id: divider
            anchors{
                left: parent.left
                right: parent.right
                bottom: bottomRow.top
                margins: units.largeSpacing

            }
            color: theme.textColor
            height: 1
            opacity: 0.2
        }

        RowLayout{
            id: bottomRow
            height: units.gridUnit * 3
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: units.largeSpacing
                rightMargin:  units.largeSpacing
                bottomMargin: units.smallSpacing
            }
            spacing: 16

            Image {
                id: iconUser
                source: kuser.faceIconUrl.toString() || "user-identity"
                cache: false
                visible: source !== ""
                height: units.gridUnit * 3
                width: height
                sourceSize.width: width
                sourceSize.height: height
                fillMode: Image.PreserveAspectFit

                // Crop the avatar to fit in a circle, like the lock and login screens
                // but don't on software rendering where this won't render
                layer.enabled:true // iconUser.GraphicsInfo.api !== GraphicsInfo.Software
                layer.effect: OpacityMask {
                    // this Rectangle is a circle due to radius size
                    maskSource: Rectangle {
                        width: iconUser.width
                        height: iconUser.height
                        radius: height / 2
                        visible: false
                    }
                }
            }

            PlasmaExtras.Heading {

                wrapMode: Text.NoWrap
                color: theme.textColor
                level: 3
                font.bold: true
                font.weight: Font.Bold
                text: qsTr(kuser.fullName)
            }



            Item{
                Layout.fillWidth: true
            }

            ListDelegate {
                id: iconMenu
                text: "System Preferences"
                highlight: delegateHighlight
                icon: "configure"
                size: units.iconSizes.smallMedium
                onClicked: logic.openUrl("file:///usr/share/applications/systemsettings.desktop")
            }

            ListDelegate {
                text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Leave ... ")
                highlight: delegateHighlight
                icon: "system-lock-screen"
                size: units.iconSizes.smallMedium
                onClicked: pmEngine.performOperation("lockScreen")
            }

            ListDelegate {
                text: i18nc("@action", "Lock Screen")
                icon: "system-shutdown"
                highlight: delegateHighlight
                enabled: pmEngine.data["Sleep States"]["LockScreen"]
                size: units.iconSizes.smallMedium
                onClicked: pmEngine.performOperation("requestShutDown")
            }
        }

        Keys.onPressed: {
            if (event.key == Qt.Key_Escape) {
                event.accepted = true;
                if (searching) {
                    reset();
                } else {
                    root.visible = false;
                }
                return;
            }

            if (searchField.focus) {
                return;
            }

            if (event.key == Qt.Key_Backspace) {
                event.accepted = true;
                searchField.backspace();
            } else if (event.key == Qt.Key_Tab || event.key == Qt.Key_Backtab) {
                gridViewFavorites.tryActivate(0, 0);
            } else if (event.text != "") {
                event.accepted = true;
                searchField.appendText(event.text);
            }
        }

    }

    function refreshModel() {
        reload()
    }

    Component.onCompleted: {
        rootModel.refreshed.connect(refreshModel)
        kicker.reset.connect(reset);
        reset();
    }
}

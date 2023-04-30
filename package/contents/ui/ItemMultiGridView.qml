/***************************************************************************
 *   Copyright (C) 2015 by Eike Hein <hein@kde.org>                        *
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

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras

import org.kde.plasma.private.kicker 0.1 as Kicker

PlasmaExtras.ScrollArea {
    id: itemMultiGrid
    anchors.fill: parent
    implicitHeight: itemColumn.implicitHeight

    signal keyNavLeft(int subGridIndex)
    signal keyNavRight(int subGridIndex)
    signal keyNavUp()
    signal keyNavDown()

    property bool grabFocus: false

    property alias model: repeater.model
    property alias count: repeater.count
    property bool isSquare: false
    property int aCellHeight
    property int aCellWidth

    verticalScrollBarPolicy: Qt.ScrollBarAsNeeded
    horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff

    flickableItem.flickableDirection: Flickable.VerticalFlick

    onFocusChanged: {
        if (!focus) {
            for (var i = 0; i < repeater.count; i++) {
                subGridAt(i).focus = false;
            }
        }
    }

    function subGridAt(index) {
        return repeater.itemAt(index).itemGrid;
    }

    function tryActivate(row, col) { // FIXME TODO: Cleanup messy algo.
        console.log("on try activate multigrid")
        if (flickableItem.contentY > 0) {
            row = 0;
        }

        var target = null;
        var rows = 0;

        for (var i = 0; i < repeater.count; i++) {
            var grid = subGridAt(i);

            if (rows <= row) {
                target = grid;
                rows += grid.lastRow() + 2; // Header counts as one.
            } else {
                break;
            }
        }

        if (target) {
            rows -= (target.lastRow() + 2);
            target.tryActivate(row - rows, col);
        }
    }

    Column {
        id: itemColumn

        width: itemMultiGrid.width //- PlasmaCore.Units.gridUnit

        Repeater {
            id: repeater

            delegate: Item {
                width: itemColumn.width
                height:  gridViewLabel.height + gridView.height + (index == repeater.count - 1 ? 0 : PlasmaCore.Units.smallSpacing)
                //visible:  gridView.count > 0

                property Item itemGrid: gridView

                PlasmaExtras.Heading {
                    id: gridViewLabel
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.leftMargin: PlasmaCore.Units.smallSpacing
                    height: dummyHeading.height
                    wrapMode: Text.NoWrap
                    color: theme.textColor
                    font.bold: true
                    font.weight: Font.DemiBold
                    level: 5
                    verticalAlignment: Qt.AlignVCenter
                    text: repeater.model.modelForRow(index) ? repeater.model.modelForRow(index).description : ""
                }

                Rectangle{
                    anchors.right: parent.right
                    anchors.verticalCenter: gridViewLabel.verticalCenter
                    height: 1
                    width: parent.width - gridViewLabel.implicitWidth - PlasmaCore.Units.largeSpacing*2
                    color: theme.textColor
                    opacity: 0.15
                }

                MouseArea {
                    width: parent.width
                    height: parent.height
                    onClicked: root.toggle()
                }

                ItemGridView {
                    id: gridView

                    anchors {
                        top: gridViewLabel.bottom
                        topMargin: PlasmaCore.Units.smallSpacing
                    }

                    width: parent.width
                    //height: Math.ceil(count / Math.floor(width / root.tileSide)) * root.tileSide
                    height: gridView.count ? gridView.count * aCellHeight : 0

                    cellWidth:  isSquare ? root.tileSide : aCellWidth
                    cellHeight: isSquare ? root.tileSide : aCellHeight
                    iconSize: root.iconSize
                    square: isSquare
                    verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

                    model: repeater.model.modelForRow(index)

                    onFocusChanged: {
                        if (focus) {
                            itemMultiGrid.focus = true;
                        }
                    }

                    onCountChanged: {
                        if (itemMultiGrid.grabFocus && index == 0 && count > 0) {
                            currentIndex = 0;
                            focus = true;
                        }
                    }

                    onCurrentItemChanged: {
                        if (!currentItem) {
                            return;
                        }

                        if (index == 0 && currentRow() === 0) {
                            itemMultiGrid.flickableItem.contentY = 0;
                            return;
                        }

                        var y = currentItem.y;
                        y = contentItem.mapToItem(itemMultiGrid.flickableItem.contentItem, 0, y).y;

                        if (y < itemMultiGrid.flickableItem.contentY) {
                            itemMultiGrid.flickableItem.contentY = y;
                        } else {
                            y += isSquare ? root.tileSide : aCellHeight;
                            y -= itemMultiGrid.flickableItem.contentY;
                            y -= itemMultiGrid.viewport.height;

                            if (y > 0) {
                                itemMultiGrid.flickableItem.contentY += y;
                            }
                        }
                    }

                    onKeyNavLeft: {
                        itemMultiGrid.keyNavLeft(index);
                    }

                    onKeyNavRight: {
                        itemMultiGrid.keyNavRight(index);
                    }

                    onKeyNavUp: {
                        if (index > 0) {
                            var prevGrid = subGridAt(index - 1);
                            prevGrid.tryActivate(prevGrid.lastRow(), currentCol());
                        } else {
                            itemMultiGrid.keyNavUp();
                        }
                    }

                    onKeyNavDown: {
                        if (index < repeater.count - 1) {
                            subGridAt(index + 1).tryActivate(0, currentCol());
                        } else {
                            itemMultiGrid.keyNavDown();
                        }
                    }
                }

                // HACK: Steal wheel events from the nested grid view and forward them to
                // the ScrollView's internal WheelArea.
                Kicker.WheelInterceptor {
                    anchors.fill: gridView
                    z: 1

                    destination: findWheelArea(itemMultiGrid.flickableItem)
                }
            }
        }
    }
}

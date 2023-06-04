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
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kquickcontrolsaddons 2.0
import org.kde.draganddrop 2.0

FocusScope {
    id: itemList

    signal keyNavUp
    signal keyNavDown

    signal itemActivated(int index, string actionId, string argument)

    property bool dragEnabled: true
    property bool dropEnabled: false
    property alias usesPlasmaTheme: listView.usesPlasmaTheme

    property alias currentIndex: listView.currentIndex
    property alias currentItem: listView.currentItem
    property alias contentItem: listView.contentItem
    property alias count: listView.count
    property alias model: listView.model

    property alias iconSize: listView.iconSize

    property alias horizontalScrollBarPolicy: scrollArea.horizontalScrollBarPolicy
    property alias verticalScrollBarPolicy: scrollArea.verticalScrollBarPolicy

    onDropEnabledChanged: {
        if (!dropEnabled && "dropPlaceHolderIndex" in model) {
            model.dropPlaceHolderIndex = -1;
        }
    }

    onFocusChanged: {
        if (!focus) {
            currentIndex = -1;
        }
    }

    function tryActivate(row, col) {
        if (count) {
            listView.focus = true
            var rows = count;
            row = Math.min(row, rows - 1);
            currentIndex = Math.min(row ? Math.max(1, row)
                                        : 0,
                                    count - 1);

            focus = true;
        }
    }

    function forceLayout() {
        listView.forceLayout();
    }

    ActionMenu {
        id: actionMenu

        onActionClicked: {
            visualParent.actionTriggered(actionId, actionArgument);
        }
    }

    DropArea {
        id: dropArea

        anchors.fill: parent

        onDragMove: {
            if (!itemList.dropEnabled || listView.animating || !kicker.dragSource) {
                return;
            }

            var cPos = mapToItem(listView.contentItem, event.x, event.y);
            var item = listView.itemAt(cPos.x, cPos.y);

            if (item) {
                if (kicker.dragSource.parent === listView.contentItem) {
                    if (item !== kicker.dragSource) {
                        item.ListView.view.model.moveRow(dragSource.itemIndex, item.itemIndex);
                    }
                } else if (kicker.dragSource.ListView.view.model.favoritesModel === itemList.model
                           && !itemList.model.isFavorite(kicker.dragSource.favoriteId)) {
                    var hasPlaceholder = (itemList.model.dropPlaceholderIndex !== -1);

                    itemList.model.dropPlaceholderIndex = item.itemIndex;

                    if (!hasPlaceholder) {
                        listView.currentIndex = (item.itemIndex - 1);
                    }
                }
            } else if (kicker.dragSource.parent !== listView.contentItem
                       && kicker.dragSource.ListView.view.model.favoritesModel === itemList.model
                       && !itemList.model.isFavorite(kicker.dragSource.favoriteId)) {
                var hasPlaceholder = (itemList.model.dropPlaceholderIndex !== -1);

                itemList.model.dropPlaceholderIndex = hasPlaceholder ? itemList.model.count - 1 : itemList.model.count;

                if (!hasPlaceholder) {
                    listView.currentIndex = (itemList.model.count - 1);
                }
            } else {
                itemList.model.dropPlaceholderIndex = -1;
                listView.currentIndex = -1;
            }
        }

        onDragLeave: {
            if ("dropPlaceholderIndex" in itemList.model) {
                itemList.model.dropPlaceholderIndex = -1;
                listView.currentIndex = -1;
            }
        }

        onDrop: {
            if (kicker.dragSource && kicker.dragSource.parent !== listView.contentItem && kicker.dragSource.ListView.view.model.favoritesModel === itemList.model) {
                itemList.model.addFavorite(kicker.dragSource.favoriteId, itemList.model.dropPlaceholderIndex);
                listView.currentIndex = -1;
            }
        }

        Timer {
            id: resetAnimationDurationTimer

            interval: 120
            repeat: false

            onTriggered: {
                listView.animationDuration = interval - 20;
            }
        }

        Component{
            id: aItemListDelegate
            ItemListDelegate2 {}
        }

        PlasmaExtras.ScrollArea {
            id: scrollArea

            anchors.fill: parent

            focus: true

            horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff

            ListView {
                id: listView

                signal itemContainsMouseChanged(bool containsMouse)

                property bool usesPlasmaTheme: false

                property int iconSize: PlasmaCore.Units.iconSizes.huge

                property bool animating: false
                property int animationDuration: itemList.dropEnabled ? resetAnimationDurationTimer.interval : 0

                focus: true

                currentIndex: -1

                move: Transition {
                    enabled: itemList.dropEnabled

                    SequentialAnimation {
                        PropertyAction { target: listView; property: "animating"; value: true }

                        NumberAnimation {
                            duration: listView.animationDuration
                            properties: "x, y"
                            easing.type: Easing.OutQuad
                        }

                        PropertyAction { target: listView; property: "animating"; value: false }
                    }
                }

                moveDisplaced: Transition {
                    enabled: itemList.dropEnabled

                    SequentialAnimation {
                        PropertyAction { target: listView; property: "animating"; value: true }

                        NumberAnimation {
                            duration: listView.animationDuration
                            properties: "x, y"
                            easing.type: Easing.OutQuad
                        }

                        PropertyAction { target: listView; property: "animating"; value: false }
                    }
                }

                keyNavigationWraps: false
                boundsBehavior: Flickable.StopAtBounds

                delegate: aItemListDelegate

                highlight: Item {
                    property bool isDropPlaceHolder: "dropPlaceholderIndex" in itemList.model && itemList.currentIndex === itemList.model.dropPlaceholderIndex

                    PlasmaComponents.Highlight {
                        visible: listView.currentItem && !isDropPlaceHolder

                        anchors.fill: parent
                    }

                    PlasmaCore.FrameSvgItem {
                        visible: listView.currentItem && isDropPlaceHolder

                        anchors.fill: parent

                        imagePath: "widgets/viewitem"
                        prefix: "selected"

                        opacity: 0.5

                        PlasmaCore.IconItem {
                            anchors {
                                right: parent.right
                                rightMargin: parent.margins.right
                                bottom: parent.bottom
                                bottomMargin: parent.margins.bottom
                            }

                            width: PlasmaCore.Units.iconSizes.smallMedium
                            height: width

                            source: "list-add"
                            active: false
                        }
                    }
                }

                highlightFollowsCurrentItem: true
                highlightMoveDuration: 0

                onCurrentIndexChanged: {
                    if (currentIndex != -1) {
                        hoverArea.hoverEnabled = false
                        focus = true;
                    }
                }

                onCountChanged: {
                    animationDuration = 0;
                    resetAnimationDurationTimer.start();
                }

                onModelChanged: {
                    currentIndex = -1;
                }

                Keys.onUpPressed: {
                    if (itemList.currentIndex !== 0) {
                        event.accepted = true;
                        decrementCurrentIndex();
                        positionViewAtIndex(currentIndex, ListView.Contain);
                    } else {
                        itemList.keyNavUp();
                    }
                }

                Keys.onDownPressed: {
                    if (itemList.currentIndex < itemList.count - 1) {
                        event.accepted = true;
                        incrementCurrentIndex();
                        positionViewAtIndex(currentIndex, ListView.Contain);
                    } else {
                        itemList.keyNavDown();
                    }
                }

                onItemContainsMouseChanged: {
                    if (!containsMouse) {
                        if (!actionMenu.opened) {
                            listView.currentIndex = -1;
                        }

                        hoverArea.pressX = -1;
                        hoverArea.pressY = -1;
                        hoverArea.lastX = -1;
                        hoverArea.lastY = -1;
                        hoverArea.pressedItem = null;
                        hoverArea.hoverEnabled = true;
                    }
                }
            }
        }

        MouseArea {
            id: hoverArea

            anchors.fill: parent

            property int pressX: -1
            property int pressY: -1
            property int lastX: -1
            property int lastY: -1
            property Item pressedItem: null

            acceptedButtons: Qt.LeftButton | Qt.RightButton

            hoverEnabled: true

            function updatePositionProperties(x, y) {
                // Prevent hover event synthesis in QQuickWindow interfering
                // with keyboard navigation by ignoring repeated events with
                // identical coordinates. As the work done here would be re-
                // dundant in any case, these are safe to ignore.
                if (lastX === x && lastY === y) {
                    return;
                }

                lastX = x;
                lastY = y;

                var cPos = mapToItem(listView.contentItem, x, y);
                var item = listView.itemAt(cPos.x, cPos.y);

                if (!item) {
                    listView.currentIndex = -1;
                    pressedItem = null;
                } else {
                    listView.currentIndex = item.itemIndex;
                    itemList.focus = (itemList.currentIndex != -1)
                }

                return item;
            }

            onPressed: mouse => {
                           mouse.accepted = true;

                           updatePositionProperties(mouse.x, mouse.y);

                           pressX = mouse.x;
                           pressY = mouse.y;

                           if (mouse.button == Qt.RightButton) {
                               if (listView.currentItem) {
                                   if (listView.currentItem.hasActionList) {
                                       var mapped = mapToItem(listView.currentItem, mouse.x, mouse.y);
                                       listView.currentItem.openActionMenu(mapped.x, mapped.y);
                                   }
                               } else {
                                   var mapped = mapToItem(rootItem, mouse.x, mouse.y);
                                   contextMenu.open(mapped.x, mapped.y);
                               }
                           } else {
                               pressedItem = listView.currentItem;
                           }
                       }

            onReleased: mouse => {
                            mouse.accepted = true;
                            updatePositionProperties(mouse.x, mouse.y);

                            if (listView.currentItem && listView.currentItem == pressedItem) {
                                if ("trigger" in listView.model) {
                                    listView.model.trigger(pressedItem.itemIndex, "", null);
                                    root.toggle();
                                }

                                itemList.itemActivated(pressedItem.itemIndex, "", null);
                            } else if (!dragHelper.dragging && !pressedItem && mouse.button == Qt.LeftButton) {
                                root.toggle();
                            }

                            pressX = -1;
                            pressY = -1;
                            pressedItem = null;
                        }

            onPositionChanged: mouse => {
                                   var item = pressedItem? pressedItem : updatePositionProperties(mouse.x, mouse.y);

                                   if (listView.currentIndex != -1) {
                                       if (itemList.dragEnabled && pressX != -1 && dragHelper.isDrag(pressX, pressY, mouse.x, mouse.y)) {
                                           if ("pluginName" in item.m) {
                                               dragHelper.startDrag(kicker, item.url, item.icon,
                                                                    "text/x-plasmoidservicename", item.m.pluginName);
                                           } else {
                                               dragHelper.startDrag(kicker, item.url, item.icon);
                                           }

                                           kicker.dragSource = item;

                                           pressX = -1;
                                           pressY = -1;
                                       }
                                   }
                               }
        }
    }
}

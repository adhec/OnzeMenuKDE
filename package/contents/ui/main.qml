/***************************************************************************
 *   Copyright (C) 2014-2015 by Eike Hein <hein@kde.org>                   *
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
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.plasma.private.kicker 0.1 as Kicker

Item {
    id: kicker

    anchors.fill: parent

    signal reset

    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation
    Plasmoid.compactRepresentation: null
    Plasmoid.fullRepresentation: compactRepresentation

    property Item dragSource: null

    function action_menuedit() {
        processRunner.runMenuEditor();
    }

    Component {
        id: compactRepresentation
        CompactRepresentation {}
    }

    Component {
        id: menuRepresentation
        MenuRepresentation {}
    }

    readonly property Kicker.RootModel rootModel: Kicker.RootModel {
        id: rootModel
        autoPopulate: false

        appletInterface: plasmoid

        flat: true // have categories, but no subcategories
        showSeparators: false
        showTopLevelItems: false//true

        showAllApps: true
        showAllAppsCategorized: true
        showRecentApps: true
        showRecentDocs: true
        showRecentContacts: false
        showPowerSession: false
        Component.onCompleted: {

            favoritesModel.initForClient("org.kde.plasma.kickoff.favorites.instance-" + plasmoid.id)

            if (!plasmoid.configuration.favoritesPortedToKAstats) {
                if (favoritesModel.count < 1) {
                    favoritesModel.portOldFavorites(plasmoid.configuration.favorites);
                }
                plasmoid.configuration.favoritesPortedToKAstats = true;
            }
        }
    }

    readonly property Kicker.RecentUsageModel frequentUsageModel: Kicker.RecentUsageModel {
        favoritesModel: rootModel.favoritesModel
        ordering: 1 // Popular / Frequently Used
    }

    readonly property Kicker.RecentUsageModel recentUsageModel: Kicker.RecentUsageModel {
        favoritesModel: rootModel.favoritesModel
    }

    Kicker.RunnerModel {
        id: runnerModel
        appletInterface: plasmoid
        favoritesModel: rootModel.favoritesModel
        mergeResults: false
        deleteWhenEmpty: true
    }

    Kicker.DragHelper {
        id: dragHelper
    }

    Kicker.ProcessRunner {
        id: processRunner;
    }

    Kicker.WindowSystem {
        id: windowSystem
    }

    Connections {
        target: plasmoid.configuration
        function onHiddenApplicationsChanged(){
            rootModel.refresh(); // Force refresh on hidden
        }
    }

    PlasmaCore.FrameSvgItem {
        id : highlightItemSvg
        visible: false
        imagePath: "widgets/viewitem"
        prefix: "hover"
    }

    PlasmaCore.FrameSvgItem {
        id : panelSvg

        visible: false

        imagePath: "widgets/panel-background"
    }

    PlasmaCore.FrameSvgItem {
        id : backgroundSvg

        visible: false

        imagePath: "dialogs/background"
    }


    PlasmaComponents.Label {
        id: toolTipDelegate

        width: contentWidth
        height: contentHeight

        property Item toolTip

        text: (toolTip != null) ? toolTip.text : ""
    }

    function resetDragSource() {
        dragSource = null;
    }

    function enableHideOnWindowDeactivate() {
        plasmoid.hideOnWindowDeactivate = true;
    }

    Component.onCompleted: {
        //plasmoid.setAction("menuedit", i18n("Edit Applications..."));
        //rootModel.refreshed.connect(reset);
        //dragHelper.dropped.connect(resetDragSource);

        if (plasmoid.hasOwnProperty("activationTogglesExpanded")) {
            plasmoid.activationTogglesExpanded = false
        }

        windowSystem.focusIn.connect(enableHideOnWindowDeactivate);
        plasmoid.hideOnWindowDeactivate = true;

        if (plasmoid.immutability !== PlasmaCore.Types.SystemImmutable) {
            plasmoid.setAction("menuedit", i18n("Edit Applications…"), "kmenuedit");
        }

        //updateSvgMetrics();
        //PlasmaCore.Theme.themeChanged.connect(updateSvgMetrics);
        dragHelper.dropped.connect(resetDragSource);
    }
}

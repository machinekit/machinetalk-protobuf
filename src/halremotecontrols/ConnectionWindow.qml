/****************************************************************************
**
** Copyright (C) 2014 Alexander Rössler
** License: LGPL version 2.1
**
** This file is part of QtQuickVcp.
**
** All rights reserved. This program and the accompanying materials
** are made available under the terms of the GNU Lesser General Public License
** (LGPL) version 2.1 which accompanies this distribution, and is available at
** http://www.gnu.org/licenses/lgpl-2.1.html
**
** This library is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
** Lesser General Public License for more details.
**
** Contributors:
** Alexander Rössler @ The Cool Tool GmbH <mail DOT aroessler AT gmail DOT com>
**
****************************************************************************/
import QtQuick 2.1
import QtQuick.Controls 1.1
import QtQuick.Window 2.0
import Machinekit.HalRemote 1.0

/*!
    \qmltype ConnectionWindow
    \inqmlmodule Machinekit.HalRemote.Controls
    \brief Provides an all in one container item to load and display Machinekit UIs.
    \ingroup halremotecontrols

    This component provides an all in container item to load and display Machinekit UIs.
    It combines service discovery and instance selection for local as well as remote
    deployed \l{HalApplicationWindow}.

    The following example demonstrates how to use the ConnectionWindow as generic Machinekit
    client.

    \qml
    ConnectionWindow {
        id: connectionWindow

        anchors.fill: parent
        autoSelectInstance: false
        applicationSource: ""
        instanceFilter: ServiceDiscoveryFilter{ name: "" }
    }
    \endqml

    It can also be used to load local UIs e.g. for development purposes.

    \qml
    ConnectionWindow {
        id: connectionWindow

        anchors.fill: parent
        autoSelectInstance: false
        applicationSource: "qrc:/qml/VideoDemo.qml"
        instanceFilter: ServiceDiscoveryFilter{ name: "" }
    }
    \endqml

    Use a combination of \l instanceFilter and \l autoSelectInstance to automatically
    connect to a specific instance. This can be especially usefull during development
    of new UIs.

    \qml
    ConnectionWindow {
        id: connectionWindow

        anchors.fill: parent
        autoSelectInstance: true
        applicationSource: "qrc:/qml/VideoDemo.qml"
        instanceFilter: ServiceDiscoveryFilter{ name: "Development" }
    }
    \endqml
*/



Rectangle {
    /*! This property holds whether an instance should be automatically selected or not.
    */
    property bool autoSelectInstance: false

    /*! \qmlproperty ServiceDiscoveryFilter instanceFilter

        This property can be used to filter all available instances for a specific name or TXT record.
    */
    property alias instanceFilter: configService.filter

    /*! This property holds the source of the main application window. Leave this property empty to
        to show a list of applications available on the remote config server.
    */
    property string applicationSource: ""

    /*! This property holds the title of the window.
    */
    readonly property string title: (applicationLoader.active && (applicationLoader.item != null))
                           ? ((applicationLoader.item.title !== undefined) ? applicationLoader.item.title : "")
                           : qsTr("MachineKit App Discover")

    /*! This property holds whether the a local or remote application should be loaded. Depends on the
        \l{applicationSource}.
    */
    readonly property bool localMode: applicationSource != ""

    id: mainWindow


    color: systemPalette.window
    width: 500
    height: 700

    /*! \internal */
    function selectInstance(index)
    {
        if (!localMode)
        {
            if ((configService.items[index].uri !== "") && (configService.items[index].uuid !== ""))
            {
                var x = applicationConfig   // for some reason the appConfig variable goes away after settings the filter
                serviceDiscoveryFilter.txtRecords = ["uuid=" + configService.items[index].uuid]
                serviceDiscovery.updateFilter()
                x.ready = true
                discoveryPage.instanceSelected = true
            }
            else
            {
                console.log("selecting instance failed: check uri and uuid")
                setError(qsTr("Instance Error:"), qsTr("Check uri and uuid"))
            }
        }
        else
        {
            if (configService.items[index].uuid !== "")
            {
                serviceDiscoveryFilter.txtRecords = ["uuid=" + configService.items[index].uuid]
                serviceDiscovery.updateFilter()
                discoveryPage.instanceSelected = true
            }
            else
            {
                console.log("selecting instance failed: check uuid")
                setError(qsTr("Instance Error:"), qsTr("Check uri and uuid"))
            }
        }
    }

    /*! \internal */
    function goBack()
    {
        if (mainWindow.state == "discovery")
        {
            Qt.quit()
        }
        else if (mainWindow.state == "config")
        {
            if (autoSelectInstance == false)
            {
                applicationConfig.ready = false
                serviceDiscoveryFilter.txtRecords = []
                serviceDiscovery.updateFilter()
            }
            else
            {
                Qt.quit()
            }
        }
        else if (mainWindow.state == "loaded")
        {
            if (localMode)
            {
                if (autoSelectInstance == false)
                {
                    applicationServiceList.services = []
                    applicationInternalServiceList.services = []
                    serviceDiscovery.updateServices()
                    serviceDiscoveryFilter.txtRecords = []
                    serviceDiscovery.updateFilter()
                    discoveryPage.instanceSelected = false
                }
                else
                {
                    Qt.quit()
                }
            }
            else
            {
                applicationConfig.unselectConfig()
                applicationServiceList.services = []
                applicationInternalServiceList.services = []
                serviceDiscovery.updateServices()
            }
        }
        else if (mainWindow.state == "error")
        {
            clearError()
            applicationConfig.ready = false
            serviceDiscoveryFilter.txtRecords = []
            serviceDiscovery.updateFilter()
        }
    }

    /*! \internal */
    function setError(errorType, errorText)
    {
        errorPage.errorType = errorType
        errorPage.errorText = errorText
        discoveryPage.errorActive = true
    }

    /*! \internal */
    function clearError()
    {
        discoveryPage.errorActive = false
    }

    // Capture the Android Back key and backspace key
    // on the desktop tp go back in the application
    // focus needs to be true to capture key events
    focus: true
    Keys.onReleased: {
        if ((event.key === Qt.Key_Back) ||
                (event.key === Qt.Key_Backspace)) {
            goBack()
            event.accepted = true
        }
    }

    SystemPalette {
        id: systemPalette;
        colorGroup: enabled ? SystemPalette.Active : SystemPalette.Disabled
    }

    Text {
        id: dummyText
    }

    Item {
        id: networkPage

        anchors.fill: parent

        Label {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Screen.logicalPixelDensity * 2
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.pixelSize: dummyText.font.pixelSize * 1.5
            text: qsTr("Warning!<br>No network connection found, service discovery unavailable. Please check your network connection.")
        }
    }

    Item {
        property bool instanceSelected: false
        property bool errorActive: false

        id: discoveryPage

        anchors.fill: parent

        Text {
            id: pageTitleText2

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: Screen.logicalPixelDensity*3
            text: qsTr("Available Instances:")
            font.pointSize: dummyText.font.pointSize * 1.6
            font.bold: true
        }

        ListView {
            anchors.top: pageTitleText2.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Screen.logicalPixelDensity*3
            spacing: Screen.logicalPixelDensity*3

            model: configService.items
            delegate: Button {
                anchors.left: parent.left
                anchors.right: parent.right
                height: mainWindow.height*0.1

                Text {
                    id: titleText2

                    anchors.centerIn: parent
                    font.pointSize: dummyText.font.pointSize*1.6
                    font.bold: true
                    text: name
                }

                onClicked: selectInstance(index)
            }

            onCountChanged: {
                if ((mainWindow.state == "discovery") && (autoSelectInstance == true) && (count > 0))
                {
                    selectInstance(0)
                }
            }
        }

        BusyIndicator {
            anchors.centerIn: parent
            running: true
            visible: configService.items.length === 0
            height: parent.height * 0.15
            width: height
        }
    }

    Item {
        id: appPage

        anchors.fill: parent

        Text {
            id: pageTitleText

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: Screen.logicalPixelDensity*3
            text: configService.name
            font.pointSize: dummyText.font.pointSize * 1.6
            font.bold: true
        }

        ListView {
            anchors.top: pageTitleText.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Screen.logicalPixelDensity*3
            spacing: Screen.logicalPixelDensity*3

            model: applicationConfig.configs
            delegate: Button {
                anchors.left: parent.left
                anchors.right: parent.right
                height: mainWindow.height*0.1

                Text {
                    id: titleText

                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -Screen.logicalPixelDensity*2
                    font.pointSize: descriptionText.font.pointSize*1.6
                    font.bold: true
                    text: name
                }
                Text {
                    id: descriptionText

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: titleText.bottom
                    anchors.margins: Screen.logicalPixelDensity*1
                    text: description
                }

                onClicked: applicationConfig.selectConfig(name)
            }
        }
    }

    Item {
        id: viewPage

        anchors.fill: parent

        Loader {
            id: applicationLoader

            anchors.fill: parent
            active: localMode ? discoveryPage.instanceSelected : applicationConfig.selectedConfig.loaded
            source: localMode ? applicationSource : applicationConfig.selectedConfig.mainFile

            onSourceChanged: {
                console.log("Source changed: " + source + " " + active)
            }

            onLoaded: {
                console.log("Window " + applicationLoader.item.name + " loaded")
                applicationServiceList.services = Qt.binding(
                            function()
                            {
                                return (((applicationLoader.item != null) && (applicationLoader.item.services !== undefined)) ? applicationLoader.item.services : [])
                            })
                applicationInternalServiceList.services = Qt.binding(
                            function()
                            {
                                return (((applicationLoader.item != null) && (applicationLoader.item.internalServices !== undefined)) ? applicationLoader.item.internalServices : [])
                            })
                serviceDiscovery.updateServices()
            }
        }
    }

    Item {
        property string errorType: ""
        property string errorText: ""

        id: errorPage

        anchors.fill: parent

        Label {
            id: errorLabel

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Screen.logicalPixelDensity * 2
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.pixelSize: dummyText.font.pixelSize * 1.5
            text: errorPage.errorType + "\n" + errorPage.errorText
        }
    }

    ApplicationConfig {
        id: applicationConfig

        ready: false
        configUri: configService.uri
        filters: [ ApplicationConfigFilter { type: ApplicationConfigItem.Qt5QmlApplication } ]
        onConnectionStateChanged: {
            if (applicationConfig.connectionState === ApplicationConfig.Error)
            {
                setError(qsTr("Application Config Error:"), applicationConfig.errorString)
            }
        }
    }

    ServiceDiscovery {
        id: serviceDiscovery

        serviceType: "machinekit"
        domain:      "local"
        running:     true
        filter: ServiceDiscoveryFilter {
            id: serviceDiscoveryFilter
            name: ""
        }

        serviceLists: [
            ServiceList {
                services: [
                    Service {
                        id: configService
                        type: "config"
                        filter: ServiceDiscoveryFilter { name: "" }
                    }
                ]
            },
            ServiceList {
                id: applicationInternalServiceList
            },
            ServiceList {
                id: applicationServiceList
            }
        ]
    }

    state: {
        if (serviceDiscovery.networkOpen)
        {
            if (discoveryPage.errorActive)
            {
                return "error"
            }
            else if (localMode && discoveryPage.instanceSelected)
            {
                return "loaded"
            }
            else if (applicationConfig.ready)
            {
                if (applicationLoader.active)
                {
                    return "loaded";
                }
                else
                {
                    return "config"
                }
            }
            else {
                return "discovery"
            }
        }
        else
        {
            return "network"
        }
    }

    states: [
        State {
            name: "network"
            PropertyChanges { target: networkPage; opacity: 1.0; z: 1; enabled: true }
            PropertyChanges { target: discoveryPage; opacity: 0.0; z: 0; enabled: false }
            PropertyChanges { target: appPage; opacity: 0.0; z: 0; enabled: false }
            PropertyChanges { target: viewPage; opacity: 0.0; z: 0; enabled: false }
            PropertyChanges { target: errorPage; opacity: 0.0; z: 0; enabled: false }
        },
        State {
            name: "discovery"
            PropertyChanges { target: discoveryPage; opacity: 1.0; z: 1; enabled: true }
            PropertyChanges { target: appPage; opacity: 0.0; z: 0; enabled: false }
            PropertyChanges { target: viewPage; opacity: 0.0; z: 0; enabled: false }
            PropertyChanges { target: networkPage; opacity: 0.0; z: 0; enabled: false }
            PropertyChanges { target: errorPage; opacity: 0.0; z: 0; enabled: false }
        },
        State {
            name: "config"
            PropertyChanges { target: appPage; opacity: 1.0; z: 1; enabled: true }
            PropertyChanges { target: viewPage; opacity: 0.0; z: 0; enabled: false }
            PropertyChanges { target: discoveryPage; opacity: 0.0; z: 0; enabled: false }
            PropertyChanges { target: networkPage; opacity: 0.0; z: 0; enabled: false }
            PropertyChanges { target: errorPage; opacity: 0.0; z: 0; enabled: false }
        },
        State {
            name: "loaded"
            PropertyChanges { target: appPage; opacity: 0.0; z: 0; enabled: false }
            PropertyChanges { target: viewPage; opacity: 1.0; z: 1; enabled: true }
            PropertyChanges { target: discoveryPage; opacity: 0.0; z: 0; enabled: false }
            PropertyChanges { target: networkPage; opacity: 0.0; z: 0; enabled: false }
            PropertyChanges { target: errorPage; opacity: 0.0; z: 0; enabled: false }
        },
        State {
            name: "error"
            PropertyChanges { target: appPage; opacity: 0.0; z: 0; enabled: false }
            PropertyChanges { target: viewPage; opacity: 0.0; z: 0; enabled: false }
            PropertyChanges { target: discoveryPage; opacity: 0.0; z: 0; enabled: false }
            PropertyChanges { target: networkPage; opacity: 0.0; z: 0; enabled: false }
            PropertyChanges { target: errorPage; opacity: 1.0; z: 1; enabled: true }
        }
    ]

    transitions: Transition {
            PropertyAnimation { duration: 500; properties: "opacity"; easing.type: Easing.InCubic }
        }
}
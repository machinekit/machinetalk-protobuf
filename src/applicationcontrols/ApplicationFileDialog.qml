import QtQuick 2.0
import QtQuick.Dialogs 1.2
import Machinekit.Application 1.0

FileDialog {
    property var core: null
    property var status: core === null ? {"synced": false} : core.status
    property var file: core === null ? {"localPath":"", "remotePath":"", "localFilePath":"", "ready":false} : core.file

    id: fileDialog
    title: qsTr("Please choose a file")
    onAccepted: {
        file.localFilePath = fileUrl
        file.startUpload()
    }

    nameFilters: {
        var filters = []
        var allExtensions = ["*.ngc"]

        if ((status.synced) && (status.config.programExtension !== undefined))
        {
            for (var i = 0; i < status.config.programExtension.length; ++i)
            {
                var extension = status.config.programExtension[i]
                var splitted = extension.split(",")
                var nameSplit = splitted[splitted.length-1].split(" ")
                splitted[splitted.length-1] = nameSplit[0]
                nameSplit.splice(0,1)
                var name = nameSplit.join(" ")
                for (var j = 0; j < splitted.length; ++j) {
                    splitted[j] = "*" + splitted[j]
                }
                filters.push(name + " (" + splitted.join(" ") + ")")
                allExtensions = allExtensions.concat(splitted)
            }
        }

        filters.unshift(qsTr("All machinable files") + " (" + allExtensions.join(" ") + ")")
        filters.push(qsTr("rs274ngc files") + " (*.ngc)")
        filters.push(qsTr("All files") + " (*)")
        return filters
    }

    Component.onCompleted: {
        if (core == null)
        {
            try {
                var x = applicationCore
                core = Qt.binding(function() {return x})
            }
            catch (err) {
            }
        }
    }
}
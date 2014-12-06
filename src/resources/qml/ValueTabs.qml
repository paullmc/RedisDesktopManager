import QtQuick 2.0
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.1
import QtQuick.Dialogs 1.2

Repeater {

    Tab {
        id: keyTab

        function close(index) {
            viewModel.closeTab(tabIndex)
        }

        title: keyName
        property int tabIndex: keyIndex

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 5
            spacing: 1

            RowLayout {
                Layout.preferredHeight: 40
                Layout.minimumHeight: 40
                Layout.fillWidth: true
                spacing: 1

                Text { text: "Key:" }
                TextField {
                    id: keyNameField
                    Layout.fillWidth: true
                    text: keyName
                    readOnly: true                    
                }

                Button {
                    text: "Rename"

                    Dialog {
                        id: renameConfirmation
                        title: "Rename key"

                        width: 520

                        RowLayout {
                            implicitWidth: 500
                            implicitHeight: 100
                            width: 500

                            Text { text: "New name:" }
                            TextField { id: newKeyName; Layout.fillWidth: true;}
                        }

                        onAccepted: {
                            console.log(newKeyName.text)
                            viewModel.renameKey(keyTab.keyIndex, newKeyName.text)
                        }

                        visible: false
                        modality: Qt.WindowModal
                        standardButtons: StandardButton.Ok | StandardButton.Cancel
                    }

                    onClicked: {
                        newKeyName.text = keyNameField.text
                        renameConfirmation.open()
                    }
                }

                //Button { text: "Reload" } // TBD

                Button {
                    text: "Delete"

                    MessageDialog {
                        id: deleteConfirmation
                        title: "Delete key"
                        text: "Do you really want to delete this key?"
                        onYes: {
                            console.log("remove key")
                            viewModel.removeKey(keyTab.keyIndex)
                        }
                        visible: false
                        modality: Qt.WindowModal
                        icon: StandardIcon.Warning
                        standardButtons: StandardButton.Yes | StandardButton.No
                    }

                    onClicked: {
                        deleteConfirmation.open()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.minimumHeight: 40

                Text { text: "Type:"; font.bold: true }
                Text { text: keyType.toUpperCase()  }
                Text { text: "TTL:"; font.bold: true }
                Text { text: keyTtl}
            }

            RowLayout {
                id: pagination
                visible: showValueNavigation
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.minimumHeight: 40

                Button { text: "|<"}
                Button { text: "<"}
                TextField { text: "1"; Layout.fillWidth: true; readOnly: false}
                Button {
                    text: "Goto Index"
                }
                Button { text: ">"}
                Button { text: ">|"}
            }

            TableView {
                id: table
                visible: showValueNavigation
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 100

                TableViewColumn{ width: 30 }
                TableViewColumn{ width: 100 }
                TableViewColumn{ width: table.width - 130}

                model: viewModel.getValue(tabIndex)

                property int currentStart: 0
                property int maxItemsOnPage: 100

                Component.onCompleted: {
                    loadValue()
                }

                Connections {
                    target: viewModel

                    onReplaceTab: {
                        console.log("replace tab")
                        table.model = viewModel.getValue(tabIndex)
                        table.loadValue()
                    }
                }


                MessageDialog {
                    id: valueLoadingConfirmation
                    title: "Legacy Redis-Server detected!"
                    text: "You are connected to legacy redis-server, which doesn't support partial loading. "
                            + "Do you really want to load " + table.model.totalRowCount() +" items?"
                    onYes: {
                        table.loadValue(true)
                    }
                    visible: false
                    modality: Qt.WindowModal
                    icon: StandardIcon.Warning
                    standardButtons: StandardButton.Yes | StandardButton.No
                }

                function loadValue() {
                    var columns = table.model.getColumnNames()

                    for (var index = 0; index < 3; index++)
                    {
                        var column = table.getColumn(index)

                        if (index >= columns.length) {
                            column.visible = false
                            continue
                        }

                        column.role = columns[index]
                        column.title = columns[index]
                        column.visible = true
                    }

                    if (table.model.isPartialLoadingSupported()
                            || table.model.totalRowCount() < maxItemsOnPage
                            || (arguments.length == 1 && arguments[0] === true)) {
                        table.model.loadRows(currentStart, maxItemsOnPage)
                    } else {
                        // Legacy redis without SCAN support
                        // Show warning message
                        // to get upprove from user
                        valueLoadingConfirmation.open()
                    }

                    // TODO: show loader with fadeout
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: !showValueNavigation

                TextArea {
                    Layout.fillWidth: true
                    Layout.fillHeight: !showValueNavigation
                    text: {
                        if (keyType === "string") {
                            table.loadValue()
                            console.log(table.model.get(0))
                            return table.model.get(0).value
                        }
                        return "" // TBD
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 40
                    Item { Layout.fillWidth: true}
                    Button { text: "Save"}
                }

            }
        }
    }
}

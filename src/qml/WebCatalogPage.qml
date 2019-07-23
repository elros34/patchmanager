/*
 * Copyright (C) 2014 Lucien XU <sfietkonstantin@free.fr>
 *
 * You may use this file under the terms of the BSD license as follows:
 *
 * "Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *   * Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in
 *     the documentation and/or other materials provided with the
 *     distribution.
 *   * The names of its contributors may not be used to endorse or promote
 *     products derived from this software without specific prior written
 *     permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import org.SfietKonstantin.patchmanager 2.0

Page {
    id: container
    property string author
    property var versions
    property string release
    property string search
    property bool searchVisible
    property PatchManagerPage patchManagerPage

    onStatusChanged: {
        if (status == PageStatus.Active) {
            patchmanagerDbusInterface.listVersions()
        } else if (status == PageStatus.Deactivating) {
            patchManagerPage.pendingPatchesRefresh = true
        }
    }

    DBusInterface {
        id: patchmanagerDbusInterface
        service: "org.SfietKonstantin.patchmanager"
        path: "/org/SfietKonstantin/patchmanager"
        iface: "org.SfietKonstantin.patchmanager"
        bus: DBus.SystemBus
        function listVersions() {
            typedCall("listVersions", [], function (patches) {
                container.versions = patches
            })
        }
    }

    SilicaListView {
        id: view
        anchors.fill: parent

        PullDownMenu {
            quickSelect: true
            visible: !container.author

            MenuItem {
                text: PatchManager.developerMode ? qsTranslate("", "Disable developer mode") : qsTranslate("", "Enable developer mode")
                onClicked: PatchManager.developerMode = !PatchManager.developerMode
            }

            MenuItem {
                text: searchVisible ? qsTranslate("", "Hide search field") : qsTranslate("", "Show search field")
                onClicked: {
                    searchVisible = !searchVisible
                }
            }
        }

        header: Component {
            Column {
                width: view.width
                PageHeader {
                    title: container.author ? qsTranslate("", "%1 patches").arg(container.author) : qsTranslate("", "Web catalog")
                }

                SearchField {
                    id: searchField
                    width: parent.width
                    placeholderText: qsTranslate("", "Tap to enter search query")
                    visible: container.searchVisible
                    onVisibleChanged: {
                        if (visible) {
                            forceActiveFocus()
                        } else {
                            text = ''
                            container.forceActiveFocus()
                        }
                    }
                    onTextChanged: {
                        if (visible) {
                            searchTimer.restart()
                        }
                    }
                    EnterKey.enabled: text.length > 0
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.onClicked: {
                        searchTimer.stop()
                        container.search = searchField.text
                    }
                    Timer {
                        id: searchTimer
                        interval: 1500
                        repeat: false
                        onTriggered: {
                            container.search = searchField.text
                        }
                    }
                }
            }
        }
        model: WebPatchesModel {
            id: patchModel
            queryParams:  container.author ? { 'author': container.author }
                                           : container.search ? { 'display_name__contains': container.search }
                                                              : {}
        }
        section.criteria: ViewSection.FullString
        section.delegate: SectionHeader {
            text: qsTranslate("", section[0].toUpperCase() + section.substr(1))
        }
        section.property: "category"
        currentIndex: -1

        delegate: BackgroundItem {
            id: background
            contentHeight: height
            height: Theme.itemSizeExtraLarge + Theme.paddingSmall
            property bool isInstalled: typeof(container.versions) != "undefined" && typeof(container.versions[model.name]) != "undefined"

            onClicked: {
                pageStack.push(Qt.resolvedUrl("WebPatchPage.qml"),
                               {modelData: model, delegate: background, release: release})
            }

            Column {
                id: delegateContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter

                Item {
                    height: nameLabel.height
                    width: parent.width
                    Label {
                        id: nameLabel
                        width: parent.width - authorLabel.width - Theme.paddingMedium
                        text: model.display_name
                        color: background.down ? Theme.highlightColor : Theme.primaryColor
                        font.bold: isInstalled
                        truncationMode: TruncationMode.Fade
                    }

                    Label {
                        id: authorLabel
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: model.author
                        color: Theme.secondaryHighlightColor
                    }
                }

                Label {
                    width: parent.width
                    text: model.description.replace("\r\n\r\n", "\r\n")
                    color: background.down ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    maximumLineCount: 3
                }
            }
        }

        ViewPlaceholder {
            enabled: patchModel.count == 0
            text: qsTranslate("", "No patches available")
        }

        VerticalScrollDecorator {}
    }

    BusyIndicator {
        id: indicator
        running: visible
        visible: view.count == 0
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
    }
}



TARGET = patchmanager
PLUGIN_IMPORT_PATH = org/SfietKonstantin/patchmanager

TEMPLATE = lib
QT = core qml network
CONFIG += qt plugin hide_symbols

HEADERS += \
    patchmanager.h \
    webcatalog.h \
    webpatchesmodel.h \
    webpatchdata.h \
    webdownloader.h

SOURCES += \
    plugin.cpp \
    patchmanager.cpp \
    webpatchesmodel.cpp \
    webpatchdata.cpp \
    webdownloader.cpp

DISTFILES += qmldir \
    PatchManagerPage.qml \
    AboutPage.qml \
    DevelopersPage.qml \
    RestartServicesDialog.qml \
    LegacyPatchPage.qml \
    WebCatalogPage.qml \
    WebPatchPage.qml \
    ItemErrorComponent.qml \
    NewPatchPage.qml \
    ScreenshotsPage.qml

target.path = $$[QT_INSTALL_QML]/$$PLUGIN_IMPORT_PATH

qmlfiles.files += $${DISTFILES}
qmlfiles.path = $$[QT_INSTALL_QML]/$$PLUGIN_IMPORT_PATH

translations.files += translations/*.qm
translations.path = /usr/share/translations

INSTALLS += target qmlfiles translations

#include <clocale>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QIcon>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QUrl>
#include <iostream>
#include <QWebChannel>
#include <QtWebEngineQuick/qtwebenginequickglobal.h>

#include "bridge/bridge.hpp"

int main(int argc, char *argv[]) {
    std::setlocale(LC_NUMERIC, "C");

    // Prevent GPU buffer sharing segfault on Wayland with hybrid GPU (NVIDIA + AMD/Intel)
    if (!qEnvironmentVariableIsSet("QTWEBENGINE_CHROMIUM_FLAGS")) {
        qputenv("QTWEBENGINE_CHROMIUM_FLAGS", "--disable-gpu-compositing --disable-dev-shm-usage");
    }
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");

    QtWebEngineQuick::initialize();

    QGuiApplication app(argc, argv);
    std::setlocale(LC_NUMERIC, "C");
    qInstallMessageHandler([](QtMsgType, const QMessageLogContext &, const QString &msg) {
        std::cout << "[Qt/QML] " << msg.toStdString() << std::endl;
    });
    app.setApplicationName("Melyar");
    app.setApplicationDisplayName("Melyar");
    app.setOrganizationName("Melyar");
    app.setOrganizationDomain("melyar.org");
    QIcon appIcon;
    appIcon.addFile(":/melyar/ui_cpp/resources/melyar.svg");
    app.setWindowIcon(appIcon);

    qmlRegisterSingletonType(QUrl(QStringLiteral("qrc:/melyar/ui_cpp/qml/theme/Style.qml")), "Melyar.Theme", 1, 0, "Style");
    QQmlApplicationEngine engine;
    engine.addImportPath(":/melyar");
    engine.addImportPath("qrc:/melyar");

    // C++/Rust bridge exposed to QML (for global media shortcuts)
    auto bridge = std::make_unique<MelyarBridge>();
    MelyarBridge *bridgePtr = bridge.get();
    engine.rootContext()->setContextProperty("bridge", bridgePtr);

    // Resolve web UI path BEFORE loading QML
    QString webUrlStr = qEnvironmentVariable("MELYAR_DEV_URL");
    if (webUrlStr.isEmpty()) {
        QStringList candidates = {
            QDir::currentPath() + "/ui_web/dist/index.html",
            QCoreApplication::applicationDirPath() + "/../ui_web/dist/index.html",
            QCoreApplication::applicationDirPath() + "/ui_web/dist/index.html",
            "/home/mahmud/melyar/ui_web/dist/index.html",
            "/usr/share/melyar/web/index.html"
        };
        for (const auto &cand : candidates) {
            if (QFile::exists(cand)) {
                webUrlStr = QUrl::fromLocalFile(QFileInfo(cand).canonicalFilePath()).toString();
                break;
            }
        }
    }
    if (webUrlStr.isEmpty()) {
        webUrlStr = QUrl::fromLocalFile(QDir::currentPath() + "/ui_web/dist/index.html").toString();
    }
    std::cout << "Loading Web UI from: " << webUrlStr.toStdString() << std::endl;

    // Race-free WebChannel protocol:
    // 1. QML creates the WebChannel + WebEngineView WITHOUT any url bound.
    // 2. Here (after engine.load) we register the bridge onto that channel.
    // 3. Only then do we set the view url -> the page can never init its
    //    QWebChannel client before the "bridge" object is registered.
    engine.load(QUrl(QStringLiteral("qrc:/melyar/ui_cpp/qml/Main.qml")));

    QObject *rootObject = engine.rootObjects().isEmpty() ? nullptr : engine.rootObjects().first();
    if (!rootObject) {
        std::cerr << "FATAL: QML root object failed to load" << std::endl;
        return -1;
    }

    QObject *channelObj = rootObject->findChild<QObject *>(QStringLiteral("appChannel"));
    if (!channelObj) {
        std::cerr << "FATAL: appChannel (QML WebChannel) not found" << std::endl;
        return -1;
    }
    auto *webChannel = qobject_cast<QWebChannel *>(channelObj);
    if (!webChannel) {
        std::cerr << "FATAL: appChannel is not a QWebChannel" << std::endl;
        return -1;
    }
    webChannel->registerObject(QStringLiteral("bridge"), bridgePtr);
    std::cout << "[C++] bridge registered onto QML appChannel" << std::endl;

    QObject *webViewObj = rootObject->findChild<QObject *>(QStringLiteral("webView"));
    if (!webViewObj) {
        std::cerr << "FATAL: webView (QML WebEngineView) not found" << std::endl;
        return -1;
    }
    webViewObj->setProperty("url", webUrlStr);
    std::cout << "[C++] webView url set: " << webUrlStr.toStdString() << std::endl;

    QObject::connect(&engine, &QQmlApplicationEngine::warnings,
                     [](const QList<QQmlError> &warnings) {
        if (!warnings.isEmpty()) {
            std::cerr << "QML Warnings:" << std::endl;
            for (const auto &warning : warnings) {
                std::cerr << "  " << warning.toString().toStdString() << std::endl;
            }
        }
    });

    return app.exec();
}

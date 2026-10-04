#include <clocale>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QIcon>
#include <iostream>

#include "bridge/bridge.hpp"

int main(int argc, char *argv[]) {
    std::setlocale(LC_NUMERIC, "C");
    // Platform and GPU optimization hints for Arch Linux Wayland / X11
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");
    
    QGuiApplication app(argc, argv);
    std::setlocale(LC_NUMERIC, "C");
    app.setApplicationName("Melyar");
    app.setApplicationDisplayName("Melyar - Ultra-Lightweight Music");
    app.setOrganizationName("Melyar");
    app.setOrganizationDomain("melyar.org");

    qmlRegisterSingletonType(QUrl(QStringLiteral("qrc:/melyar/ui_cpp/qml/theme/Style.qml")), "Melyar.Theme", 1, 0, "Style");
    QQmlApplicationEngine engine;

    // Instantiate CXX bridge connecting Qt6 and Rust Core
    auto bridge = std::make_unique<MelyarBridge>();
    engine.rootContext()->setContextProperty("bridge", bridge.get());

    // Load Main QML from Qt Resource System or local file fallback
    const QUrl url(QStringLiteral("qrc:/melyar/ui_cpp/qml/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        // Fallback to local file load if QRC prefix is different
        engine.load(QUrl::fromLocalFile(QStringLiteral("ui_cpp/qml/Main.qml")));
    }

    return app.exec();
}

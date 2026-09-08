#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include "passwordanalyzer.h"
#include "database.h"

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("PasswordGuard"));
    app.setOrganizationName(QStringLiteral("PasswordGuardTeam"));

    PasswordAnalyzer analyzer;
    Database db;
    db.initDatabase();

    QQmlApplicationEngine engine;

    // IR-QML-001: QML ve C++ Arayüzü
    engine.rootContext()->setContextProperty(QStringLiteral("passwordAnalyzer"), &analyzer);
    engine.rootContext()->setContextProperty(QStringLiteral("database"), &db);

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    engine.load(url);

    return QGuiApplication::exec();
}

#include "database.h"
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>
#include <QDir>
#include <QDateTime>
#include <QDebug>

Database::Database(QObject *parent)
    : QObject{parent}
{
}

Database::~Database()
{
    if (m_db.isOpen()) {
        m_db.close();
    }
}

bool Database::initDatabase()
{
    const QString connectionName = QStringLiteral("passwordguard_db_connection");

    if (QSqlDatabase::contains(connectionName)) {
        m_db = QSqlDatabase::database(connectionName);
    } else {
        m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connectionName);
        QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        if (dataDir.isEmpty()) {
            dataDir = QStringLiteral(".");
        }
        QDir().mkpath(dataDir);
        m_db.setDatabaseName(dataDir + QStringLiteral("/passwordguard_history.db"));
    }

    if (!m_db.open()) {
        qWarning() << "Database::initDatabase error:" << m_db.lastError().text();
        return false;
    }

    // FR-DB-001 & FR-DB-002: SQLite veritabanında anonim kayıt tutulur, ham şifre kolonu BULUNMAZ!
    QSqlQuery query(m_db);
    bool success = query.exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS analysis_history ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "password_length INTEGER NOT NULL, "
        "criteria_results TEXT, "
        "score INTEGER NOT NULL, "
        "security_level TEXT NOT NULL, "
        "analysis_date TEXT NOT NULL)"
    ));

    if (!success) {
        qWarning() << "Database::initDatabase failed to create table:" << query.lastError().text();
        return false;
    }

    return true;
}

bool Database::saveAnalysis(int passwordLength, const QString &criteriaResults, int score, const QString &securityLevel)
{
    if (!m_db.isOpen() && !initDatabase()) {
        return false;
    }

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "INSERT INTO analysis_history (password_length, criteria_results, score, security_level, analysis_date) "
        "VALUES (:length, :criteria, :score, :level, :date)"
    ));

    query.bindValue(QStringLiteral(":length"), passwordLength);
    query.bindValue(QStringLiteral(":criteria"), criteriaResults);
    query.bindValue(QStringLiteral(":score"), score);
    query.bindValue(QStringLiteral(":level"), securityLevel);
    query.bindValue(QStringLiteral(":date"), QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss")));

    if (!query.exec()) {
        qWarning() << "Database::saveAnalysis failed:" << query.lastError().text();
        return false;
    }

    emit historyChanged();
    return true;
}

QVariantList Database::getHistory()
{
    QVariantList history;
    if (!m_db.isOpen() && !initDatabase()) {
        return history;
    }

    QSqlQuery query(m_db);
    if (!query.exec(QStringLiteral("SELECT id, password_length, criteria_results, score, security_level, analysis_date FROM analysis_history ORDER BY id DESC"))) {
        qWarning() << "Database::getHistory failed:" << query.lastError().text();
        return history;
    }

    while (query.next()) {
        QVariantMap item;
        item[QStringLiteral("id")] = query.value(0).toInt();
        item[QStringLiteral("passwordLength")] = query.value(1).toInt();
        item[QStringLiteral("criteriaResults")] = query.value(2).toString();
        item[QStringLiteral("score")] = query.value(3).toInt();
        item[QStringLiteral("securityLevel")] = query.value(4).toString();
        item[QStringLiteral("analysisDate")] = query.value(5).toString();
        history.append(item);
    }

    return history;
}

bool Database::clearHistory()
{
    if (!m_db.isOpen() && !initDatabase()) {
        return false;
    }

    QSqlQuery query(m_db);
    if (!query.exec(QStringLiteral("DELETE FROM analysis_history"))) {
        qWarning() << "Database::clearHistory failed:" << query.lastError().text();
        return false;
    }

    query.exec(QStringLiteral("VACUUM"));

    emit historyChanged();
    return true;
}

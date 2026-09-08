#include "database.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QDateTime>
#include <QStandardPaths>
#include <QDir>
#include <QDebug>

Database::Database(QObject *parent)
    : QObject(parent)
{
    initDatabase();
}

Database::~Database()
{
    if (m_db.isOpen()) {
        m_db.close();
    }
}

// SQLite veritabanı bağlantısı ve tablo başlatma
bool Database::initDatabase()
{
    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));

    // Yerel uygulama veri dizininde veritabanı dosyası yolu
    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);
    QString dbPath = dataDir + QStringLiteral("/passwordguard.db");
    m_db.setDatabaseName(dbPath);

    if (!m_db.open()) {
        return false;
    }

    // FR-DB-001, FR-DB-002: Anonim analiz kaydı tablosu oluşturulması (Ham şifre kolonu içermez)
    QSqlQuery query(m_db);
    QString createTableSql = QStringLiteral(
        "CREATE TABLE IF NOT EXISTS analysis_history ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "password_length INTEGER NOT NULL, "
        "criteria_summary TEXT NOT NULL, "
        "score INTEGER NOT NULL, "
        "security_level TEXT NOT NULL, "
        "created_at TEXT NOT NULL"
        ")"
    );

    return query.exec(createTableSql);
}

// FR-DB-001: Anonim Analiz Kaydı
// FR-DB-002, NFR-SEC-001: Ham şifre parametre olarak alınmaz ve saklanmaz
bool Database::saveAnalysis(int passwordLength, const QString &criteriaSummary, int score, const QString &securityLevel)
{
    if (!m_db.isOpen()) {
        return false;
    }

    // Kural 8: SQL sorgularında parametre bağlama kullanımı
    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "INSERT INTO analysis_history (password_length, criteria_summary, score, security_level, created_at) "
        "VALUES (:len, :summary, :score, :level, :created_at)"
    ));

    QString currentDateTime = QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"));

    query.bindValue(QStringLiteral(":len"), passwordLength);
    query.bindValue(QStringLiteral(":summary"), criteriaSummary);
    query.bindValue(QStringLiteral(":score"), score);
    query.bindValue(QStringLiteral(":level"), securityLevel);
    query.bindValue(QStringLiteral(":created_at"), currentDateTime);

    if (query.exec()) {
        emit historyChanged();
        return true;
    }

    return false;
}

// FR-DB-003: Analiz Geçmişinin Listelenmesi (tarih, puan ve güvenlik seviyesi bilgileriyle)
QVariantList Database::getHistory()
{
    QVariantList list;
    if (!m_db.isOpen()) {
        return list;
    }

    QSqlQuery query(QStringLiteral(
        "SELECT id, password_length, criteria_summary, score, security_level, created_at "
        "FROM analysis_history ORDER BY id DESC"
    ), m_db);

    while (query.next()) {
        QVariantMap row;
        row[QStringLiteral("id")] = query.value(0).toInt();
        row[QStringLiteral("passwordLength")] = query.value(1).toInt();
        row[QStringLiteral("criteriaSummary")] = query.value(2).toString();
        row[QStringLiteral("score")] = query.value(3).toInt();
        row[QStringLiteral("securityLevel")] = query.value(4).toString();
        row[QStringLiteral("createdAt")] = query.value(5).toString();
        list.append(row);
    }

    return list;
}

// FR-DB-004: Analiz Geçmişinin Temizlenmesi
bool Database::clearHistory()
{
    if (!m_db.isOpen()) {
        return false;
    }

    QSqlQuery query(m_db);
    if (query.exec(QStringLiteral("DELETE FROM analysis_history"))) {
        emit historyChanged();
        return true;
    }

    return false;
}

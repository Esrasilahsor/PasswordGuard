#ifndef DATABASE_H
#define DATABASE_H

#include <QObject>
#include <QSqlDatabase>
#include <QVariantList>
#include <QVariantMap>

class Database : public QObject
{
    Q_OBJECT
public:
    explicit Database(QObject *parent = nullptr);
    ~Database();

    Q_INVOKABLE bool initDatabase();

    // FR-DB-001 & FR-DB-002 & NFR-SEC-001: Anonymous recording (no raw password parameter)
    Q_INVOKABLE bool saveAnalysis(int passwordLength, const QString &criteriaResults, int score, const QString &securityLevel);

    // FR-DB-003: List analysis history with date, score, security level, and length
    Q_INVOKABLE QVariantList getHistory();

    // FR-DB-004: Clear all analysis history from database
    Q_INVOKABLE bool clearHistory();

signals:
    void historyChanged();

private:
    QSqlDatabase m_db;
};

#endif // DATABASE_H

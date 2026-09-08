#ifndef DATABASE_H
#define DATABASE_H

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVariantMap>
#include <QSqlDatabase>

// FR-DB-001 - FR-DB-004: SQLite Veritabanı Yönetimi
class Database : public QObject
{
    Q_OBJECT

public:
    explicit Database(QObject *parent = nullptr);
    ~Database();

    // Veritabanı bağlantısı ve tablo oluşturma
    bool initDatabase();

    // FR-DB-001: Anonim Analiz Kaydı
    // FR-DB-002, NFR-SEC-001: Ham Şifrenin Saklanmaması
    Q_INVOKABLE bool saveAnalysis(int passwordLength, const QString &criteriaSummary, int score, const QString &securityLevel);

    // FR-DB-003: Analiz Geçmişinin Listelenmesi
    Q_INVOKABLE QVariantList getHistory();

    // FR-DB-004: Analiz Geçmişinin Temizlenmesi
    Q_INVOKABLE bool clearHistory();

signals:
    // FR-DB-004: Geçmiş değiştiğinde QML listesini anında güncelleme sinyali
    void historyChanged();

private:
    QSqlDatabase m_db;
};

#endif // DATABASE_H

#ifndef PASSWORDANALYZER_H
#define PASSWORDANALYZER_H

#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QStringList>
#include <QSet>

// IR-QML-001: QML ve C++ Arayüzü
class PasswordAnalyzer : public QObject
{
    Q_OBJECT

public:
    explicit PasswordAnalyzer(QObject *parent = nullptr);

    // FR-SCORE-001: Güvenlik puanı ve kriterlerin hesaplanması
    // IR-QML-001: QML tarafından erişilebilir analiz işlevi
    Q_INVOKABLE QVariantMap analyzePassword(const QString &password);

private:
    // FR-ANL-011: qrc gömülü yaygın şifreler listesi
    QSet<QString> m_commonPasswords;
    void loadCommonPasswords();

    // FR-ANL-001: Minimum 8 karakter uzunluk kontrolü
    bool checkMinLength8(const QString &password) const;

    // FR-ANL-002: Minimum 12 karakter uzunluk kontrolü
    bool checkExtraLength12(const QString &password) const;

    // FR-ANL-003: Büyük harf kontrolü
    bool checkUppercase(const QString &password) const;

    // FR-ANL-004: Küçük harf kontrolü
    bool checkLowercase(const QString &password) const;

    // FR-ANL-005: Rakam kontrolü
    bool checkDigit(const QString &password) const;

    // FR-ANL-006, FR-ANL-010: Özel karakter kontrolü
    bool checkSpecialChar(const QString &password) const;

    // FR-ANL-007, FR-ANL-011: Yaygın şifre kontrolü
    bool checkCommonPassword(const QString &password) const;

    // FR-ANL-008: Tekrarlayan karakter kontrolü (art arda >= 3 aynı karakter)
    int countRepeatedCharacters(const QString &password) const;

    // FR-ANL-009: Sıralı karakter kontrolü (alfabetik ve sayısal ardışık diziler)
    int countSequentialCharacters(const QString &password) const;

    // FR-SCORE-002 - FR-SCORE-005: Güvenlik seviyesi belirleme
    QString determineSecurityLevel(int score) const;

    // FR-UI-005: İyileştirme önerileri üretimi
    QStringList generateSuggestions(bool len8, bool len12, bool upper, bool lower,
                                    bool digit, bool special, bool isCommon,
                                    int repeatedCount, int sequentialCount) const;
};

#endif // PASSWORDANALYZER_H

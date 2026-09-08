#include "passwordanalyzer.h"
#include <QFile>
#include <QTextStream>
#include <QtGlobal>

PasswordAnalyzer::PasswordAnalyzer(QObject *parent)
    : QObject(parent)
{
    // FR-ANL-011: Gömülü yaygın şifre sözlüğünü yükle
    loadCommonPasswords();
}

// FR-ANL-011: Yaygın Şifre Listesi Kaynağı
void PasswordAnalyzer::loadCommonPasswords()
{
    Q_INIT_RESOURCE(qml);
    m_commonPasswords.clear();
    QFile file(":/resources/common_passwords.txt");
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&file);
        while (!in.atEnd()) {
            QString line = in.readLine().trimmed().toLower();
            if (!line.isEmpty()) {
                m_commonPasswords.insert(line);
            }
        }
        file.close();
    }
}

// FR-ANL-001: Minimum Uzunluk Kontrolü (en az 8 karakter)
bool PasswordAnalyzer::checkMinLength8(const QString &password) const
{
    return password.length() >= 8;
}

// FR-ANL-002: Ek Uzunluk Kontrolü (en az 12 karakter)
bool PasswordAnalyzer::checkExtraLength12(const QString &password) const
{
    return password.length() >= 12;
}

// FR-ANL-003: Büyük Harf Kontrolü (en az bir büyük harf)
bool PasswordAnalyzer::checkUppercase(const QString &password) const
{
    for (const QChar &c : password) {
        if (c.isUpper()) {
            return true;
        }
    }
    return false;
}

// FR-ANL-004: Küçük Harf Kontrolü (en az bir küçük harf)
bool PasswordAnalyzer::checkLowercase(const QString &password) const
{
    for (const QChar &c : password) {
        if (c.isLower()) {
            return true;
        }
    }
    return false;
}

// FR-ANL-005: Rakam Kontrolü (en az bir rakam)
bool PasswordAnalyzer::checkDigit(const QString &password) const
{
    for (const QChar &c : password) {
        if (c.isDigit()) {
            return true;
        }
    }
    return false;
}

// FR-ANL-006, FR-ANL-010: Özel Karakter Kümesi Tanımı
// ASCII standartlarında yer alan !@#$%^&*()_+-=[]{}|;:,.<>?/`~"' sembolleri
bool PasswordAnalyzer::checkSpecialChar(const QString &password) const
{
    const QString specialChars = QStringLiteral("!@#$%^&*()_+-=[]{}|;:,.<>?/`~\"'");
    for (const QChar &c : password) {
        if (specialChars.contains(c)) {
            return true;
        }
    }
    return false;
}

// FR-ANL-007, FR-ANL-011: Yaygın Şifre Kontrolü (büyük/küçük harf duyarsız)
bool PasswordAnalyzer::checkCommonPassword(const QString &password) const
{
    return m_commonPasswords.contains(password.trimmed().toLower());
}

// FR-ANL-008: Tekrarlayan Karakter Kontrolü (art arda üç veya daha fazla aynı karakter)
int PasswordAnalyzer::countRepeatedCharacters(const QString &password) const
{
    int count = 0;
    int n = password.length();
    int i = 0;
    while (i < n) {
        int j = i;
        while (j < n && password[j] == password[i]) {
            j++;
        }
        if (j - i >= 3) {
            count++;
        }
        i = j;
    }
    return count;
}

// FR-ANL-009: Sıralı Karakter Kontrolü (alfabetik ve sayısal ardışık diziler, örn. 1234, 4321, abcd, dcba)
int PasswordAnalyzer::countSequentialCharacters(const QString &password) const
{
    int count = 0;
    int n = password.length();
    if (n < 4) {
        return 0;
    }

    QString lower = password.toLower();
    int i = 0;
    while (i <= n - 4) {
        bool isNumAsc = true;
        bool isNumDesc = true;
        bool isAlphaAsc = true;
        bool isAlphaDesc = true;

        for (int k = 0; k < 3; ++k) {
            QChar c1 = lower[i + k];
            QChar c2 = lower[i + k + 1];

            if (!(c1.isDigit() && c2.isDigit() && c2.unicode() == c1.unicode() + 1)) {
                isNumAsc = false;
            }
            if (!(c1.isDigit() && c2.isDigit() && c2.unicode() == c1.unicode() - 1)) {
                isNumDesc = false;
            }
            if (!(c1.isLetter() && c2.isLetter() && c2.unicode() == c1.unicode() + 1)) {
                isAlphaAsc = false;
            }
            if (!(c1.isLetter() && c2.isLetter() && c2.unicode() == c1.unicode() - 1)) {
                isAlphaDesc = false;
            }
        }

        if (isNumAsc || isNumDesc || isAlphaAsc || isAlphaDesc) {
            count++;
            int step = (isNumAsc || isAlphaAsc) ? 1 : -1;
            bool isNumeric = (isNumAsc || isNumDesc);
            int j = i + 3;
            while (j + 1 < n) {
                QChar cCurr = lower[j];
                QChar cNext = lower[j + 1];
                if (isNumeric && cCurr.isDigit() && cNext.isDigit() && cNext.unicode() == cCurr.unicode() + step) {
                    j++;
                } else if (!isNumeric && cCurr.isLetter() && cNext.isLetter() && cNext.unicode() == cCurr.unicode() + step) {
                    j++;
                } else {
                    break;
                }
            }
            i = j + 1;
        } else {
            i++;
        }
    }
    return count;
}

// FR-SCORE-002 - FR-SCORE-005: Güvenlik Seviyesi Belirleme
QString PasswordAnalyzer::determineSecurityLevel(int score) const
{
    // FR-SCORE-002: Weak Seviyesi (0 ile 30 arasında)
    if (score <= 30) {
        return QStringLiteral("Weak");
    }
    // FR-SCORE-003: Medium Seviyesi (31 ile 60 arasında)
    if (score <= 60) {
        return QStringLiteral("Medium");
    }
    // FR-SCORE-004: Strong Seviyesi (61 ile 80 arasında)
    if (score <= 80) {
        return QStringLiteral("Strong");
    }
    // FR-SCORE-005: Very Strong Seviyesi (81 ile 100 arasında)
    return QStringLiteral("Very Strong");
}

// FR-UI-005: İyileştirme Önerileri
QStringList PasswordAnalyzer::generateSuggestions(bool len8, bool len12, bool upper, bool lower,
                                                 bool digit, bool special, bool isCommon,
                                                 int repeatedCount, int sequentialCount) const
{
    QStringList suggestions;

    if (!len8) {
        suggestions.append(QStringLiteral("Şifrenizi en az 8 karakter olacak şekilde uzatın."));
    }
    if (!len12) {
        suggestions.append(QStringLiteral("Daha güçlü bir şifre için en az 12 karakter kullanın."));
    }
    if (!upper) {
        suggestions.append(QStringLiteral("En az bir büyük harf ekleyin."));
    }
    if (!lower) {
        suggestions.append(QStringLiteral("En az bir küçük harf ekleyin."));
    }
    if (!digit) {
        suggestions.append(QStringLiteral("En az bir rakam ekleyin."));
    }
    if (!special) {
        suggestions.append(QStringLiteral("En az bir özel karakter ekleyin."));
    }
    if (isCommon) {
        suggestions.append(QStringLiteral("Yaygın kullanılan şifrelerden kaçının."));
    }
    if (repeatedCount > 0) {
        suggestions.append(QStringLiteral("Aynı karakteri art arda 3 veya daha fazla kez kullanmaktan kaçının."));
    }
    if (sequentialCount > 0) {
        suggestions.append(QStringLiteral("1234 veya abcd gibi sıralı karakter dizilerinden kaçının."));
    }

    return suggestions;
}

// FR-SCORE-001: Güvenlik Puanı Hesaplama
// IR-QML-001: QML tarafından çağrılabilir analiz fonksiyonu
QVariantMap PasswordAnalyzer::analyzePassword(const QString &password)
{
    QVariantMap result;

    // Kriter kontrolleri
    bool len8 = checkMinLength8(password);
    bool len12 = checkExtraLength12(password);
    bool upper = checkUppercase(password);
    bool lower = checkLowercase(password);
    bool digit = checkDigit(password);
    bool special = checkSpecialChar(password);
    bool isCommon = checkCommonPassword(password);
    int repeatedCount = countRepeatedCharacters(password);
    int sequentialCount = countSequentialCharacters(password);

    // FR-SCORE-006: Taban puan 0
    int score = 0;

    // FR-SCORE-006: Temel Uzunluk Katkısı (+15 puan)
    if (len8) {
        score += 15;
    }
    // FR-SCORE-007: Ek Uzunluk Katkısı (+15 puan)
    if (len12) {
        score += 15;
    }
    // FR-SCORE-008: Büyük Harf Puan Katkısı (+15 puan)
    if (upper) {
        score += 15;
    }
    // FR-SCORE-009: Küçük Harf Puan Katkısı (+15 puan)
    if (lower) {
        score += 15;
    }
    // FR-SCORE-010: Rakam Puan Katkısı (+15 puan)
    if (digit) {
        score += 15;
    }
    // FR-SCORE-011: Özel Karakter Puan Katkısı (+25 puan)
    if (special) {
        score += 25;
    }

    // FR-SCORE-013: Ardışık veya Tekrarlayan Karakter Puan Kesintisi (-15 puan her biri)
    int penalties = (repeatedCount + sequentialCount) * 15;
    score -= penalties;

    // FR-SCORE-012: Yaygın Şifre Puan Sıfırlama (bağımsız olarak doğrudan 0)
    if (isCommon) {
        score = 0;
    }

    // FR-SCORE-014: Puanın 0-100 Aralığında Sınırlandırılması
    if (score < 0) {
        score = 0;
    }
    if (score > 100) {
        score = 100;
    }

    // Güvenlik seviyesi
    QString level = determineSecurityLevel(score);

    // İyileştirme önerileri
    QStringList suggestions = generateSuggestions(len8, len12, upper, lower, digit, special,
                                                  isCommon, repeatedCount, sequentialCount);

    // Kriter özeti (Veritabanı için)
    QStringList summaryItems;
    if (len8) summaryItems << QStringLiteral("Min8");
    if (len12) summaryItems << QStringLiteral("Min12");
    if (upper) summaryItems << QStringLiteral("Upper");
    if (lower) summaryItems << QStringLiteral("Lower");
    if (digit) summaryItems << QStringLiteral("Digit");
    if (special) summaryItems << QStringLiteral("Special");
    if (isCommon) summaryItems << QStringLiteral("Common");
    if (repeatedCount > 0) summaryItems << QStringLiteral("Repeated(%1)").arg(repeatedCount);
    if (sequentialCount > 0) summaryItems << QStringLiteral("Sequential(%1)").arg(sequentialCount);
    QString criteriaSummary = summaryItems.join(QStringLiteral(", "));

    // QML için kriter haritası
    QVariantMap criteriaMap;
    criteriaMap[QStringLiteral("minLength8")] = len8;
    criteriaMap[QStringLiteral("extraLength12")] = len12;
    criteriaMap[QStringLiteral("hasUppercase")] = upper;
    criteriaMap[QStringLiteral("hasLowercase")] = lower;
    criteriaMap[QStringLiteral("hasDigit")] = digit;
    criteriaMap[QStringLiteral("hasSpecialChar")] = special;
    criteriaMap[QStringLiteral("isCommonPassword")] = isCommon;
    criteriaMap[QStringLiteral("hasRepeated")] = (repeatedCount > 0);
    criteriaMap[QStringLiteral("hasSequential")] = (sequentialCount > 0);

    result[QStringLiteral("score")] = score;
    result[QStringLiteral("level")] = level;
    result[QStringLiteral("length")] = password.length();
    result[QStringLiteral("criteria")] = criteriaMap;
    result[QStringLiteral("suggestions")] = suggestions;
    result[QStringLiteral("criteriaSummary")] = criteriaSummary;

    return result;
}

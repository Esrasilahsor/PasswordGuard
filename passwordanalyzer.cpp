#include "passwordanalyzer.h"
#include <QFile>
#include <QTextStream>
#include <QDebug>
#include <QtGlobal>

namespace {
    // FR-ANL-010: ASCII standard special characters
    const QString SPECIAL_CHARACTERS = QStringLiteral("!@#$%^&*()_+-=[]{}|;:,.<>?/`~\"'");
}

PasswordAnalyzer::PasswordAnalyzer(QObject *parent)
    : QObject{parent}
{
    loadCommonPasswords();
}

void PasswordAnalyzer::loadCommonPasswords()
{
    if (m_passwordsLoaded) {
        return;
    }

    // Try embedded resource first (FR-ANL-011)
    QString filePath = QStringLiteral(":/data/Pwdb_top-1000.txt");
    QFile file(filePath);

    // Fallback to local data folder if running without resource or in test environment
    if (!file.exists()) {
        file.setFileName(QStringLiteral("data/Pwdb_top-1000.txt"));
    }

    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&file);
        while (!in.atEnd()) {
            QString line = in.readLine().trimmed();
            if (!line.isEmpty()) {
                m_commonPasswords.insert(line.toLower());
            }
        }
        file.close();
        m_passwordsLoaded = true;
        qDebug() << "PasswordAnalyzer: Loaded" << m_commonPasswords.size() << "common passwords.";
    } else {
        qWarning() << "PasswordAnalyzer: Failed to open common password file:" << file.errorString();
    }
}

bool PasswordAnalyzer::isCommonPassword(const QString &password) const
{
    if (m_commonPasswords.isEmpty()) {
        return false;
    }
    return m_commonPasswords.contains(password.toLower());
}

int PasswordAnalyzer::countRepeatedPatterns(const QString &password) const
{
    // FR-ANL-008: 3 or more identical consecutive characters (e.g. "aaa", "111", "!!!")
    int count = 0;
    int len = password.length();
    if (len < 3) return 0;

    int currentRun = 1;
    for (int i = 1; i < len; ++i) {
        if (password[i] == password[i - 1]) {
            currentRun++;
        } else {
            if (currentRun >= 3) {
                count++;
            }
            currentRun = 1;
        }
    }
    if (currentRun >= 3) {
        count++;
    }

    return count;
}

int PasswordAnalyzer::countSequentialPatterns(const QString &password) const
{
    // FR-ANL-009: Defined sequential sequences like 1234, 4321, abcd, dcba (length >= 4)
    int count = 0;
    QString lower = password.toLower();
    int n = lower.length();
    if (n < 4) return 0;

    int i = 0;
    while (i < n) {
        int runLen = 1;
        int dir = 0; // +1 ascending, -1 descending

        while (i + runLen < n) {
            QChar prev = lower[i + runLen - 1];
            QChar curr = lower[i + runLen];

            bool bothDigits = prev.isDigit() && curr.isDigit();
            bool bothLetters = (prev >= 'a' && prev <= 'z') && (curr >= 'a' && curr <= 'z');

            if (!bothDigits && !bothLetters) {
                break;
            }

            int diff = curr.unicode() - prev.unicode();
            if (runLen == 1) {
                if (diff == 1 || diff == -1) {
                    dir = diff;
                    runLen++;
                } else {
                    break;
                }
            } else {
                if (diff == dir) {
                    runLen++;
                } else {
                    break;
                }
            }
        }

        if (runLen >= 4) {
            count++;
            i += runLen;
        } else {
            i++;
        }
    }

    return count;
}

QVariantMap PasswordAnalyzer::analyzePassword(const QString &password)
{
    QVariantMap result;

    // FR-INPUT-002: Boş Şifre Kontrolü
    if (password.isEmpty()) {
        result[QStringLiteral("isValid")] = false;
        result[QStringLiteral("errorMessage")] = QStringLiteral("Lütfen analiz için bir şifre giriniz.");
        return result;
    }

    result[QStringLiteral("isValid")] = true;
    result[QStringLiteral("errorMessage")] = QString();

    int length = password.length();
    result[QStringLiteral("length")] = length;

    // FR-ANL-001 & FR-ANL-002: Uzunluk kontrolleri
    bool lengthAtLeast8 = (length >= 8);
    bool lengthAtLeast12 = (length >= 12);
    result[QStringLiteral("lengthAtLeast8")] = lengthAtLeast8;
    result[QStringLiteral("lengthAtLeast12")] = lengthAtLeast12;

    // FR-ANL-003, FR-ANL-004, FR-ANL-005, FR-ANL-006 & FR-ANL-010: Karakter kümesi kontrolleri
    bool hasUpper = false;
    bool hasLower = false;
    bool hasDigit = false;
    bool hasSpecial = false;

    for (const QChar &ch : password) {
        if (ch.isUpper()) {
            hasUpper = true;
        } else if (ch.isLower()) {
            hasLower = true;
        } else if (ch.isDigit()) {
            hasDigit = true;
        } else if (SPECIAL_CHARACTERS.contains(ch)) {
            hasSpecial = true;
        }
    }

    result[QStringLiteral("hasUpper")] = hasUpper;
    result[QStringLiteral("hasLower")] = hasLower;
    result[QStringLiteral("hasDigit")] = hasDigit;
    result[QStringLiteral("hasSpecial")] = hasSpecial;

    // FR-ANL-007 & FR-ANL-011: Yaygın şifre kontrolü
    bool common = isCommonPassword(password);
    result[QStringLiteral("isCommon")] = common;

    // FR-ANL-008: Tekrarlayan karakter kontrolü
    int repeatedPatterns = countRepeatedPatterns(password);
    result[QStringLiteral("repeatedPatterns")] = repeatedPatterns;
    result[QStringLiteral("hasNoRepeated")] = (repeatedPatterns == 0);

    // FR-ANL-009: Sıralı karakter kontrolü
    int sequentialPatterns = countSequentialPatterns(password);
    result[QStringLiteral("sequentialPatterns")] = sequentialPatterns;
    result[QStringLiteral("hasNoSequential")] = (sequentialPatterns == 0);

    // PUAN HESAPLAMA (FR-SCORE-001..014)
    int score = 0; // FR-SCORE-006: Taban puan 0

    if (lengthAtLeast8) {
        score += 15; // FR-SCORE-006: En az 8 karakter -> +15
    }
    if (lengthAtLeast12) {
        score += 15; // FR-SCORE-007: En az 12 karakter -> +15
    }
    if (hasUpper) {
        score += 15; // FR-SCORE-008: Büyük harf -> +15
    }
    if (hasLower) {
        score += 15; // FR-SCORE-009: Küçük harf -> +15
    }
    if (hasDigit) {
        score += 15; // FR-SCORE-010: Rakam -> +15
    }
    if (hasSpecial) {
        score += 25; // FR-SCORE-011: Özel karakter -> +25
    }

    // FR-SCORE-012: Yaygın Şifre Puan Sıfırlama
    if (common) {
        score = 0;
    } else {
        // FR-SCORE-013: Ardışık veya Tekrarlayan Karakter Puan Kesintisi
        int penalty = (repeatedPatterns + sequentialPatterns) * 15;
        score -= penalty;
    }

    // FR-SCORE-014: Puanın 0-100 Aralığında Sınırlandırılması
    if (score < 0) score = 0;
    if (score > 100) score = 100;

    result[QStringLiteral("score")] = score;

    // GÜVENLİK SEVİYESİ (FR-SCORE-002..005)
    QString level;
    if (score <= 30) {
        level = QStringLiteral("Weak");
    } else if (score <= 60) {
        level = QStringLiteral("Medium");
    } else if (score <= 80) {
        level = QStringLiteral("Strong");
    } else {
        level = QStringLiteral("Very Strong");
    }
    result[QStringLiteral("securityLevel")] = level;

    // İYİLEŞTİRME ÖNERİLERİ (FR-UI-005)
    QStringList suggestions;
    if (common) {
        suggestions << QStringLiteral("Şifreniz en yaygın kullanılan şifreler listesinde bulunuyor. Lütfen tahmin edilmesi zor ve özgün bir şifre seçin.");
    }
    if (!lengthAtLeast8) {
        suggestions << QStringLiteral("Şifre uzunluğunu en az 8 karaktere çıkarın (+15 puan).");
    } else if (!lengthAtLeast12) {
        suggestions << QStringLiteral("Daha yüksek güvenlik için şifrenizi en az 12 karaktere uzatın (+15 puan).");
    }
    if (!hasUpper) {
        suggestions << QStringLiteral("Şifrenize en az bir büyük harf (A-Z) ekleyin (+15 puan).");
    }
    if (!hasLower) {
        suggestions << QStringLiteral("Şifrenize en az bir küçük harf (a-z) ekleyin (+15 puan).");
    }
    if (!hasDigit) {
        suggestions << QStringLiteral("Şifrenize en az bir rakam (0-9) ekleyin (+15 puan).");
    }
    if (!hasSpecial) {
        suggestions << QStringLiteral("Şifrenize en az bir özel karakter (!@#$%^&*...) ekleyin (+25 puan).");
    }
    if (repeatedPatterns > 0) {
        suggestions << QStringLiteral("Art arda tekrarlayan karakterleri (örn. aaa, 111) kaldırarak puan kesintisini (-%1 puan) önleyin.").arg(repeatedPatterns * 15);
    }
    if (sequentialPatterns > 0) {
        suggestions << QStringLiteral("Sıralı karakter dizilerini (örn. 1234, abcd) kullanmaktan kaçınarak puan kesintisini (-%1 puan) önleyin.").arg(sequentialPatterns * 15);
    }

    result[QStringLiteral("suggestions")] = suggestions;

    // Kriter Özeti (Veritabanı için)
    QStringList criteriaSummary;
    if (lengthAtLeast8) criteriaSummary << QStringLiteral("8+ Krk");
    if (lengthAtLeast12) criteriaSummary << QStringLiteral("12+ Krk");
    if (hasUpper) criteriaSummary << QStringLiteral("Büyük Harf");
    if (hasLower) criteriaSummary << QStringLiteral("Küçük Harf");
    if (hasDigit) criteriaSummary << QStringLiteral("Rakam");
    if (hasSpecial) criteriaSummary << QStringLiteral("Özel Karakter");
    if (!common) criteriaSummary << QStringLiteral("Özgün");
    if (repeatedPatterns == 0) criteriaSummary << QStringLiteral("Tekrarsız");
    if (sequentialPatterns == 0) criteriaSummary << QStringLiteral("Sırasız");

    result[QStringLiteral("criteriaSummary")] = criteriaSummary.join(QStringLiteral(", "));

    return result;
}

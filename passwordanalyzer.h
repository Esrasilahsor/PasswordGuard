#ifndef PASSWORDANALYZER_H
#define PASSWORDANALYZER_H

#include <QObject>
#include <QString>
#include <QSet>
#include <QVariantMap>
#include <QStringList>

class PasswordAnalyzer : public QObject
{
    Q_OBJECT
public:
    explicit PasswordAnalyzer(QObject *parent = nullptr);

    // Q_INVOKABLE method to analyze a password and return structured results to QML
    Q_INVOKABLE QVariantMap analyzePassword(const QString &password);

    // Helper checks
    bool isCommonPassword(const QString &password) const;
    int countRepeatedPatterns(const QString &password) const;
    int countSequentialPatterns(const QString &password) const;

private:
    void loadCommonPasswords();
    QSet<QString> m_commonPasswords;
    bool m_passwordsLoaded = false;
};

#endif // PASSWORDANALYZER_H

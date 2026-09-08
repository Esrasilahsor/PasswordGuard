import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: root
    width: 1200
    height: 800
    minimumWidth: 860
    minimumHeight: 640
    visible: true
    visibility: Window.Maximized
    title: qsTr("PasswordGuard - Güvenli Şifre Analiz Sistemi")
    color: root.theme.windowBg

    Behavior on color {
        ColorAnimation { duration: 250 }
    }

    // F11 Tam Ekran Kısayolu
    Shortcut {
        sequence: "F11"
        onActivated: {
            if (root.visibility === Window.FullScreen) {
                root.visibility = Window.Maximized;
            } else {
                root.visibility = Window.FullScreen;
            }
        }
    }

    // Tema Durumu (Gece / Gündüz)
    property bool isDarkTheme: true

    // Merkezi Tema Tasarım Sistemi (Design Tokens)
    readonly property var theme: ({
        // Genel Pencere ve Kartlar
        windowBg: isDarkTheme ? "#0F172A" : "#F1F5F9",
        cardBg: isDarkTheme ? "#1E293B" : "#FFFFFF",
        cardBorder: isDarkTheme ? "#334155" : "#E2E8F0",
        subCardBg: isDarkTheme ? "#0F172A" : "#F8FAFC",
        subCardBorder: isDarkTheme ? "#334155" : "#E2E8F0",

        // Metin Renkleri
        textPrimary: isDarkTheme ? "#F8FAFC" : "#0F172A",
        textSecondary: isDarkTheme ? "#94A3B8" : "#475569",
        textMuted: isDarkTheme ? "#64748B" : "#94A3B8",

        // Vurgu ve Butonlar
        primary: "#6366F1",
        buttonBg: isDarkTheme ? "#0F172A" : "#F1F5F9",
        buttonHover: isDarkTheme ? "#334155" : "#E2E8F0",
        buttonDown: isDarkTheme ? "#1E293B" : "#CBD5E1",
        buttonBorder: isDarkTheme ? "#475569" : "#CBD5E1",
        buttonText: isDarkTheme ? "#CBD5E1" : "#334155",

        // Giriş Alanı
        inputBg: isDarkTheme ? "#0F172A" : "#F8FAFC",
        inputBorder: isDarkTheme ? "#334155" : "#CBD5E1",
        inputText: isDarkTheme ? "#F8FAFC" : "#0F172A",
        inputPlaceholder: isDarkTheme ? "#475569" : "#94A3B8",

        // Göster/Gizle Butonu
        toggleBtnBg: isDarkTheme ? "#1E293B" : "#F1F5F9",
        toggleBtnHover: isDarkTheme ? "#334155" : "#E2E8F0",
        toggleBtnBorder: isDarkTheme ? "#475569" : "#CBD5E1",
        toggleBtnStroke: isDarkTheme ? "#94A3B8" : "#64748B",

        // Canlı Kriter Durum Renkleri
        critNeutralBg: isDarkTheme ? "#0F172A" : "#F8FAFC",
        critNeutralBorder: isDarkTheme ? "#334155" : "#E2E8F0",
        critNeutralText: isDarkTheme ? "#94A3B8" : "#64748B",
        critNeutralPoints: isDarkTheme ? "#64748B" : "#94A3B8",
        critNeutralIconBg: isDarkTheme ? "#1E293B" : "#E2E8F0",
        critNeutralIconBorder: isDarkTheme ? "#475569" : "#CBD5E1",
        critNeutralIconText: isDarkTheme ? "#64748B" : "#94A3B8",

        critPassedBg: isDarkTheme ? "#143C2E" : "#ECFDF5",
        critPassedBorder: isDarkTheme ? "#10B981" : "#34D399",
        critPassedText: isDarkTheme ? "#F1F5F9" : "#065F46",
        critPassedPoints: isDarkTheme ? "#34D399" : "#059669",
        critPassedIconBg: isDarkTheme ? "#064E3B" : "#D1FAE5",
        critPassedIconBorder: isDarkTheme ? "#10B981" : "#10B981",
        critPassedIconText: isDarkTheme ? "#10B981" : "#059669",

        critUnmetBg: isDarkTheme ? "#281D26" : "#FEF2F2",
        critUnmetBorder: isDarkTheme ? "#4B232E" : "#FECACA",
        critUnmetText: isDarkTheme ? "#E2E8F0" : "#991B1B",
        critUnmetPoints: isDarkTheme ? "#F87171" : "#DC2626",
        critUnmetIconBg: isDarkTheme ? "#450A0A" : "#FEE2E2",
        critUnmetIconBorder: isDarkTheme ? "#EF4444" : "#EF4444",
        critUnmetIconText: isDarkTheme ? "#EF4444" : "#DC2626",

        // Geçmiş Tablosu
        historyHeaderBg: isDarkTheme ? "#0F172A" : "#F1F5F9",
        historyRowBg: isDarkTheme ? "#0F172A" : "#FFFFFF",
        historyRowBorder: isDarkTheme ? "#334155" : "#E2E8F0",

        // Diyalog
        dialogBg: isDarkTheme ? "#1E293B" : "#FFFFFF",
        dialogBorder: isDarkTheme ? "#475569" : "#E2E8F0"
    })

    // Sayfa Durum Değişkenleri
    property bool isPasswordVisible: false
    property bool hasAnalyzed: false
    property var lastAnalysis: null
    property string errorMessage: ""
    property var historyList: []

    // Canlı Analiz (Şifre kutusuna yazıldıkça anlık reaktif güncelleme)
    property var liveAnalysis: passwordInput && passwordInput.text.length > 0 ? passwordAnalyzer.analyzePassword(passwordInput.text) : null

    function countPassedCriteria() {
        if (!liveAnalysis) return 0;
        var count = 0;
        if (liveAnalysis.lengthAtLeast8) count++;
        if (liveAnalysis.lengthAtLeast12) count++;
        if (liveAnalysis.hasUpper) count++;
        if (liveAnalysis.hasLower) count++;
        if (liveAnalysis.hasDigit) count++;
        if (liveAnalysis.hasSpecial) count++;
        if (!liveAnalysis.isCommon) count++;
        if (liveAnalysis.hasNoRepeated) count++;
        if (liveAnalysis.hasNoSequential) count++;
        return count;
    }

    Component.onCompleted: {
        refreshHistory();
    }

    Connections {
        target: database
        function onHistoryChanged() {
            refreshHistory();
        }
    }

    function refreshHistory() {
        if (typeof database !== "undefined" && database) {
            historyList = database.getHistory();
        }
    }

    function runAnalysis() {
        errorMessage = "";
        var pwd = passwordInput.text;

        // FR-INPUT-002: Boş Şifre Kontrolü
        if (!pwd || pwd.length === 0) {
            errorMessage = "Lütfen analiz işlemi için en az bir şifre giriniz.";
            hasAnalyzed = false;
            lastAnalysis = null;
            return;
        }

        // IR-QML-001: PasswordAnalyzer C++ sınıfı üzerinden analiz
        var result = passwordAnalyzer.analyzePassword(pwd);
        if (!result.isValid) {
            errorMessage = result.errorMessage;
            hasAnalyzed = false;
            lastAnalysis = null;
            return;
        }

        lastAnalysis = result;
        hasAnalyzed = true;

        // FR-DB-001 & FR-DB-002 & NFR-SEC-001: Ham şifre asla veritabanına iletilmez!
        database.saveAnalysis(result.length, result.criteriaSummary, result.score, result.securityLevel);
    }

    function clearAll() {
        // FR-UI-006: Şifre alanını ve ekrandaki son analiz sonuçlarını temizleme
        passwordInput.text = "";
        hasAnalyzed = false;
        lastAnalysis = null;
        errorMessage = "";
    }

    // Renk Yardımcıları (Koyu ve Açık Tema Uyumlu)
    function getLevelColor(level) {
        if (level === "Weak") return isDarkTheme ? "#EF4444" : "#DC2626";
        if (level === "Medium") return isDarkTheme ? "#F59E0B" : "#D97706";
        if (level === "Strong") return isDarkTheme ? "#3B82F6" : "#2563EB";
        if (level === "Very Strong") return isDarkTheme ? "#10B981" : "#059669";
        return isDarkTheme ? "#64748B" : "#94A3B8";
    }

    function getLevelBgColor(level) {
        if (isDarkTheme) {
            if (level === "Weak") return "#3B181F";
            if (level === "Medium") return "#3B2D18";
            if (level === "Strong") return "#172E4C";
            if (level === "Very Strong") return "#143C2E";
            return "#1E293B";
        } else {
            if (level === "Weak") return "#FEE2E2";
            if (level === "Medium") return "#FEF3C7";
            if (level === "Strong") return "#DBEAFE";
            if (level === "Very Strong") return "#D1FAE5";
            return "#F1F5F9";
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            // Ekrana ferahça yayılma: geniş ekranlarda 1360px'e kadar esneme
            width: Math.min(parent.width - 64, 1360)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 24
            Layout.topMargin: 24
            Layout.bottomMargin: 32

            // ================= HEADER =================
            Rectangle {
                Layout.fillWidth: true
                height: 84
                color: root.theme.cardBg
                radius: 12
                border.color: root.theme.cardBorder
                border.width: 1

                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    Rectangle {
                        width: 50
                        height: 50
                        radius: 10
                        color: root.isDarkTheme ? "#312E81" : "#EEF2FF"
                        border.color: root.isDarkTheme ? "#6366F1" : "#818CF8"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "🛡️"
                            font.pixelSize: 24
                        }
                    }

                    ColumnLayout {
                        spacing: 4
                        Text {
                            text: "PasswordGuard"
                            color: root.theme.textPrimary
                            font.pixelSize: 22
                            font.bold: true
                        }
                        Text {
                            text: "Gelişmiş Güvenlik Kriterleri ve Anonim Şifre Analiz Sistemi"
                            color: root.theme.textSecondary
                            font.pixelSize: 13
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Header Aksiyonları (Tema, Tam Ekran ve Güvenlik Rozeti)
                    RowLayout {
                        spacing: 10

                        // Gece / Gündüz Tema Değiştirme Butonu
                        Button {
                            id: themeToggleBtn
                            implicitHeight: 38
                            implicitWidth: 124
                            hoverEnabled: true

                            background: Rectangle {
                                color: themeToggleBtn.down ? root.theme.buttonDown : (themeToggleBtn.hovered ? root.theme.buttonHover : root.theme.subCardBg)
                                radius: 8
                                border.color: themeToggleBtn.hovered ? root.theme.primary : root.theme.cardBorder
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                            }

                            contentItem: RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: root.isDarkTheme ? "☀️" : "🌙"
                                    font.pixelSize: 14
                                }
                                Text {
                                    text: root.isDarkTheme ? "Açık Tema" : "Koyu Tema"
                                    color: root.theme.textPrimary
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            ToolTip.visible: themeToggleBtn.hovered
                            ToolTip.delay: 250
                            ToolTip.text: root.isDarkTheme ? "Gündüz (Açık) Moduna Geç" : "Gece (Koyu) Moduna Geç"
                            onClicked: {
                                root.isDarkTheme = !root.isDarkTheme;
                            }
                        }

                        // Tam Ekran Aç/Kapat Butonu
                        Button {
                            id: fullscreenToggleBtn
                            implicitHeight: 38
                            implicitWidth: 38
                            hoverEnabled: true

                            background: Rectangle {
                                color: fullscreenToggleBtn.down ? root.theme.buttonDown : (fullscreenToggleBtn.hovered ? root.theme.buttonHover : root.theme.subCardBg)
                                radius: 8
                                border.color: fullscreenToggleBtn.hovered ? root.theme.primary : root.theme.cardBorder
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                            }

                            contentItem: Text {
                                text: root.visibility === Window.FullScreen ? "🗗" : "🗖"
                                font.pixelSize: 15
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                color: root.theme.textPrimary
                            }

                            ToolTip.visible: fullscreenToggleBtn.hovered
                            ToolTip.delay: 250
                            ToolTip.text: root.visibility === Window.FullScreen ? "Tam Ekrandan Çık (F11)" : "Tam Ekrana Geç (F11)"
                            onClicked: {
                                if (root.visibility === Window.FullScreen) {
                                    root.visibility = Window.Maximized;
                                } else {
                                    root.visibility = Window.FullScreen;
                                }
                            }
                        }

                        // Güvenlik Rozeti
                        Rectangle {
                            color: root.theme.subCardBg
                            radius: 8
                            border.color: root.theme.subCardBorder
                            border.width: 1
                            implicitWidth: secInfoText.implicitWidth + 24
                            implicitHeight: 38

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    text: "🔒"
                                    font.pixelSize: 13
                                }
                                Text {
                                    id: secInfoText
                                    text: "Ham şifreler asla saklanmaz"
                                    color: "#10B981"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
            }

            // ================= ŞİFRE GİRİŞ KARTI =================
            Rectangle {
                Layout.fillWidth: true
                color: root.theme.cardBg
                radius: 12
                border.color: root.theme.cardBorder
                border.width: 1
                implicitHeight: inputCol.implicitHeight + 40

                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                ColumnLayout {
                    id: inputCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Şifre Girişi"
                            color: root.theme.textPrimary
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        // FR-INPUT-004: Maksimum Uzunluk Sınırı (128 karakter)
                        Text {
                            text: passwordInput.text.length + " / 128 karakter"
                            color: passwordInput.text.length > 120 ? "#F59E0B" : root.theme.textMuted
                            font.pixelSize: 12
                        }
                    }

                    // Giriş Kutusu + Göster/Gizle Butonu
                    Rectangle {
                        Layout.fillWidth: true
                        height: 50
                        color: root.theme.inputBg
                        radius: 8
                        border.color: passwordInput.activeFocus ? root.theme.primary : root.theme.inputBorder
                        border.width: passwordInput.activeFocus ? 2 : 1

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 8
                            spacing: 8

                            TextField {
                                id: passwordInput
                                Layout.fillWidth: true
                                color: root.theme.inputText
                                font.pixelSize: 15
                                placeholderText: "Analiz etmek istediğiniz şifreyi yazın..."
                                placeholderTextColor: root.theme.inputPlaceholder
                                background: null
                                selectByMouse: true
                                maximumLength: 128
                                echoMode: root.isPasswordVisible ? TextInput.Normal : TextInput.Password

                                onAccepted: {
                                    runAnalysis();
                                }
                            }

                            // FR-INPUT-005: Göster / Gizle Butonu (Yüksek Kontrastlı ve Vektörel İkon)
                            Button {
                                id: toggleVisibilityBtn
                                implicitWidth: 42
                                implicitHeight: 36
                                hoverEnabled: true

                                background: Rectangle {
                                    color: toggleVisibilityBtn.down ? "#4338CA" : (toggleVisibilityBtn.hovered ? root.theme.toggleBtnHover : root.theme.toggleBtnBg)
                                    radius: 6
                                    border.color: toggleVisibilityBtn.hovered ? root.theme.primary : root.theme.toggleBtnBorder
                                    border.width: 1.5

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }
                                }

                                contentItem: Item {
                                    anchors.fill: parent

                                    Canvas {
                                        id: eyeCanvas
                                        anchors.centerIn: parent
                                        width: 22
                                        height: 18

                                        property bool isVisible: root.isPasswordVisible
                                        property bool isHovered: toggleVisibilityBtn.hovered
                                        property bool isDown: toggleVisibilityBtn.down
                                        property bool isDark: root.isDarkTheme

                                        onIsVisibleChanged: requestPaint()
                                        onIsHoveredChanged: requestPaint()
                                        onIsDownChanged: requestPaint()
                                        onIsDarkChanged: requestPaint()

                                        onPaint: {
                                            var ctx = getContext("2d");
                                            ctx.clearRect(0, 0, width, height);

                                            var strokeColor = isDown
                                                ? "#A5B4FC"
                                                : (isHovered
                                                    ? (root.isDarkTheme ? "#FFFFFF" : "#4338CA")
                                                    : (isVisible ? root.theme.primary : root.theme.toggleBtnStroke));

                                            ctx.strokeStyle = strokeColor;
                                            ctx.fillStyle = strokeColor;
                                            ctx.lineWidth = 1.8;
                                            ctx.lineCap = "round";
                                            ctx.lineJoin = "round";

                                            // Göz dış hatları
                                            ctx.beginPath();
                                            ctx.moveTo(2, height / 2);
                                            ctx.quadraticCurveTo(width / 2, -1, width - 2, height / 2);
                                            ctx.quadraticCurveTo(width / 2, height + 1, 2, height / 2);
                                            ctx.stroke();

                                            // Göz bebeği
                                            ctx.beginPath();
                                            ctx.arc(width / 2, height / 2, 3, 0, 2 * Math.PI);
                                            ctx.fill();

                                            // Şifre gizliyken / maskeliyken üstünü çizen diyagonal çizgi
                                            if (!isVisible) {
                                                ctx.beginPath();
                                                ctx.moveTo(3, 2);
                                                ctx.lineTo(width - 3, height - 2);
                                                ctx.stroke();
                                            }
                                        }
                                    }
                                }

                                ToolTip.visible: toggleVisibilityBtn.hovered
                                ToolTip.delay: 200
                                ToolTip.text: root.isPasswordVisible ? "Şifreyi Gizle" : "Şifreyi Göster"
                                onClicked: {
                                    root.isPasswordVisible = !root.isPasswordVisible;
                                }
                            }
                        }
                    }

                    // CANLI GÜVENLİK KRİTERLERİ KONTROL PANELİ
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 4
                        spacing: 8

                        Text {
                            text: "Canlı Güvenlik Kriterleri"
                            color: root.theme.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                        }

                        Text {
                            text: "•"
                            color: root.theme.textMuted
                            font.pixelSize: 12
                        }

                        Text {
                            text: passwordInput.text.length === 0 ? "Şifrenizi yazarken kriterler anlık olarak kontrol edilir" : "Kriterleri tamamlayarak şifrenizi güçlendirin"
                            color: root.theme.textSecondary
                            font.pixelSize: 12
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            visible: passwordInput.text.length > 0
                            height: 24
                            radius: 12
                            color: root.theme.subCardBg
                            border.color: root.theme.subCardBorder
                            border.width: 1
                            implicitWidth: criteriaCountText.implicitWidth + 16

                            Text {
                                id: criteriaCountText
                                anchors.centerIn: parent
                                text: root.countPassedCriteria() + " / 9 Kriter Sağlandı"
                                color: root.countPassedCriteria() >= 7 ? "#10B981" : (root.countPassedCriteria() >= 4 ? "#F59E0B" : "#EF4444")
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        rowSpacing: 10
                        columnSpacing: 12

                        property bool hasInput: passwordInput.text.length > 0

                        // 1. Min 8 Karakter (FR-ANL-001)
                        CriterionItem {
                            title: "En Az 8 Karakter"
                            points: !parent.hasInput ? "+15 Puan" : (root.liveAnalysis && root.liveAnalysis.lengthAtLeast8 ? "+15 Puan (Sağlandı)" : (passwordInput.text.length + " / 8 Karakter"))
                            status: !parent.hasInput ? "neutral" : (root.liveAnalysis && root.liveAnalysis.lengthAtLeast8 ? "passed" : "unmet")
                        }
                        // 2. Ek Uzunluk 12+ (FR-ANL-002)
                        CriterionItem {
                            title: "En Az 12 Karakter"
                            points: !parent.hasInput ? "+15 Puan" : (root.liveAnalysis && root.liveAnalysis.lengthAtLeast12 ? "+15 Puan (Sağlandı)" : (passwordInput.text.length + " / 12 Karakter"))
                            status: !parent.hasInput ? "neutral" : (root.liveAnalysis && root.liveAnalysis.lengthAtLeast12 ? "passed" : "unmet")
                        }
                        // 3. Büyük Harf (FR-ANL-003)
                        CriterionItem {
                            title: "Büyük Harf (A-Z)"
                            points: "+15 Puan"
                            status: !parent.hasInput ? "neutral" : (root.liveAnalysis && root.liveAnalysis.hasUpper ? "passed" : "unmet")
                        }
                        // 4. Küçük Harf (a-z)
                        CriterionItem {
                            title: "Küçük Harf (a-z)"
                            points: "+15 Puan"
                            status: !parent.hasInput ? "neutral" : (root.liveAnalysis && root.liveAnalysis.hasLower ? "passed" : "unmet")
                        }
                        // 5. Rakam (0-9)
                        CriterionItem {
                            title: "Rakam (0-9)"
                            points: "+15 Puan"
                            status: !parent.hasInput ? "neutral" : (root.liveAnalysis && root.liveAnalysis.hasDigit ? "passed" : "unmet")
                        }
                        // 6. Özel Karakter (FR-ANL-006 & FR-ANL-010)
                        CriterionItem {
                            title: "Özel Karakter (!@#$...)"
                            points: "+25 Puan"
                            status: !parent.hasInput ? "neutral" : (root.liveAnalysis && root.liveAnalysis.hasSpecial ? "passed" : "unmet")
                        }
                        // 7. Yaygın Şifre Değil (FR-ANL-007 & FR-ANL-011)
                        CriterionItem {
                            title: "Yaygın Şifre Değil"
                            points: !parent.hasInput ? "Uygunluk" : (root.liveAnalysis && root.liveAnalysis.isCommon ? "Puan Sıfırlanır!" : "Uygun")
                            status: !parent.hasInput ? "neutral" : (root.liveAnalysis && !root.liveAnalysis.isCommon ? "passed" : "unmet")
                        }
                        // 8. Tekrarlayan Karakter Yok (FR-ANL-008 & FR-SCORE-013)
                        CriterionItem {
                            title: "Tekrarsız Karakter (aaa...)"
                            points: !parent.hasInput ? "0 Ceza" : (root.liveAnalysis && root.liveAnalysis.repeatedPatterns > 0 ? ("-" + (root.liveAnalysis.repeatedPatterns * 15) + " Ceza") : "0 Ceza")
                            status: !parent.hasInput ? "neutral" : (root.liveAnalysis && root.liveAnalysis.hasNoRepeated ? "passed" : "unmet")
                        }
                        // 9. Sıralı Karakter Yok (FR-ANL-009 & FR-SCORE-013)
                        CriterionItem {
                            title: "Sırasız Karakter (1234...)"
                            points: !parent.hasInput ? "0 Ceza" : (root.liveAnalysis && root.liveAnalysis.sequentialPatterns > 0 ? ("-" + (root.liveAnalysis.sequentialPatterns * 15) + " Ceza") : "0 Ceza")
                            status: !parent.hasInput ? "neutral" : (root.liveAnalysis && root.liveAnalysis.hasNoSequential ? "passed" : "unmet")
                        }
                    }

                    // Hata / Uyarı Banner'ı (FR-INPUT-002)
                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        visible: root.errorMessage.length > 0
                        color: root.isDarkTheme ? "#450A0A" : "#FEE2E2"
                        border.color: "#DC2626"
                        border.width: 1
                        radius: 6

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8
                            Text {
                                text: "⚠️"
                                font.pixelSize: 14
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.errorMessage
                                color: root.isDarkTheme ? "#FCA5A5" : "#B91C1C"
                                font.pixelSize: 13
                                font.bold: true
                            }
                        }
                    }

                    // Aksiyon Butonları
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Button {
                            id: analyzeBtn
                            Layout.fillWidth: true
                            implicitHeight: 44
                            background: Rectangle {
                                color: analyzeBtn.down ? "#4338CA" : (analyzeBtn.hovered ? "#4F46E5" : "#6366F1")
                                radius: 8
                            }
                            contentItem: RowLayout {
                                spacing: 8
                                anchors.centerIn: parent
                                Text {
                                    text: "⚡"
                                    font.pixelSize: 15
                                }
                                Text {
                                    text: "Şifreyi Analiz Et"
                                    color: "#FFFFFF"
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }
                            onClicked: {
                                runAnalysis();
                            }
                        }

                        // FR-UI-006: Temizleme İşlemi
                        Button {
                            id: clearBtn
                            implicitWidth: 140
                            implicitHeight: 44
                            background: Rectangle {
                                color: clearBtn.down ? root.theme.buttonDown : (clearBtn.hovered ? root.theme.buttonHover : root.theme.buttonBg)
                                border.color: root.theme.buttonBorder
                                border.width: 1
                                radius: 8

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                            }
                            contentItem: RowLayout {
                                spacing: 6
                                anchors.centerIn: parent
                                Text {
                                    text: "🗑️"
                                    font.pixelSize: 14
                                }
                                Text {
                                    text: "Temizle"
                                    color: root.theme.buttonText
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }
                            onClicked: {
                                clearAll();
                            }
                        }
                    }
                }
            }

            // ================= ANALİZ SONUCU VE GÜÇ GÖSTERGESİ =================
            Rectangle {
                Layout.fillWidth: true
                color: root.theme.cardBg
                radius: 12
                border.color: root.theme.cardBorder
                border.width: 1
                implicitHeight: resultCol.implicitHeight + 40
                visible: root.hasAnalyzed

                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                ColumnLayout {
                    id: resultCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    // Skor Başlık & Seviye Rozeti
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            spacing: 4
                            Text {
                                text: "Güvenlik Skoru ve Seviyesi"
                                color: root.theme.textPrimary
                                font.pixelSize: 16
                                font.bold: true
                            }
                            Text {
                                text: "Hesaplanan toplam güvenlik puanı ve değerlendirme seviyesi"
                                color: root.theme.textSecondary
                                font.pixelSize: 12
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // FR-UI-002: Güvenlik Seviyesinin Gösterilmesi
                        Rectangle {
                            height: 38
                            radius: 8
                            color: root.lastAnalysis ? root.getLevelBgColor(root.lastAnalysis.securityLevel) : root.theme.subCardBg
                            border.color: root.lastAnalysis ? root.getLevelColor(root.lastAnalysis.securityLevel) : root.theme.cardBorder
                            border.width: 1
                            implicitWidth: levelText.implicitWidth + 28

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    id: levelText
                                    text: root.lastAnalysis ? root.lastAnalysis.securityLevel : ""
                                    color: root.lastAnalysis ? root.getLevelColor(root.lastAnalysis.securityLevel) : root.theme.textPrimary
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                            }
                        }
                    }

                    // FR-UI-001 & FR-UI-004: Puan ve Güç Göstergesi
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 24

                        // Puan Dairesi / Rozeti
                        Rectangle {
                            width: 80
                            height: 80
                            radius: 40
                            color: root.theme.subCardBg
                            border.color: root.lastAnalysis ? root.getLevelColor(root.lastAnalysis.securityLevel) : root.theme.cardBorder
                            border.width: 3

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 0
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.lastAnalysis ? root.lastAnalysis.score : "0"
                                    color: root.lastAnalysis ? root.getLevelColor(root.lastAnalysis.securityLevel) : root.theme.textPrimary
                                    font.pixelSize: 26
                                    font.bold: true
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "/ 100"
                                    color: root.theme.textMuted
                                    font.pixelSize: 11
                                }
                            }
                        }

                        // FR-UI-004: Güç Göstergesi Çubuğu
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Güç Seviyesi İlerlemesi"
                                    color: root.theme.textPrimary
                                    font.pixelSize: 13
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: "%" + (root.lastAnalysis ? root.lastAnalysis.score : 0)
                                    color: root.lastAnalysis ? root.getLevelColor(root.lastAnalysis.securityLevel) : root.theme.textSecondary
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 14
                                radius: 7
                                color: root.theme.subCardBg
                                border.color: root.theme.subCardBorder
                                border.width: 1

                                Rectangle {
                                    id: strengthFill
                                    height: parent.height
                                    radius: 7
                                    width: parent.width * ((root.lastAnalysis ? root.lastAnalysis.score : 0) / 100.0)
                                    color: root.lastAnalysis ? root.getLevelColor(root.lastAnalysis.securityLevel) : "#3B82F6"

                                    Behavior on width {
                                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on color {
                                        ColorAnimation { duration: 300 }
                                    }
                                }
                            }

                            // Seviye Göstergeleri Eşiği
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "Weak (0-30)"; color: "#EF4444"; font.pixelSize: 10 }
                                Item { Layout.fillWidth: true }
                                Text { text: "Medium (31-60)"; color: "#F59E0B"; font.pixelSize: 10 }
                                Item { Layout.fillWidth: true }
                                Text { text: "Strong (61-80)"; color: "#3B82F6"; font.pixelSize: 10 }
                                Item { Layout.fillWidth: true }
                                Text { text: "Very Strong (81-100)"; color: "#10B981"; font.pixelSize: 10 }
                            }
                        }
                    }

                    // Ayırıcı Çizgi
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: root.theme.cardBorder
                    }

                    // Detaylı Bilgilendirme ve Başarı Özeti
                    Rectangle {
                        Layout.fillWidth: true
                        height: 44
                        radius: 8
                        color: root.lastAnalysis && root.lastAnalysis.score >= 80 ? root.theme.critPassedBg : root.theme.subCardBg
                        border.color: root.lastAnalysis && root.lastAnalysis.score >= 80 ? root.theme.critPassedBorder : root.theme.cardBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10

                            Text {
                                text: root.lastAnalysis && root.lastAnalysis.score >= 80 ? "🛡️" : "📋"
                                font.pixelSize: 15
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.lastAnalysis && root.lastAnalysis.score >= 80
                                      ? "Tebrikler! Şifreniz yüksek güvenlik standartlarını karşılıyor ve güvenle kullanılabilir."
                                      : "Kriter durumlarını yukarıdaki canlı panelden anlık izleyebilir, önerilere göre şifrenizi geliştirebilirsiniz."
                                color: root.lastAnalysis && root.lastAnalysis.score >= 80 ? (root.isDarkTheme ? "#A7F3D0" : "#065F46") : root.theme.textSecondary
                                font.pixelSize: 12
                            }
                        }
                    }

                    // FR-UI-005: İyileştirme Önerisi
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        visible: root.lastAnalysis && root.lastAnalysis.suggestions && root.lastAnalysis.suggestions.length > 0

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: root.theme.cardBorder
                        }

                        Text {
                            text: "💡 İyileştirme Önerileri"
                            color: root.isDarkTheme ? "#FBBF24" : "#D97706"
                            font.pixelSize: 14
                            font.bold: true
                        }

                        Repeater {
                            model: root.lastAnalysis ? root.lastAnalysis.suggestions : []
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: 34
                                color: root.theme.subCardBg
                                radius: 6
                                border.color: root.theme.subCardBorder
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 8
                                    Text {
                                        text: "•"
                                        color: root.isDarkTheme ? "#FBBF24" : "#D97706"
                                        font.bold: true
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData
                                        color: root.theme.textPrimary
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ================= ANALİZ GEÇMİŞİ (FR-DB-001..004) =================
            Rectangle {
                Layout.fillWidth: true
                color: root.theme.cardBg
                radius: 12
                border.color: root.theme.cardBorder
                border.width: 1
                implicitHeight: historyCol.implicitHeight + 40

                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                ColumnLayout {
                    id: historyCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            spacing: 4
                            Text {
                                text: "Anonim Analiz Geçmişi"
                                color: root.theme.textPrimary
                                font.pixelSize: 16
                                font.bold: true
                            }
                            Text {
                                text: "Yerel SQLite veritabanına kaydedilen anonim analiz sonuçları"
                                color: root.theme.textSecondary
                                font.pixelSize: 12
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // FR-DB-004: Analiz Geçmişinin Temizlenmesi
                        Button {
                            id: clearHistoryBtn
                            enabled: root.historyList.length > 0
                            implicitHeight: 36
                            background: Rectangle {
                                color: clearHistoryBtn.enabled
                                       ? (clearHistoryBtn.down ? "#7F1D1D" : (clearHistoryBtn.hovered ? "#991B1B" : (root.isDarkTheme ? "#450A0A" : "#FEE2E2")))
                                       : root.theme.buttonBg
                                border.color: clearHistoryBtn.enabled ? "#DC2626" : root.theme.cardBorder
                                border.width: 1
                                radius: 6

                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            contentItem: RowLayout {
                                spacing: 6
                                anchors.centerIn: parent
                                Text {
                                    text: "🗑️"
                                    font.pixelSize: 12
                                }
                                Text {
                                    text: "Geçmişi Temizle"
                                    color: clearHistoryBtn.enabled ? (root.isDarkTheme ? "#FCA5A5" : "#DC2626") : root.theme.textMuted
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }
                            onClicked: {
                                confirmDialog.open();
                            }
                        }
                    }

                    // Boş Geçmiş Uyarısı
                    Rectangle {
                        Layout.fillWidth: true
                        height: 60
                        visible: root.historyList.length === 0
                        color: root.theme.subCardBg
                        radius: 8
                        border.color: root.theme.subCardBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Henüz kaydedilmiş bir analiz geçmişi bulunmuyor."
                            color: root.theme.textSecondary
                            font.pixelSize: 13
                        }
                    }

                    // Geçmiş Kayıtları Listesi (FR-DB-003)
                    Repeater {
                        model: root.historyList
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            color: root.theme.historyRowBg
                            radius: 8
                            border.color: root.theme.historyRowBorder
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 16

                                Text {
                                    text: modelData.analysisDate || ""
                                    color: root.theme.textSecondary
                                    font.pixelSize: 13
                                    font.family: "Monospace"
                                }

                                Text {
                                    text: "Uzunluk: " + (modelData.passwordLength || 0) + " krk"
                                    color: root.theme.textPrimary
                                    font.pixelSize: 13
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.criteriaResults || ""
                                    color: root.theme.textMuted
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    width: 76
                                    height: 26
                                    radius: 6
                                    color: root.getLevelBgColor(modelData.securityLevel)
                                    border.color: root.getLevelColor(modelData.securityLevel)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.securityLevel || ""
                                        color: root.getLevelColor(modelData.securityLevel)
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                Text {
                                    text: (modelData.score || 0) + " Puan"
                                    color: root.getLevelColor(modelData.securityLevel)
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // FR-DB-004: Onay Diyaloğu
    Dialog {
        id: confirmDialog
        title: "Analiz Geçmişini Temizle"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        standardButtons: Dialog.Yes | Dialog.No

        background: Rectangle {
            color: root.theme.dialogBg
            border.color: root.theme.dialogBorder
            border.width: 1
            radius: 8

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        contentItem: Text {
            text: "Kayıtlı tüm anonim analiz geçmişi silinecektir. Emin misiniz?"
            color: root.theme.textPrimary
            font.pixelSize: 14
        }

        onAccepted: {
            database.clearHistory();
        }
    }

    // Kriter Bileşeni Şablonu (Canlı Durum ve Renk Desteği)
    component CriterionItem: Rectangle {
        id: critItem
        property string title: ""
        property string points: ""
        property string status: "neutral" // "neutral", "passed", "unmet"
        property bool passed: status === "passed"

        Layout.fillWidth: true
        height: 52
        radius: 8
        color: critItem.status === "passed"
               ? root.theme.critPassedBg
               : (critItem.status === "unmet" ? root.theme.critUnmetBg : root.theme.critNeutralBg)
        border.color: critItem.status === "passed"
                      ? root.theme.critPassedBorder
                      : (critItem.status === "unmet" ? root.theme.critUnmetBorder : root.theme.critNeutralBorder)
        border.width: critItem.status === "passed" ? 1.5 : 1

        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Rectangle {
                width: 26
                height: 26
                radius: 13
                color: critItem.status === "passed"
                       ? root.theme.critPassedIconBg
                       : (critItem.status === "unmet" ? root.theme.critUnmetIconBg : root.theme.critNeutralIconBg)
                border.color: critItem.status === "passed"
                              ? root.theme.critPassedIconBorder
                              : (critItem.status === "unmet" ? root.theme.critUnmetIconBorder : root.theme.critNeutralIconBorder)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    text: critItem.status === "passed" ? "✓" : (critItem.status === "unmet" ? "✕" : "○")
                    color: critItem.status === "passed"
                           ? root.theme.critPassedIconText
                           : (critItem.status === "unmet" ? root.theme.critUnmetIconText : root.theme.critNeutralIconText)
                    font.pixelSize: critItem.status === "neutral" ? 10 : 13
                    font.bold: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: critItem.title
                    color: critItem.status === "passed"
                           ? root.theme.critPassedText
                           : (critItem.status === "unmet" ? root.theme.critUnmetText : root.theme.critNeutralText)
                    font.pixelSize: 12
                    font.bold: critItem.status === "passed"
                    elide: Text.ElideRight
                }
                Text {
                    text: critItem.points
                    color: critItem.status === "passed"
                           ? root.theme.critPassedPoints
                           : (critItem.status === "unmet" ? root.theme.critUnmetPoints : root.theme.critNeutralPoints)
                    font.pixelSize: 10
                    font.bold: critItem.status === "passed"
                }
            }
        }
    }
}

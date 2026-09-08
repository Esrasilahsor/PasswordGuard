import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: rootWindow
    visible: true
    width: 1100
    height: 750
    minimumWidth: 540
    minimumHeight: 600
    title: qsTr("PasswordGuard - Şifre Güvenlik Analizi")
    color: "#EFF6FC"

    // Analiz sonuç durumu ve model verileri
    property var lastResult: null
    property bool hasResult: false
    property var historyModel: []

    // UN-003, FR-DB-003: SQLite Analiz Geçmişinin Yüklenmesi
    function loadHistory() {
        if (typeof databaseManager !== "undefined") {
            rootWindow.historyModel = databaseManager.getHistory();
        }
    }

    Component.onCompleted: {
        loadHistory();
    }

    // FR-DB-004: Veritabanı geçmişi değiştiğinde listeyi anında güncelleme
    Connections {
        target: databaseManager
        function onHistoryChanged() {
            rootWindow.loadHistory();
        }
    }

    // =========================================================================
    // ARKA PLAN (WAVE / DALGALI GÜVENLİK TEMASI)
    // =========================================================================
    Item {
        id: backgroundCanvasContainer
        anchors.fill: parent
        z: 0

        // Üst koyu lacivert gradient alan
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 250
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#0A223E" }
                GradientStop { position: 0.7; color: "#0F3256" }
                GradientStop { position: 1.0; color: "#144573" }
            }
        }

        // Dalgalı organik geçiş katmanları (Canvas ile saf Qt 5.15 çizimi)
        Canvas {
            id: waveCanvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var w = width;
                var h = height;

                // 1. Dalga Katmanı (Derin Mavi geçiş)
                ctx.fillStyle = "rgba(19, 66, 110, 0.55)";
                ctx.beginPath();
                ctx.moveTo(0, 180);
                ctx.bezierCurveTo(w * 0.25, 140, w * 0.65, 230, w, 190);
                ctx.lineTo(w, 290);
                ctx.bezierCurveTo(w * 0.70, 310, w * 0.30, 240, 0, 280);
                ctx.closePath();
                ctx.fill();

                // 2. Dalga Katmanı (Orta Yumuşak Mavi)
                ctx.fillStyle = "rgba(100, 150, 195, 0.25)";
                ctx.beginPath();
                ctx.moveTo(0, 210);
                ctx.bezierCurveTo(w * 0.35, 260, w * 0.65, 180, w, 240);
                ctx.lineTo(w, 360);
                ctx.bezierCurveTo(w * 0.60, 340, w * 0.30, 390, 0, 320);
                ctx.closePath();
                ctx.fill();

                // 3. Dalga Katmanı (Açık Yumuşak Zemin Dalgası)
                ctx.fillStyle = "rgba(220, 234, 247, 0.75)";
                ctx.beginPath();
                ctx.moveTo(0, 250);
                ctx.bezierCurveTo(w * 0.30, 290, w * 0.70, 220, w, 270);
                ctx.lineTo(w, h);
                ctx.lineTo(0, h);
                ctx.closePath();
                ctx.fill();

                // 4. Sol alt arka planda dekoratif kalkan silüeti
                ctx.strokeStyle = "rgba(255, 255, 255, 0.35)";
                ctx.lineWidth = 4;
                ctx.beginPath();
                var sx = Math.min(180, w * 0.14);
                var sy = 560;
                var sw = 150;
                var sh = 190;
                ctx.moveTo(sx, sy);
                ctx.lineTo(sx + sw, sy);
                ctx.bezierCurveTo(sx + sw, sy + sh * 0.6, sx + sw * 0.5, sy + sh * 0.9, sx + sw * 0.5, sy + sh);
                ctx.bezierCurveTo(sx + sw * 0.5, sy + sh * 0.9, sx, sy + sh * 0.6, sx, sy);
                ctx.stroke();

                // Kalkan içi kilit silüeti
                ctx.beginPath();
                ctx.arc(sx + sw * 0.5, sy + sh * 0.45, 24, Math.PI, 0, false);
                ctx.stroke();
                ctx.strokeRect(sx + sw * 0.5 - 20, sy + sh * 0.45, 40, 32);
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }
    }

    // =========================================================================
    // KAYDIRILABİLİR ANA İÇERİK
    // =========================================================================
    ScrollView {
        id: mainScrollView
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        z: 1

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            active: true
        }

        ColumnLayout {
            // Referans görseldeki oran: Geniş ekranlarda ~%84, maksimum 1140px
            width: Math.min(Math.max(parent.width * 0.86, 500), 1140)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Item { height: 8 }

            // =================================================================
            // HEADER BÖLÜMÜ (REFERANS GÖRSELLE BİREBİR)
            // =================================================================
            RowLayout {
                id: headerRow
                Layout.fillWidth: true
                spacing: 16

                // SOL: Slogan Grubu (Geniş ekranda görünür)
                ColumnLayout {
                    id: headerLeftSlogan
                    visible: rootWindow.width >= 900
                    Layout.preferredWidth: 200
                    spacing: 2
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: qsTr("Verilerinizi")
                        font.pixelSize: 15
                        color: "#91AFCD"
                    }
                    Text {
                        text: qsTr("Güçlü Şifrelerle")
                        font.pixelSize: 19
                        font.bold: true
                        color: "#FFFFFF"
                    }
                    Text {
                        text: qsTr("Koruyun")
                        font.pixelSize: 15
                        color: "#91AFCD"
                    }
                }

                // ORTA: Dairesel Logo ve Ana Başlık Grubu
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    spacing: 18

                    // Dairesel Beyaz Çerçeve İçinde Logo
                    Rectangle {
                        width: rootWindow.width < 640 ? 72 : 88
                        height: width
                        radius: width / 2
                        color: "#FFFFFF"
                        border.color: "#8FAEC9"
                        border.width: 3
                        Layout.alignment: Qt.AlignVCenter

                        Image {
                            anchors.centerIn: parent
                            width: parent.width * 0.78
                            height: parent.height * 0.78
                            source: "qrc:/resources/logo.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                    }

                    // Başlık ve Alt Başlıklar
                    ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: qsTr("PasswordGuard")
                            font.pixelSize: rootWindow.width < 640 ? 24 : 32
                            font.bold: true
                            color: "#FFFFFF"
                        }

                        Text {
                            text: qsTr("Şifre Güvenlik Analizi")
                            font.pixelSize: rootWindow.width < 640 ? 14 : 16
                            font.weight: Font.Medium
                            color: "#D2E4F4"
                        }

                        Text {
                            text: qsTr("Daha Güçlü Şifreler, Daha Güvenli Yarınlar")
                            font.pixelSize: rootWindow.width < 640 ? 11 : 12
                            color: "#91AFCD"
                        }
                    }
                }

                // SAĞ: Güvenlik Rozeti (Geniş ekranda görünür)
                RowLayout {
                    id: headerRightBadge
                    visible: rootWindow.width >= 960
                    spacing: 12
                    Layout.alignment: Qt.AlignVCenter

                    // İnce ayraç
                    Rectangle {
                        width: 1
                        height: 48
                        color: Qt.rgba(1, 1, 1, 0.2)
                    }

                    // Kalkan/Kilit İkonu
                    Rectangle {
                        width: 44
                        height: 44
                        radius: 10
                        color: "#164B7C"
                        border.color: "#3577B0"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "🔒"
                            font.pixelSize: 20
                        }
                    }

                    ColumnLayout {
                        spacing: 2

                        Text {
                            text: qsTr("Güçlü Şifre")
                            font.pixelSize: 12
                            font.bold: true
                            color: "#FFFFFF"
                        }
                        Text {
                            text: qsTr("Güvenli Gelecek")
                            font.pixelSize: 12
                            color: "#A2C3DF"
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1.5
                            color: "#3B75A8"
                        }
                    }
                }
            }

            Item { height: 4 }

            // =================================================================
            // KART 1: ŞİFRE ANALİZİ KARTI (GENİŞ BEYAZ KART)
            // =================================================================
            Rectangle {
                id: inputCard
                Layout.fillWidth: true
                implicitHeight: inputCardColumn.implicitHeight + 36
                Layout.preferredHeight: implicitHeight
                color: "#FFFFFF"
                radius: 12
                border.color: "#D6E4F0"
                border.width: 1

                ColumnLayout {
                    id: inputCardColumn
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    // Başlık
                    RowLayout {
                        spacing: 8
                        Text {
                            text: "🔑"
                            font.pixelSize: 16
                        }
                        Text {
                            text: qsTr("Şifre Analizi")
                            font.pixelSize: 16
                            font.bold: true
                            color: "#0B2D50"
                        }
                    }

                    // FR-INPUT-001, FR-INPUT-003, FR-INPUT-004, FR-INPUT-005: Giriş Alanı ve Göster/Gizle
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        TextField {
                            id: passwordField
                            Layout.fillWidth: true
                            placeholderText: qsTr("Analiz edilecek şifreyi giriniz...")
                            echoMode: showPasswordButton.checked ? TextInput.Normal : TextInput.Password
                            maximumLength: 128
                            font.pixelSize: 14
                            color: "#0B2D50"
                            selectByMouse: true
                            padding: 10
                            background: Rectangle {
                                radius: 8
                                color: "#FFFFFF"
                                border.color: passwordField.activeFocus ? "#1769AA" : "#D6E4F0"
                                border.width: passwordField.activeFocus ? 2 : 1
                            }
                            onTextChanged: {
                                if (warningLabel.visible && text.length > 0) {
                                    warningLabel.visible = false;
                                }
                            }
                            onAccepted: analyzeButton.clicked()
                        }

                        // Göster / Gizle Butonu (Referans görseldeki buton biçimi)
                        Button {
                            id: showPasswordButton
                            checkable: true
                            checked: false
                            implicitHeight: 40
                            implicitWidth: 95
                            background: Rectangle {
                                radius: 8
                                color: showPasswordButton.down ? "#E4EEF8" : "#F1F6FB"
                                border.color: "#D6E4F0"
                                border.width: 1
                            }
                            contentItem: RowLayout {
                                spacing: 6
                                anchors.centerIn: parent
                                Text {
                                    text: showPasswordButton.checked ? "👁‍🗨" : "👁"
                                    font.pixelSize: 14
                                }
                                Text {
                                    text: showPasswordButton.checked ? qsTr("Gizle") : qsTr("Göster")
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    color: "#174D7C"
                                }
                            }
                        }
                    }

                    // FR-INPUT-002: Boş Şifre Uyarısı
                    Text {
                        id: warningLabel
                        visible: false
                        text: qsTr("Lütfen analiz edilecek bir şifre giriniz!")
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: "#DC2626"
                    }

                    // Butonlar Satırı: [ Analiz Et ]  [ Temizle ]
                    RowLayout {
                        spacing: 12

                        // Analiz Et (Primary Buton - Koyu Lacivert)
                        Button {
                            id: analyzeButton
                            text: qsTr("Analiz Et")
                            implicitHeight: 42
                            implicitWidth: 140
                            background: Rectangle {
                                radius: 8
                                color: analyzeButton.down ? "#0A223E" : (analyzeButton.hovered ? "#133D6B" : "#0E2F54")
                            }
                            contentItem: RowLayout {
                                spacing: 8
                                anchors.centerIn: parent
                                Text {
                                    text: "🔍"
                                    font.pixelSize: 14
                                }
                                Text {
                                    text: analyzeButton.text
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#FFFFFF"
                                }
                            }
                            onClicked: {
                                if (passwordField.text.length === 0) {
                                    warningLabel.visible = true;
                                    rootWindow.hasResult = false;
                                    return;
                                }

                                warningLabel.visible = false;
                                var result = passwordAnalyzer.analyzePassword(passwordField.text);
                                rootWindow.lastResult = result;
                                rootWindow.hasResult = true;

                                // FR-DB-001, FR-DB-002: Veritabanına kaydet
                                databaseManager.saveAnalysis(
                                    result.length,
                                    result.criteriaSummary,
                                    result.score,
                                    result.level
                                );
                            }
                        }

                        // Temizle (Secondary Buton - Açık Mavi/Gri)
                        Button {
                            id: clearButton
                            text: qsTr("Temizle")
                            implicitHeight: 42
                            implicitWidth: 120
                            background: Rectangle {
                                radius: 8
                                color: clearButton.down ? "#D4E5F5" : (clearButton.hovered ? "#DFEDF8" : "#EAF2F9")
                                border.color: "#CFE0F0"
                                border.width: 1
                            }
                            contentItem: RowLayout {
                                spacing: 8
                                anchors.centerIn: parent
                                Text {
                                    text: "🗑"
                                    font.pixelSize: 14
                                }
                                Text {
                                    text: clearButton.text
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#174D7C"
                                }
                            }
                            onClicked: {
                                passwordField.text = "";
                                rootWindow.hasResult = false;
                                rootWindow.lastResult = null;
                                warningLabel.visible = false;
                            }
                        }
                    }
                }
            }

            // =================================================================
            // ORTA BÖLÜM: MASAÜSTÜNDE İKİ KOLON, DAR EKRANDA TEK KOLON
            // =================================================================
            GridLayout {
                id: middleGrid
                objectName: "middleGrid"
                Layout.fillWidth: true
                columns: rootWindow.width >= 820 ? 2 : 1
                columnSpacing: 16
                rowSpacing: 16

                // KART 2A: ANALİZ SONUÇLARI
                Rectangle {
                    id: resultsCard
                    Layout.fillWidth: true
                    Layout.row: 0
                    Layout.column: 0
                    implicitHeight: resultsCardCol.implicitHeight + 36
                    Layout.preferredHeight: implicitHeight
                    color: "#FFFFFF"
                    radius: 12
                        border.color: "#D6E4F0"
                        border.width: 1

                        ColumnLayout {
                            id: resultsCardCol
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 16

                            // Başlık
                            RowLayout {
                                spacing: 8
                                Text {
                                    text: "📊"
                                    font.pixelSize: 16
                                }
                                Text {
                                    text: qsTr("Analiz Sonuçları")
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: "#0B2D50"
                                }
                            }

                            // İki Bilgi Kutusu: Güvenlik Puanı ve Güvenlik Seviyesi
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 14

                                // Güvenlik Puanı Kutusu
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 74
                                    radius: 8
                                    color: "#F0F6FC"
                                    border.color: "#E1EDF7"
                                    border.width: 1

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            text: qsTr("Güvenlik Puanı")
                                            font.pixelSize: 13
                                            color: "#58728C"
                                            Layout.alignment: Qt.AlignHCenter
                                        }

                                        Text {
                                            text: (rootWindow.hasResult && rootWindow.lastResult ? rootWindow.lastResult.score : 0) + " / 100"
                                            font.pixelSize: 22
                                            font.bold: true
                                            color: "#0B2D50"
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }
                                }

                                // Güvenlik Seviyesi Kutusu
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 74
                                    radius: 8
                                    color: "#F0F6FC"
                                    border.color: "#E1EDF7"
                                    border.width: 1

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text {
                                            text: qsTr("Güvenlik Seviyesi")
                                            font.pixelSize: 13
                                            color: "#58728C"
                                            Layout.alignment: Qt.AlignHCenter
                                        }

                                        // Seviye Rozeti
                                        Rectangle {
                                            Layout.alignment: Qt.AlignHCenter
                                            radius: 12
                                            implicitWidth: Math.max(70, levelTextItem.implicitWidth + 24)
                                            implicitHeight: 26
                                            color: {
                                                if (!rootWindow.hasResult || !rootWindow.lastResult) return "#DDE8F4";
                                                switch (rootWindow.lastResult.level) {
                                                    case "Weak": return "#FEE2E2";
                                                    case "Medium": return "#FEF3C7";
                                                    case "Strong": return "#DCFCE7";
                                                    case "Very Strong": return "#DBEAFE";
                                                    default: return "#DDE8F4";
                                                }
                                            }

                                            Text {
                                                id: levelTextItem
                                                anchors.centerIn: parent
                                                text: (rootWindow.hasResult && rootWindow.lastResult ? rootWindow.lastResult.level : "-")
                                                font.pixelSize: 13
                                                font.bold: true
                                                color: {
                                                    if (!rootWindow.hasResult || !rootWindow.lastResult) return "#58728C";
                                                    switch (rootWindow.lastResult.level) {
                                                        case "Weak": return "#DC2626";
                                                        case "Medium": return "#D97706";
                                                        case "Strong": return "#16A34A";
                                                        case "Very Strong": return "#2563EB";
                                                        default: return "#58728C";
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Güç Göstergesi Bölümü
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: qsTr("Güç Göstergesi")
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: "#0B2D50"
                                }

                                // Geniş Progress Bar
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 12
                                    radius: 6
                                    color: "#DCE8F4"

                                    Rectangle {
                                        width: parent.width * (rootWindow.hasResult && rootWindow.lastResult ? (rootWindow.lastResult.score / 100.0) : 0)
                                        height: parent.height
                                        radius: 6
                                        color: {
                                            if (!rootWindow.hasResult || !rootWindow.lastResult) return "#58728C";
                                            switch (rootWindow.lastResult.level) {
                                                case "Weak": return "#DC2626";
                                                case "Medium": return "#D97706";
                                                case "Strong": return "#16A34A";
                                                case "Very Strong": return "#2563EB";
                                                default: return "#58728C";
                                            }
                                        }
                                        Behavior on width {
                                            NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // KART 2B: İYİLEŞTİRME ÖNERİLERİ
                    Rectangle {
                        id: suggestionsCard
                        Layout.fillWidth: true
                        Layout.row: rootWindow.width >= 820 ? 1 : 2
                        Layout.column: 0
                        implicitHeight: suggestionsCol.implicitHeight + 36
                        Layout.preferredHeight: implicitHeight
                        color: "#FFFFFF"
                        radius: 12
                        border.color: "#D6E4F0"
                        border.width: 1

                        ColumnLayout {
                            id: suggestionsCol
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 12

                            // Başlık
                            RowLayout {
                                spacing: 8
                                Text {
                                    text: "💡"
                                    font.pixelSize: 16
                                }
                                Text {
                                    text: qsTr("İyileştirme Önerileri")
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: "#0B2D50"
                                }
                            }

                            // DURUM 1: Analiz Henüz Yapılmamışsa (Referans Görseldeki Bilgi Kutusu)
                            Rectangle {
                                visible: !rootWindow.hasResult || !rootWindow.lastResult
                                Layout.fillWidth: true
                                implicitHeight: infoBannerCol.implicitHeight + 24
                                Layout.preferredHeight: implicitHeight
                                radius: 8
                                color: "#E8F2FA"
                                border.color: "#CFE2F2"
                                border.width: 1

                                RowLayout {
                                    id: infoBannerCol
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 13
                                        color: "#1976D2"
                                        Layout.alignment: Qt.AlignTop

                                        Text {
                                            anchors.centerIn: parent
                                            text: "i"
                                            font.bold: true
                                            font.pixelSize: 15
                                            color: "#FFFFFF"
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 3

                                        Text {
                                            text: qsTr("Öneriler, analiz sonrasında burada görünecektir.")
                                            font.pixelSize: 13
                                            font.bold: true
                                            color: "#1565C0"
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: qsTr("Daha güçlü bir şifre oluşturmak için önerileri takip edebilirsiniz.")
                                            font.pixelSize: 12
                                            color: "#547B9E"
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }
                                    }
                                }
                            }

                            // DURUM 2: Analiz Sonrası Öneriler Varsa
                            Column {
                                visible: rootWindow.hasResult && rootWindow.lastResult && rootWindow.lastResult.suggestions && rootWindow.lastResult.suggestions.length > 0
                                Layout.fillWidth: true
                                spacing: 8

                                Repeater {
                                    model: (rootWindow.hasResult && rootWindow.lastResult && rootWindow.lastResult.suggestions) ? rootWindow.lastResult.suggestions : []

                                    Row {
                                        width: parent.width
                                        spacing: 8

                                        Text {
                                            text: "•"
                                            color: "#D97706"
                                            font.bold: true
                                            font.pixelSize: 15
                                        }

                                        Text {
                                            width: parent.width - 24
                                            text: modelData
                                            font.pixelSize: 13
                                            color: "#0B2D50"
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                }
                            }

                            // DURUM 3: Analiz Sonrası Tüm Kriterler Karşılanmışsa
                            Rectangle {
                                visible: rootWindow.hasResult && rootWindow.lastResult && rootWindow.lastResult.suggestions && rootWindow.lastResult.suggestions.length === 0
                                Layout.fillWidth: true
                                implicitHeight: 48
                                Layout.preferredHeight: implicitHeight
                                radius: 8
                                color: "#DCFCE7"
                                border.color: "#86EFAC"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    Text { text: "✔"; font.bold: true; color: "#16A34A"; font.pixelSize: 14 }
                                    Text {
                                        text: qsTr("Harika! Şifreniz tüm güvenlik kriterlerini başarıyla karşılıyor.")
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: "#166534"
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }

                // -------------------------------------------------------------
                // SAĞ KOLON: KART 2C: GÜVENLİK KRİTERLERİ
                // -------------------------------------------------------------
                Rectangle {
                    id: criteriaCard
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    Layout.row: rootWindow.width >= 820 ? 0 : 1
                    Layout.column: rootWindow.width >= 820 ? 1 : 0
                    Layout.rowSpan: rootWindow.width >= 820 ? 2 : 1
                    implicitHeight: criteriaCardCol.implicitHeight + 36
                    Layout.preferredHeight: implicitHeight
                    color: "#FFFFFF"
                    radius: 12
                    border.color: "#D6E4F0"
                    border.width: 1

                    ColumnLayout {
                        id: criteriaCardCol
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 14

                        // Başlık
                        RowLayout {
                            spacing: 8
                            Text {
                                text: "📋"
                                font.pixelSize: 16
                            }
                            Text {
                                text: qsTr("Güvenlik Kriterleri")
                                font.pixelSize: 16
                                font.bold: true
                                color: "#0B2D50"
                            }
                        }

                        // 9 Adet Kriter Satırı (FR-ANL-001..009)
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            // 1. Min 8 Karakter
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: !rootWindow.hasResult ? "#A9BACB" : (rootWindow.lastResult.criteria.minLength8 ? "#16A34A" : "#DC2626")
                                    Text {
                                        anchors.centerIn: parent
                                        text: !rootWindow.hasResult ? "✔" : (rootWindow.lastResult.criteria.minLength8 ? "✔" : "✖")
                                        color: "#FFFFFF"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                                Text { text: qsTr("En az 8 karakter uzunluğu"); font.pixelSize: 13; color: "#0B2D50"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                            }

                            // 2. Ek 12 Karakter
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: !rootWindow.hasResult ? "#A9BACB" : (rootWindow.lastResult.criteria.extraLength12 ? "#16A34A" : "#DC2626")
                                    Text {
                                        anchors.centerIn: parent
                                        text: !rootWindow.hasResult ? "✔" : (rootWindow.lastResult.criteria.extraLength12 ? "✔" : "✖")
                                        color: "#FFFFFF"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                                Text { text: qsTr("En az 12 karakter uzunluğu"); font.pixelSize: 13; color: "#0B2D50"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                            }

                            // 3. Büyük Harf
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: !rootWindow.hasResult ? "#A9BACB" : (rootWindow.lastResult.criteria.hasUppercase ? "#16A34A" : "#DC2626")
                                    Text {
                                        anchors.centerIn: parent
                                        text: !rootWindow.hasResult ? "✔" : (rootWindow.lastResult.criteria.hasUppercase ? "✔" : "✖")
                                        color: "#FFFFFF"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                                Text { text: qsTr("En az bir büyük harf (A-Z)"); font.pixelSize: 13; color: "#0B2D50"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                            }

                            // 4. Küçük Harf
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: !rootWindow.hasResult ? "#A9BACB" : (rootWindow.lastResult.criteria.hasLowercase ? "#16A34A" : "#DC2626")
                                    Text {
                                        anchors.centerIn: parent
                                        text: !rootWindow.hasResult ? "✔" : (rootWindow.lastResult.criteria.hasLowercase ? "✔" : "✖")
                                        color: "#FFFFFF"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                                Text { text: qsTr("En az bir küçük harf (a-z)"); font.pixelSize: 13; color: "#0B2D50"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                            }

                            // 5. Rakam
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: !rootWindow.hasResult ? "#A9BACB" : (rootWindow.lastResult.criteria.hasDigit ? "#16A34A" : "#DC2626")
                                    Text {
                                        anchors.centerIn: parent
                                        text: !rootWindow.hasResult ? "✔" : (rootWindow.lastResult.criteria.hasDigit ? "✔" : "✖")
                                        color: "#FFFFFF"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                                Text { text: qsTr("En az bir rakam (0-9)"); font.pixelSize: 13; color: "#0B2D50"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                            }

                            // 6. Özel Karakter
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: !rootWindow.hasResult ? "#A9BACB" : (rootWindow.lastResult.criteria.hasSpecialChar ? "#16A34A" : "#DC2626")
                                    Text {
                                        anchors.centerIn: parent
                                        text: !rootWindow.hasResult ? "✔" : (rootWindow.lastResult.criteria.hasSpecialChar ? "✔" : "✖")
                                        color: "#FFFFFF"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                                Text { text: qsTr("En az bir özel karakter (!@#$%^&* vb.)"); font.pixelSize: 13; color: "#0B2D50"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                            }

                            // 7. Yaygın Şifre Değil
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: !rootWindow.hasResult ? "#A9BACB" : (!rootWindow.lastResult.criteria.isCommonPassword ? "#16A34A" : "#DC2626")
                                    Text {
                                        anchors.centerIn: parent
                                        text: !rootWindow.hasResult ? "✔" : (!rootWindow.lastResult.criteria.isCommonPassword ? "✔" : "✖")
                                        color: "#FFFFFF"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                                Text { text: qsTr("Yaygın kullanılan bir şifre değil"); font.pixelSize: 13; color: "#0B2D50"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                            }

                            // 8. Tekrarlayan Karakter Yok
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: !rootWindow.hasResult ? "#A9BACB" : (!rootWindow.lastResult.criteria.hasRepeated ? "#16A34A" : "#DC2626")
                                    Text {
                                        anchors.centerIn: parent
                                        text: !rootWindow.hasResult ? "✔" : (!rootWindow.lastResult.criteria.hasRepeated ? "✔" : "✖")
                                        color: "#FFFFFF"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                                Text { text: qsTr("Art arda 3 veya daha fazla tekrarlayan karakter yok"); font.pixelSize: 13; color: "#0B2D50"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                            }

                            // 9. Sıralı Dizi Yok
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: !rootWindow.hasResult ? "#A9BACB" : (!rootWindow.lastResult.criteria.hasSequential ? "#16A34A" : "#DC2626")
                                    Text {
                                        anchors.centerIn: parent
                                        text: !rootWindow.hasResult ? "✔" : (!rootWindow.lastResult.criteria.hasSequential ? "✔" : "✖")
                                        color: "#FFFFFF"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                                Text { text: qsTr("Sıralı alfabetik veya sayısal karakter dizisi yok (örn. 1234, abcd)"); font.pixelSize: 13; color: "#0B2D50"; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // KART 3: ANALİZ GEÇMİŞİ (TAM GENİŞLİKTE KART)
            // =================================================================
            Rectangle {
                id: historyCard
                Layout.fillWidth: true
                implicitHeight: historyCol.implicitHeight + 36
                Layout.preferredHeight: implicitHeight
                color: "#FFFFFF"
                radius: 12
                border.color: "#D6E4F0"
                border.width: 1

                ColumnLayout {
                    id: historyCol
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    // Başlık ve Geçmişi Temizle Butonu (FR-DB-004)
                    RowLayout {
                        id: historyHeaderRow
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 12

                        // Sol: Başlık Grubu
                        RowLayout {
                            id: historyTitleGroup
                            spacing: 8
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                            Text {
                                text: "↺"
                                font.pixelSize: 17
                                font.bold: true
                                color: "#0B2D50"
                                Layout.alignment: Qt.AlignVCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            Text {
                                text: qsTr("Analiz Geçmişi")
                                font.pixelSize: 16
                                font.bold: true
                                color: "#0B2D50"
                                Layout.alignment: Qt.AlignVCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        // Esnek Boşluk
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }

                        // Sağ: Geçmişi Temizle Butonu (FR-DB-004)
                        Button {
                            id: clearHistoryButton
                            text: qsTr("Geçmişi Temizle")
                            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                            implicitHeight: 34
                            implicitWidth: clearHistoryBtnContent.implicitWidth + 24
                            leftPadding: 12
                            rightPadding: 12
                            topPadding: 0
                            bottomPadding: 0

                            background: Rectangle {
                                radius: 6
                                color: clearHistoryButton.down ? "#D4E5F5" : (clearHistoryButton.hovered ? "#DFEDF8" : "#EAF2F9")
                                border.color: "#CFDFEE"
                                border.width: 1
                            }
                            contentItem: RowLayout {
                                id: clearHistoryBtnContent
                                spacing: 6

                                Text {
                                    text: "🗑"
                                    font.pixelSize: 13
                                    Layout.alignment: Qt.AlignVCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                Text {
                                    text: clearHistoryButton.text
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: "#174D7C"
                                    Layout.alignment: Qt.AlignVCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                            onClicked: {
                                confirmClearDialog.open();
                            }
                        }
                    }

                    // Tablo Başlık Çubuğu
                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        color: "#EEF5FB"
                        radius: 6

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text { text: qsTr("Tarih"); font.pixelSize: 12; font.bold: true; color: "#0B2D50"; Layout.preferredWidth: 140 }
                            Text { text: qsTr("Uzunluk"); font.pixelSize: 12; font.bold: true; color: "#0B2D50"; Layout.preferredWidth: 70 }
                            Text { text: qsTr("Puan"); font.pixelSize: 12; font.bold: true; color: "#0B2D50"; Layout.preferredWidth: 60 }
                            Text { text: qsTr("Seviye"); font.pixelSize: 12; font.bold: true; color: "#0B2D50"; Layout.preferredWidth: 90 }
                            Text { text: qsTr("Kriterler"); font.pixelSize: 12; font.bold: true; color: "#0B2D50"; Layout.fillWidth: true }
                        }
                    }

                    // DURUM 1: Henüz Geçmiş Yoksa (Boş Durum - Empty State)
                    ColumnLayout {
                        visible: rootWindow.historyModel.length === 0
                        Layout.fillWidth: true
                        Layout.topMargin: 16
                        Layout.bottomMargin: 16
                        spacing: 8
                        Layout.alignment: Qt.AlignHCenter

                        Text {
                            text: "📄"
                            font.pixelSize: 32
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: qsTr("Henüz analiz geçmişi bulunmuyor.")
                            font.pixelSize: 14
                            font.bold: true
                            color: "#0B2D50"
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: qsTr("İlk şifre analizi için yukarıdaki alandan bir şifre girin.")
                            font.pixelSize: 12
                            color: "#58728C"
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    // DURUM 2: Kayıtlı Analiz Geçmişi Listesi
                    Column {
                        visible: rootWindow.historyModel.length > 0
                        Layout.fillWidth: true
                        spacing: 0

                        Repeater {
                            model: rootWindow.historyModel

                            Rectangle {
                                width: parent.width
                                implicitHeight: 40
                                color: index % 2 === 0 ? "#FFFFFF" : "#F8FBFE"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 8

                                    Text {
                                        text: modelData.createdAt || ""
                                        font.pixelSize: 12
                                        color: "#58728C"
                                        Layout.preferredWidth: 140
                                    }
                                    Text {
                                        text: (modelData.passwordLength || 0) + qsTr(" kar.")
                                        font.pixelSize: 12
                                        color: "#0B2D50"
                                        Layout.preferredWidth: 70
                                    }
                                    Text {
                                        text: (modelData.score || 0).toString()
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: "#0B2D50"
                                        Layout.preferredWidth: 60
                                    }
                                    Text {
                                        text: modelData.securityLevel || ""
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: {
                                            switch (modelData.securityLevel) {
                                                case "Weak": return "#DC2626";
                                                case "Medium": return "#D97706";
                                                case "Strong": return "#16A34A";
                                                case "Very Strong": return "#2563EB";
                                                default: return "#58728C";
                                            }
                                        }
                                        Layout.preferredWidth: 90
                                    }
                                    Text {
                                        text: modelData.criteriaSummary || ""
                                        font.pixelSize: 12
                                        color: "#58728C"
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }

                                // İnce alt sınır çizgisi
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 1
                                    color: "#EDF2F7"
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // FOOTER (REFERANS GÖRSELLE BİREBİR)
            // =================================================================
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.bottomMargin: 14

                Text {
                    text: qsTr("© 2026 PasswordGuard")
                    font.pixelSize: 12
                    color: "#7B96B0"
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 6
                    Text {
                        text: "🛡"
                        font.pixelSize: 13
                    }
                    Text {
                        text: qsTr("Güvenli Parolalar, Güvenli Hayatlar")
                        font.pixelSize: 12
                        color: "#7B96B0"
                    }
                }
            }
        }
    }

    // =========================================================================
    // FR-DB-004: GEÇMİŞİ TEMİZLEME ONAY DİALOGU
    // =========================================================================
    Dialog {
        id: confirmClearDialog
        objectName: "confirmClearDialog"
        title: qsTr("Geçmişi Temizle")
        modal: true
        dim: true
        header: null
        footer: null
        padding: 22

        width: Math.min(parent.width - 40, 440)
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)

        Overlay.modal: Rectangle {
            color: Qt.rgba(7/255, 30/255, 61/255, 0.45)
        }

        background: Rectangle {
            radius: 12
            color: "#FFFFFF"
            border.color: "#D6E4F0"
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 16

            // Başlık Satırı: Uyarı Rozeti + Başlık
            RowLayout {
                spacing: 12
                Layout.fillWidth: true

                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: "#FEF2F2"
                    border.color: "#FECACA"
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: "⚠"
                        font.pixelSize: 16
                        color: "#DC2626"
                    }
                }

                Text {
                    text: qsTr("Geçmişi Temizle")
                    font.pixelSize: 17
                    font.bold: true
                    color: "#0B2D50"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // Açıklama Metinleri
            ColumnLayout {
                spacing: 6
                Layout.fillWidth: true

                Text {
                    text: qsTr("Tüm analiz geçmişini silmek istediğinize emin misiniz?")
                    font.pixelSize: 14
                    color: "#0B2D50"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    text: qsTr("Bu işlem geri alınamaz.")
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: "#DC2626"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            // Alt Butonlar: [ İptal ]  [ Geçmişi Sil ]
            RowLayout {
                spacing: 12
                Layout.fillWidth: true
                Layout.topMargin: 6

                Item {
                    Layout.fillWidth: true
                }

                // İptal (Secondary Buton)
                Button {
                    id: cancelClearButton
                    text: qsTr("İptal")
                    implicitHeight: 36
                    implicitWidth: 90
                    Layout.alignment: Qt.AlignVCenter

                    background: Rectangle {
                        radius: 6
                        color: cancelClearButton.down ? "#D4E5F5" : (cancelClearButton.hovered ? "#DFEDF8" : "#EAF2F9")
                        border.color: "#CFDFEE"
                        border.width: 1
                    }

                    contentItem: Text {
                        text: cancelClearButton.text
                        font.pixelSize: 13
                        font.bold: true
                        color: "#174D7C"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        confirmClearDialog.reject();
                    }
                }

                // Geçmişi Sil (Destructive Action Butonu)
                Button {
                    id: acceptClearButton
                    text: qsTr("Geçmişi Sil")
                    implicitHeight: 36
                    implicitWidth: 120
                    Layout.alignment: Qt.AlignVCenter

                    background: Rectangle {
                        radius: 6
                        color: acceptClearButton.down ? "#B91C1C" : (acceptClearButton.hovered ? "#DC2626" : "#EF4444")
                    }

                    contentItem: Text {
                        text: acceptClearButton.text
                        font.pixelSize: 13
                        font.bold: true
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        confirmClearDialog.accept();
                    }
                }
            }
        }

        onAccepted: {
            databaseManager.clearHistory();
            rootWindow.loadHistory();
        }
    }
}

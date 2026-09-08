# PasswordGuard

PasswordGuard, kullanıcıların girdikleri şifrelerin güvenlik düzeyini ve dayanıklılığını kapsamlı kurallarla analiz eden, Qt Quick (QML) ve C++ tabanlı modern bir masaüstü uygulamasıdır.

Uygulama, parola güvenliğini ölçerken kullanıcı gizliliğini temel ilke olarak benimser: **Girilen hiçbir ham şifre bellekte kalıcı olarak tutulmaz, dosyalara veya veritabanına kesinlikle kaydedilmez.** Yalnızca anonim analiz metrikleri (uzunluk, puan, seviye ve kriter özeti) saklanır.

---

## Features

- **Şifre Güvenlik Analizi**: Gerçek zamanlı ve deterministik parola analizi.
- **0–100 Güvenlik Puanı**: Kriter katkıları, yaygın şifre sıfırlaması ve ceza puanları ile hesaplanan standart puan.
- **Seviye Sınıflandırması**: Puan aralıklarına göre 4 kademeli seviye:
  - `Weak` (0 – 30)
  - `Medium` (31 – 60)
  - `Strong` (61 – 80)
  - `Very Strong` (81 – 100)
- **9 Güvenlik Kriteri Kontrolü**: Uzunluk, büyük/küçük harf, rakam, özel karakter, yaygın şifre, tekrarlayan ve sıralı karakter denetimleri.
- **Dinamik İyileştirme Önerileri**: Karşılanmayan güvenlik kriterlerine özel, kullanıcıyı yönlendiren Türkçe öneri maddeleri.
- **Yaygın Şifre Tespiti**: Gömülü 2.537 adetlik yaygın şifre sözlüğü (`common_passwords.txt`) kontrolü; tespit edildiğinde puan doğrudan 0'a eşitlenir.
- **Tekrarlayan ve Sıralı Dizi Cezaları**: Ardışık tekrarlar (örn. `aaa`) ve alfabetik/sayısal sıralı diziler (örn. `1234`, `abcd`) için puan kesintisi.
- **Maskeli Gösterim & Göster/Gizle**: Parola gizliliği için varsayılan maskeli giriş ve tek tıkla görünürlük geçişi.
- **Analiz Geçmişi (SQLite)**: Yapılan analizlerin anonim geçmiş kaydı.
- **Geçmişi Temizleme**: Kullanıcı onayı gerektiren, modern tasarımlı modal onay penceresi ile veritabanı temizleme.
- **Duyarlı (Responsive) Arayüz**: Masaüstü (iki kolonlu ızgara) ve dar ekranlarda (tek kolon hiyerarşik akış) taşma yapmayan esnek QML tasarımı.

---

## Technologies

- **C++ (C++11)**: Analiz motoru ve veri katmanı
- **Qt 5.15.x**: Uygulama çerçevesi (Core, Gui, Quick, Qml, Sql)
- **Qt Quick / QML**: Reaktif ve duyarlı kullanıcı arayüzü
- **SQLite**: Yerel anonim analiz geçmişi veritabanı
- **qmake**: Proje yapılandırma ve derleme sistemi

---

## Project Structure

```text
PasswordGuard/
├── PasswordGuard.pro               # Ana Qt uygulama proje dosyası
├── qml.qrc                         # QML ve kaynak dosyaları kaynak tanımı
├── main.cpp                        # Uygulama giriş noktası ve QML motoru
├── main.qml                        # Ana kullanıcı arayüzü ve bileşenler
├── passwordanalyzer.h              # Şifre analiz motoru başlık dosyası
├── passwordanalyzer.cpp            # Analiz ve puanlama algoritması implementasyonu
├── database.h                      # SQLite veritabanı yönetim başlık dosyası
├── database.cpp                    # Anonim kayıt ve geçmiş yönetimi implementasyonu
├── PasswordGuard_tr_TR.ts          # Türkçe yerelleştirme kaynak dosyası
├── PasswordGuard_Gereksinimler_TR.xlsx # Yetkili gereksinimler dokümanı
├── README.md                       # Proje dokümantasyonu
├── .gitignore                      # Git yoksayma kuralları
├── data/
│   └── Pwdb_top-1000.txt           # Referans veri seti
└── resources/
    ├── common_passwords.txt        # QRC gömülü 2.537 yaygın şifre listesi
    ├── logo.png                    # Vektörel tabanlı logo görseli
    └── passwordguard.ico           # Çoklu çözünürlüklü Windows uygulama ikonu
```

---

## Password Analysis

Uygulama her şifreyi aşağıdaki kurallara göre puanlar:

| Kriter | Koşul | Puan Etkisi |
| :--- | :--- | :---: |
| **Minimum Uzunluk** | En az 8 karakter | `+15` |
| **Ek Uzunluk** | En az 12 karakter | `+15` |
| **Büyük Harf** | En az 1 adet `[A-Z]` | `+15` |
| **Küçük Harf** | En az 1 adet `[a-z]` | `+15` |
| **Rakam** | En az 1 adet `[0-9]` | `+15` |
| **Özel Karakter** | En az 1 adet simge (`!@#$%^&*...`) | `+25` |
| **Yaygın Şifre** | Sözlükte eşleşme | Puan `0` olur |
| **Tekrarlayan Karakter** | 3 veya daha fazla ardışık tekrar | `-15` |
| **Sıralı Karakter Dizisi** | 4 veya daha fazla sıralı alfabetik/sayısal dizi | `-15` |

*Toplam puan her durumda `0` ile `100` arasında sınırlandırılır.*

---

## Privacy

- **PasswordGuard ham şifreleri asla saklamaz.**
- Analiz işlemi tamamen yerel cihaz üzerinde ve bellekte gerçekleşir.
- Veritabanına (`analysis_history`) yalnızca analiz tarihi, karakter uzunluğu, güvenlik puanı, güvenlik seviyesi ve karşılanan kriter özeti yazılır.

---

## Build and Run

### Gereksinimler
- Qt 5.15.x (Qt Quick, Qt Sql modülleri)
- MinGW 64-bit derleyici (örn. MinGW 8.1.0)

### Qt Creator ile
1. Qt Creator'ı açın.
2. `PasswordGuard.pro` dosyasını açın.
3. `Desktop Qt 5.15.x MinGW 64-bit` kitini seçin.
4. **Build** (Ctrl+B) ve ardından **Run** (Ctrl+R) adımlarını uygulayın.

### Komut Satırı ile
```bash
# Qt ve MinGW ortam değişkenlerini ayarlayın
qmake PasswordGuard.pro
mingw32-make release
```
Derlenen çalıştırılabilir dosya `bin/release/PasswordGuard.exe` konumunda üretilir.

### Dağıtım ve Bağımsız Çalıştırma (Standalone Deployment)
Qt kurulu olmayan sistemlerde uygulamanın bağımsız olarak çalışabilmesi için `windeployqt` ile hazırlanan dağıtım paketi:
- `dist/PasswordGuard/PasswordGuard.exe`
Bu klasör, tüm Qt runtime kütüphanelerini, QML modüllerini ve SQLite sürücüsünü içerir. Doğrudan çift tıklanarak çalıştırılabilir.

---

## Verification

Application functionality was verified during development.

Geliştirme sürecinde 8 adet backend birim testi ve uçtan uca QML/GUI doğrulama testleri başarıyla tamamlanmıştır (8/8 PASS).

---

## Requirements

Projenin tüm fonksiyonel ve teknik gereksinimleri [PasswordGuard_Gereksinimler_TR.xlsx](PasswordGuard_Gereksinimler_TR.xlsx) belgesinde tanımlanmıştır.

---

## Author

- **Esra Silahşor** (2026)


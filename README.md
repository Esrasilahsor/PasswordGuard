# 🛡️ PasswordGuard - Gelişmiş Şifre Güvenliği ve Analiz Aracı

<div align="center">

![Qt](https://img.shields.io/badge/Qt-5.15.2+-41CD52?style=for-the-badge&logo=qt&logoColor=white)
![C++](https://img.shields.io/badge/C++-17-00599C?style=for-the-badge&logo=c%2B%2B&logoColor=white)
![QML](https://img.shields.io/badge/UI-Qt_Quick_/_QML-41CD52?style=for-the-badge&logo=qt)
![SQLite](https://img.shields.io/badge/Database-SQLite3-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Linux_%7C_Windows-blue?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

<p align="center">
  <strong>PasswordGuard</strong>, kullanıcıların şifre güvenliklerini gerçek zamanlı olarak test eden, karmaşıklık ve zafiyet analizi yapan, yapıcı öneriler sunan ve gizlilik odaklı anonim analiz geçmişi tutan modern bir masaüstü uygulamasıdır.
</p>

</div>

---

## 📌 İçindekiler
- [Özellikler](#-özellikler)
- [Puanlama ve Güvenlik Seviyeleri](#-puanlama-ve-güvenlik-seviyeleri)
- [Gizlilik ve Güvenlik Politikası](#-gizlilik-ve-güvenlik-politikası)
- [Teknoloji Yığını](#-teknoloji-yığını)
- [Proje Yapısı](#-proje-yapısı)
- [Kurulum ve Derleme](#-kurulum-ve-derleme)
  - [Gereksinimler](#gereksinimler)
  - [Linux Üzerinde Derleme](#linux-üzerinde-derleme)
  - [Qt Creator ile Derleme](#qt-creator-ile-derleme)
- [Kullanım](#-kullanım)
- [Lisans](#-lisans)

---

## 🚀 Özellikler

- **Gerçek Zamanlı Analiz:** Şifre girildiği anda anlık olarak kriter kontrolleri ve puanlama gerçekleştirilir.
- **Karakter Seti Denetimi:**
  - En az 8 ve en az 12 karakter uzunluk kontrolleri
  - Büyük harf (`A-Z`), küçük harf (`a-z`), rakam (`0-9`) varlığı
  - Standart özel karakter denetimi (`!@#$%^&*()_+-=[]{}|;:,.<>?/\`~"'`)
- **Gelişmiş Zafiyet Tespiti:**
  - **Top 1000 Yaygın Şifre Tespiti:** En çok sızdırılan ve tahmin edilen 1.000 şifre ile eşleşme tespiti (puanı anında sıfırlar).
  - **Tekrarlayan Karakter Analizi:** 3 veya daha fazla ardışık aynı karakter (`aaa`, `111`) tespiti ve ceza puanı.
  - **Sıralı/Ardışık Karakter Analizi:** Artan veya azalan 4+ uzunlukta sıralı desen (`1234`, `abcd`, `4321`, `dcba`) tespiti ve ceza puanı.
- **Akıllı İyileştirme Önerileri:** Şifrenin puanını artırmak ve zafiyetleri gidermek için dinamik öneriler sunar.
- **Anonim Geçmiş Kaydı:** Yapılan analizlerin puan, kriter özeti ve güvenlik seviyelerini yerel SQLite veritabanında saklar.
- **Modern ve Duyarlı Kullanıcı Arayüzü:** Qt Quick / QML ile geliştirilmiş şık, akıcı ve kullanıcı dostu arayüz.

---

## 📊 Puanlama ve Güvenlik Seviyeleri

Puanlama sistemi **0 ile 100** puan arasında dinamik olarak hesaplanır:

### Kriter Puan Dağılımı
| Kriter | Açıklama | Puan Etkisi |
| :--- | :--- | :---: |
| **Uzunluk ≥ 8** | Şifre en az 8 karakter | `+15` |
| **Uzunluk ≥ 12** | Şifre en az 12 karakter (yüksek güvenlik) | `+15` |
| **Büyük Harf** | En az bir büyük harf (`A-Z`) | `+15` |
| **Küçük Harf** | En az bir küçük harf (`a-z`) | `+15` |
| **Rakam** | En az bir rakam (`0-9`) | `+15` |
| **Özel Karakter** | En az bir özel sembol (`!@#$%...`) | `+25` |
| **Tekrarlayan Dizi** | 3+ aynı karakter ardışıklığı (`aaa`, `111`) | Her desen için `-15` |
| **Sıralı Dizi** | 4+ sıralı ardışıklık (`1234`, `abcd` vb.) | Her desen için `-15` |
| **Yaygın Şifre** | İlk 1000 popüler şifre listesinde bulunma | **Puan: 0** |

### Güvenlik Seviyesi Aralıkları
- 🔴 **Weak (Zayıf):** 0 - 30 Puan
- 🟡 **Medium (Orta):** 31 - 60 Puan
- 🟢 **Strong (Güçlü):** 61 - 80 Puan
- 🔵 **Very Strong (Çok Güçlü):** 81 - 100 Puan

---

## 🔒 Gizlilik ve Güvenlik Politikası

> [!IMPORTANT]
> **PasswordGuard, kullanıcının girdiği ham (düz metin) şifreyi ASLA veritabanına, dosyalara veya belleğe kalıcı olarak kaydetmez.**

- Veritabanında yalnızca **analiz tarihi**, **şifre uzunluğu**, **başarılı kriterler**, **puan** ve **güvenlik seviyesi** tutulur.
- Analiz yerel olarak cihazınızda gerçekleştirilir, hiçbir veri harici sunucuya veya internete gönderilmez.

---

## 🛠 Teknoloji Yığını

- **Backend:** C++17
- **Frontend / UI:** Qt Quick 2.15, QML, Qt Graphical Effects
- **Veritabanı:** Qt SQL (SQLite 3)
- **Derleme Sistemi:** QMake / Make (GCC / MinGW / Clang)

---

## 📁 Proje Yapısı

```plaintext
PasswordGuard/
├── bin/                       # Derlenmiş çalıştırılabilir ikili (binary) dosyalar
│   └── PasswordGuard
├── data/                      # Veri dosyaları ve sözlükler
│   ├── Pwdb_top-1000.txt      # 1000 yaygın şifre veri tabanı
│   └── logo.png               # Uygulama logosu
├── database.h / .cpp          # SQLite geçmiş yönetimi ve anonim kayıt motoru
├── passwordanalyzer.h / .cpp  # Şifre analiz, entropi ve puanlama çekirdeği
├── main.qml                   # Modern QML kullanıcı arayüzü
├── main.cpp                   # Qt uygulama giriş noktası
├── qml.qrc                    # Qt kaynak dosyası (Resource bundle)
├── PasswordGuard.pro          # QMake proje konfigürasyon dosyası
├── .gitignore                 # Git yoksayma kuralları
└── README.md                  # Proje dokümantasyonu
```

---

## 💻 Kurulum ve Derleme

### Gereksinimler
- **Qt:** 5.15.x veya üzeri (Quick, Qml, Sql modülleri)
- **C++ Derleyici:** GCC 7+, Clang 6+ veya MSVC 2019+
- **Make / Ninja**

### Linux Üzerinde Komut Satırından Derleme

1. Depoyu klonlayın:
```bash
git clone https://github.com/KullaniciAdi/PasswordGuard.git
cd PasswordGuard
```

2. Release derlemesi oluşturun:
```bash
mkdir -p build/release
cd build/release
qmake ../../PasswordGuard.pro CONFIG+=release
make -j$(nproc)
```

3. Uygulamayı çalıştırın:
```bash
./PasswordGuard
```

*(veya `bin/PasswordGuard` dosyasını doğrudan çalıştırabilirsiniz)*

### Qt Creator ile Derleme
1. **Qt Creator**'ı açın.
2. `Dosya -> Dosya veya Proje Aç...` menüsünden `PasswordGuard.pro` dosyasını seçin.
3. Uygun Kit'i (örn. Qt 5.15.2 GCC / MinGW 64-bit) seçerek projeyi yapılandırın.
4. **Ctrl + R** kısayolu ile projeyi derleyip çalıştırın.

---

## 📖 Kullanım

1. Uygulama açıldığında parola giriş alanına analiz etmek istediğiniz şifreyi yazın.
2. Anlık olarak:
   - Şifre puanınız ve seviyeniz güncellenir.
   - Karşılanan ve karşılanmayan kriterler yeşil/kırmızı göstergelerle belirtilir.
   - Şifrenizi güçlendirmek için uygulanabilecek öneriler listelenir.
3. **Analizi Kaydet** butonuna basarak sonucu anonim olarak geçmişe kaydedebilirsiniz.
4. **Geçmiş** sekmesinden önceki analizlerinizi inceleyebilir veya tek tıkla geçmişi temizleyebilirsiniz.

---

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) altında lisanslanmıştır. Detaylar için lisans dosyasına başvurabilirsiniz.

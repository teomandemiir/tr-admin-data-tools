# tr-admin-data-tools

Utilities for reading, cleaning, and writing Turkish administrative data files in R.

---

## Overview

Turkish administrative datasets (tax records, enterprise registries, labour force surveys) share a common set of formatting conventions that differ from R's defaults: ISO-8859-9 encoding, semicolon delimiters, comma-as-decimal, and period-as-thousands separator. Base R and `readr` do not handle this combination out of the box without manual configuration on every read call.

`profil_TR` centralises these settings in a single profile object. All reading and writing functions consume the profile, so format parameters are defined once and applied consistently across a project.

## Features

- Profile-driven CSV/TXT/XLS/XLSX/RDS reading
- Türkçe numeric strings (`"1.234,56"`) safely converted to `numeric` via `fixed()` matching — no regex side-effects
- `as.character()` guard in `destring_column()` handles unexpected column types without error
- `normalize_exclude` keeps identifier columns (tax ID, IBAN, etc.) out of `tolower()` normalization
- Missing or misnamed destring targets raise `warning()` rather than failing silently
- `iconv()`-backed writing for reliable ISO-8859-9 output across platforms
- All profile fields overridable at call time via `modifyList()`

## Structure

```
tr-admin-data-tools/
├── README.md
├── R/
│   └── profil_TR.R       # Profile definition and core functions
└── demo/
    └── demo_profil_TR.R  # Synthetic data walkthrough
```

## Requirements

```r
# stringr  >= 1.5.0
# dplyr    >= 1.1.0
# readr    >= 2.1.0
# readxl   >= 1.4.0

install.packages(c("stringr", "dplyr", "readr", "readxl"))
```

Dependency pinning via [`renv`](https://rstudio.github.io/renv/) is recommended for production use.

## Usage

```r
source("R/profil_TR.R")

# Basic read
veri <- veri_cek_TR("data/firms.csv")

# Destring specific columns, protect identifier columns from lowercasing
profil <- modifyList(profil_TR, list(
  destring_columns  = c("ciro", "calisan_sayisi"),
  normalize_exclude = c("vergi_no", "tc_kimlik")
))
veri <- veri_cek_TR("data/firms.csv", profil = profil)

# Write back
veri_yaz_TR(veri, "output/firms_clean.csv")

# Override separator (tab-delimited source)
profil_tab <- modifyList(profil_TR, list(separator = "\t"))
veri <- veri_cek_TR("data/firms.txt", profil = profil_tab)
```

See `demo/demo_profil_TR.R` for a self-contained walkthrough with synthetic data.

---

---

# tr-admin-data-tools

Türkiye idari veri dosyalarını R'da okumak, temizlemek ve yazmak için yardımcı fonksiyonlar.

---

## Genel Bakış

Türkiye kaynaklı idari veri setleri (vergi kayıtları, girişim registerleri, hanehalkı işgücü anketleri) R'ın varsayılanlarından farklı bir format kullanır: ISO-8859-9 encoding, noktalı virgül ayraç, ondalık için virgül, binlik için nokta. Base R ve `readr`, bu kombinasyonu her okuma çağrısında manuel yapılandırma olmadan doğru işleyemez.

`profil_TR`, bu ayarları tek bir profil nesnesinde toplar. Tüm okuma ve yazma fonksiyonları bu profile göre çalışır; format parametreleri bir kez tanımlanır, proje genelinde tutarlı biçimde uygulanır.

## Özellikler

- Profil güdümlü CSV/TXT/XLS/XLSX/RDS okuma
- Türkçe sayı dizgeleri (`"1.234,56"`) `fixed()` eşleşmesiyle güvenli biçimde `numeric`'e çevrilir — regex yan etkisi yoktur
- `destring_column()` içindeki `as.character()` koruması beklenmedik sütun tiplerini hatasız işler
- `normalize_exclude` ile kimlik sütunları (vergi no, IBAN vb.) `tolower()` normalizasyonu dışında tutulur
- Hatalı veya eksik destring hedefleri sessiz geçmez; `warning()` basar
- `iconv()` destekli yazma ile platformdan bağımsız güvenilir ISO-8859-9 çıktısı
- Tüm profil alanları `modifyList()` ile çağrı anında geçersiz kılınabilir

## Yapı

```
tr-admin-data-tools/
├── README.md
├── R/
│   └── profil_TR.R       # Profil tanımı ve temel fonksiyonlar
└── demo/
    └── demo_profil_TR.R  # Sentetik veriyle çalışan örnek
```

##  Gerekli Paketler

```r
# stringr  >= 1.5.0
# dplyr    >= 1.1.0
# readr    >= 2.1.0
# readxl   >= 1.4.0

install.packages(c("stringr", "dplyr", "readr", "readxl"))
```

Kurumsal ortamlarda bağımlılık yönetimi için [`renv`](https://rstudio.github.io/renv/) önerilir.

## Kullanım

```r
source("R/profil_TR.R")

# Temel okuma
veri <- veri_cek_TR("veri/firmalar.csv")

# Belirli sütunları sayısallaştır, kimlik sütunlarını koru
profil <- modifyList(profil_TR, list(
  destring_columns  = c("ciro", "calisan_sayisi"),
  normalize_exclude = c("vergi_no", "tc_kimlik")
))
veri <- veri_cek_TR("veri/firmalar.csv", profil = profil)

# Geri yaz
veri_yaz_TR(veri, "cikti/firmalar_temiz.csv")

# Ayracı değiştir (tab ayraçlı kaynak)
profil_tab <- modifyList(profil_TR, list(separator = "\t"))
veri <- veri_cek_TR("veri/firmalar.txt", profil = profil_tab)
```

Sentetik veriyle çalışan tam örnek için `demo/demo_profil_TR.R` dosyasına bakın.

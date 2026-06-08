# ==============================================================================
# profil_TR.R Türkiye idari veri kaynaklarına özgü okuma/yazma profili ve yardımcı
# fonksiyonlar. [ISO-8859-9 encoding, separator, decimal_mark etc.]
# ==============================================================================

# Gerekli Paketler -------------------------------------------------------------
# Bu modül aşağıdaki paketlere ihtiyaç duyar. Kurulu ve güncel olduklarından
# emin olun. install.packages() kurumsal ortamlarda kısıtlı olabilir;
# paket yönetimi için renv kullanmanız önerilir.
#
install.packages(c("stringr", "dplyr", "readr", "readxl"))
#
# Test edilen versiyonlar:
#   stringr  >= 1.5.0
#   dplyr    >= 1.1.0
#   readr    >= 2.1.0
#   readxl   >= 1.4.0

library(stringr)   # str_replace_all(), fixed()
library(dplyr)     # mutate(), across()
library(readr)     # read_csv() (opsiyonel; şimdilik read.csv() kullanılıyor)
library(readxl)    # read_excel()

# Profil tanımı ------------------------------------------------------------
# Tüm alanlar değiştirilebilir. Farklı kaynak formatları için profil_TR'yi
# modifyList() ile türetin; orijinali bozmayın.
#
# Örnekler:
#   Tab ayraçlı:   modifyList(profil_TR, list(separator = "\t"))
#   Pipe ayraçlı:  modifyList(profil_TR, list(separator = "|"))
#   US formatı:    modifyList(profil_TR, list(separator = ",",
#                                             decimal_mark = ".",
#                                             thousand_mark = ","))
#
# NOT — US formatı örneği: thousand_mark ve decimal_mark aynı karakter
# olamaz. "1,234.56" işlenirken önce binlik "," silinir ("1234.56"),
# sonra ondalık "." noktaya çevrilir (zaten nokta). Bu sıra korunmalıdır.

profil_TR <- list(
  encoding               = "ISO-8859-9",  # Windows-1254 ile örtüşür
  separator              = ";",           # Değiştirilebilir: "\t", ",", "|" vb.
  decimal_mark           = ",",           # Değiştirilebilir: US formatı için "."
  thousand_mark          = ".",           # Değiştirilebilir: US formatı için ","
  convert_columns_to_lower = TRUE,        # Sütun adlarını küçük harfe çevirir
  destring_columns       = NULL,          # Sayısallaştırılacak sütun adları (karakter vektörü)
  normalize_exclude      = character(0)   # tolower() dışında tutulacak sütunlar
                                          # (örn. c("vergi_no", "iban", "tc_kimlik"))
)

# Yardımcı fonksiyonlar ----------------------------------------------------

# destring_column:
#   R, CSV okurken bir sütunda harf veya noktalama görürse tüm sütunu karakter
#   tipinde tutar — sayısal görünen değerleri bile. colClasses = "character"
#   ile bunu bilerek zorluyoruz; ardından bu fonksiyon Türkçe biçimli
#   dizgeleri (örn. "1.234,56") numeric'e çevirir.
#
#   Girdi tipi garantisi:
#     Fonksiyon karakter girdi bekler. Farklı bir tip gelirse (integer, numeric,
#     logical) as.character() ile önce karakter'e çevrilir; dönüşüm kaybı olmaz.
#
#   NA davranışı:
#     as.numeric() dönüşemeyen değeri (boş hücre, "-", "N/A", "—" vb.)
#     otomatik olarak NA yapar. R bu değerlere kendi başına 0 veya NULL atamaz.
#     NA'larla ne yapılacağı (silme, doldurma, bırakma) analiz adımına aittir;
#     bu fonksiyon karar vermez.
#
#   UYARI: str_replace_all() regex kullanır. "." regex'te "herhangi karakter"
#   anlamına gelir; fixed() olmadan tüm karakterler silinir.

destring_column <- function(v, decimal = ",", thousand = ".") {
  if (!is.character(v)) v <- as.character(v)  # tip garantisi
  v |>
    str_replace_all(fixed(thousand), "") |>    # binlik ayracı kaldır (literal)
    str_replace_all(fixed(decimal),  ".") |>   # ondalık ayracı noktaya çevir
    as.numeric()                               # dönüşemeyen → NA (0 veya NULL değil)
}

# normalize_character_columns:
# Tüm karakter sütunlarını küçük harfe indirir. Birleştirme ve filtreleme
# işlemlerinde büyük/küçük harf tutarsızlıklarını ortadan kaldırır.
# normalize_exclude listesindeki sütunlar atlanır — kimlik numarası, IBAN,
# tarih dizgesi gibi alanları korumak için kullanın.

normalize_character_columns <- function(df, exclude = character(0)) {
  cols_to_normalize <- setdiff(names(df)[sapply(df, is.character)], exclude)
  df |> mutate(across(all_of(cols_to_normalize), ~ tolower(.x)))
}

# Veri Seti Okuma ---------------------------------------------------------------

# veri_cek_TR:
#   Dosya uzantısına göre otomatik okuma yapar.
#   CSV/TXT: profil parametreleri (encoding, sep, dec) uygulanır.
#   XLS/XLSX: read_excel() encoding argümanı almaz, doğrudan UTF-8 okur;
#             profil$encoding bu formatlarda uygulanmaz.
#   RDS:      R'ın kendi ikili formatı, encoding dönüşümü gerekmez.

veri_cek_TR <- function(dosya_yolu, profil = profil_TR) {
  uzanti <- tolower(tools::file_ext(dosya_yolu))

  veri <- switch(
    uzanti,
    csv = read.csv(
      dosya_yolu,
      fileEncoding     = profil$encoding,
      sep              = profil$separator,
      dec              = profil$decimal_mark,
      stringsAsFactors = FALSE,
      colClasses       = "character"  # tüm sütunlar karakter; destring sonra yapılır
    ),
    txt = read.delim(
      dosya_yolu,
      fileEncoding     = profil$encoding,
      sep              = profil$separator,
      dec              = profil$decimal_mark,
      stringsAsFactors = FALSE,
      colClasses       = "character"
    ),
    xls  = read_excel(dosya_yolu),   # UTF-8, encoding profili uygulanmaz
    xlsx = read_excel(dosya_yolu),
    rds  = readRDS(dosya_yolu),
    stop("Desteklenmeyen dosya uzantısı: ", uzanti)
  )

  # Sütun adlarını küçük harfe çevir
  if (isTRUE(profil$convert_columns_to_lower)) {
    names(veri) <- tolower(names(veri))
  }

  # Karakter sütunlarını küçük harfe çevir (normalize_exclude'dakiler atlanır)
  veri <- normalize_character_columns(veri, exclude = profil$normalize_exclude)

  # Belirtilen sütunları sayısallaştır.
  #   - destring_columns NULL ise bu blok tamamen atlanır.
  #   - Listede olan ama veride bulunmayan sütun adı warning() basar ve geçilir.
  #     Sessiz geçmez; sütunun sayısallaştırılıp laştırılmadığını kontrol edin.
  #   - Dönüşemeyen hücreler NA olur; 0 veya NULL atanmaz.
  if (!is.null(profil$destring_columns)) {
    for (col in profil$destring_columns) {
      if (col %in% names(veri)) {
        veri[[col]] <- destring_column(
          veri[[col]],
          decimal  = profil$decimal_mark,
          thousand = profil$thousand_mark
        )
      } else {
        warning("destring: '", col, "' sütunu veride bulunamadı, atlandı.")
      }
    }
  }

  return(veri)
}

# --- Veri yazma ---------------------------------------------------------------

# veri_yaz_TR:
#   write.table() ile sep ve dec profil üzerinden kontrol edilir.
#
# Encoding güvencesi:
# Windows'ta write.table(..., fileEncoding = "ISO-8859-9") her zaman
# doğru sonuç vermeyebilir; locale ve R versiyonuna göre davranış değişir.
# iconv() ile önce veriyi hedef encoding'e dönüştürüp ardından yazıyoruz.
# Dönüşemeyen karakterler "?" ile ikame edilir — çıktıyı açıp kontrol edin.

veri_yaz_TR <- function(df, dosya, profil = profil_TR) {
# Karakter sütunlarını hedef encoding'e çevir
  df <- df |> mutate(across(
    where(is.character),
    ~ iconv(.x, from = "UTF-8", to = profil$encoding, sub = "?")
  ))

  write.table(
    df,
    file      = dosya,
    sep       = profil$separator,    # profil$separator = ";" (değiştirilebilir)
    dec       = profil$decimal_mark,
    row.names = FALSE,
    quote     = TRUE,
    fileEncoding = profil$encoding
  )
}

# Kaynak gösterimi ---------------------------------------------------------
# Bu dosyayı projeye dahil etmek için:
source("R/moduller/profil_TR.R")

# Örnek kullanım -----------------------------------------------------------
# Temel okuma:
veri <- veri_cek_TR("veri/abc.csv")

# Belirli sütunları sayısallaştır:
profil <- modifyList(profil_TR, list(destring_columns = c("tutar", "adet")))
veri   <- veri_cek_TR("veri/abc.csv", profil = profil)

# Kimlik sütunlarını normalize dışında tut:
profil <- modifyList(profil_TR, list(normalize_exclude = c("vergi_no", "tc_kimlik")))
veri   <- veri_cek_TR("veri/abc.csv", profil = profil)

# Yazma için:
veri_yaz_TR(veri, "cikti/abc_temiz.csv")

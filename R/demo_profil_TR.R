# ==============================================================================
# demo_profil_TR.R
# profil_TR modülünün sentetik veriyle çalışan örneği.
# Gerçek veri kullanılmamıştır; workflow otantiktir.
# ==============================================================================

source("R/profil_TR.R")

# --- Sentetik CSV oluştur -----------------------------------------------------
# Türkiye idari kaynaklarında sık karşılaşılan format:
#   - ISO-8859-9 encoding (burada UTF-8 simüle ediyoruz)
#   - Noktalı virgül ayraç
#   - Türkçe ondalık (virgül) ve binlik (nokta) gösterimi
#   - Karışık büyük/küçük harf

tmp <- tempfile(fileext = ".csv")

writeLines(
  c(
    "vergi_no;firma_adi;il;ciro;calisan_sayisi;kurulis_yili",
    "1234567890;YILDIZ GIDA A.S.;İSTANBUL;1.250.000,75;48;2005",
    "9876543210;Anadolu Tekstil Ltd.;BURSA;875.300,00;23;2011",
    "1111111111;güneş makina san.;Ankara;-;7;2018",   # ciro eksik → NA beklenir
    "2222222222;Deniz Lojistik A.Ş.;İZMİR;3.002.500,50;112;2001"
  ),
  con = tmp,
  useBytes = TRUE
)

# --- Profil türet: ciro ve calisan_sayisi sayısallaştırılacak -----------------
# vergi_no normalize_exclude'da — tolower() kimlik sütununa dokunmasın.
profil <- modifyList(profil_TR, list(
  destring_columns  = c("ciro", "calisan_sayisi", "kurulis_yili"),
  normalize_exclude = c("vergi_no")
))

# --- Oku ----------------------------------------------------------------------
veri <- veri_cek_TR(tmp, profil = profil)

cat("\n--- Okunan veri ---\n")
print(veri)
cat("\n--- Sütun tipleri ---\n")
print(sapply(veri, class))

# --- NA kontrolü --------------------------------------------------------------
# "ciro" sütununda "-" değeri NA'ya dönüşmüş olmalı.
cat("\n--- NA kontrolü (ciro) ---\n")
print(veri[is.na(veri$ciro), c("vergi_no", "firma_adi", "ciro")])

# --- Yaz ----------------------------------------------------------------------
cikti <- tempfile(fileext = ".csv")
veri_yaz_TR(veri, cikti, profil = profil)

cat("\n--- Yazılan dosyanın ilk satırları ---\n")
cat(readLines(cikti, n = 3), sep = "\n")

# Geçici dosyaları temizle
unlink(c(tmp, cikti))
cat("\nDemo tamamlandı.\n")

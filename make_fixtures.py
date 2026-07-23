"""Banka ekstresi içe aktarma senaryoları (Bölüm 4) için GERÇEKÇİ test
fixture'ları üretir: CSV + XLSX + PDF.

ÖNEMLİ: Bu script yalnızca GİRDİ VERİSİ (fixture) üretir — test sonucunu ya da
senaryo durumunu ASLA yazmaz. Smoke test'in kendisi (adımların uygulanması,
gözlem, ✅/❌ işaretlemesi) elle/ADB ile bizzat yapılmalıdır.

Eski `create_pdf.py` yalnız 4 satırlık düz metin üretiyordu; parser'ın gerçek
riskli dalları (Bakiye sütunu, TR/EN binlik-ayraç ayrımı, çok-satıra saran
açıklama) hiç test edilmiyordu. Bu sürüm o dalları bilerek tetikler.

Çalıştır:  python3 make_fixtures.py
Çıktı:     mock_statement.csv, mock_statement.xlsx, mock_statement.pdf
"""

# (Tarih, Açıklama, Tutar, Bakiye) — TR biçim: virgül ondalık, nokta binlik.
# "Market"/"Fatura"/"Maaş"/"Benzin"/"Eczane" kategori-tahmin motorunu; "Midas
# Menkul Değerler" ise category_guesser'daki gerçek Akbank örneğini tetikler.
ROWS = [
    ("15/07/2026", "Market Alışverişi - MIGROS", "-250,00", "4.750,00"),
    ("16/07/2026", "MAAŞ ÖDEMESİ TEMMUZ 2026 BORDRO REF 998877", "15.000,00", "19.750,00"),
    ("17/07/2026", "Elektrik Faturası - CK ENERJI", "-1.234,56", "18.515,44"),
    ("18/07/2026", "ATM Nakit Çekme", "-500,00", "18.015,44"),
    ("19/07/2026", "Benzin - OPET", "-900,00", "17.115,44"),
    ("20/07/2026", "Eczane - Sağlık", "-175,25", "16.940,19"),
    ("21/07/2026", "Midas Menkul Değerler Transferi", "-2.000,00", "14.940,19"),
]

HEADER = ("Tarih", "Açıklama", "Tutar", "Bakiye")


def make_csv(path="mock_statement.csv"):
    # Gerçek TR banka export'ları ';' ayraç kullanır (çünkü ',' ondalık ayracı).
    # Bu, uygulamanın delimiter + TR-ondalık otomatik algılamasını sınar.
    lines = [";".join(HEADER)]
    lines += [";".join(r) for r in ROWS]
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(f"[ok] {path} ({len(ROWS)} hareket, ';' ayraç, TR ondalık)")


def make_xlsx(path="mock_statement.xlsx"):
    try:
        from openpyxl import Workbook
    except ImportError:
        print(f"[atlandı] {path}: openpyxl yok (pip install openpyxl)")
        return
    wb = Workbook()
    ws = wb.active
    ws.title = "Hesap Özeti"
    ws.append(["AKBANK T.A.Ş. - Hesap Özeti / Ekstre"])
    ws.append(["Para Birimi: TL", "Dönem: 01/07/2026 - 31/07/2026"])
    ws.append([])
    ws.append(list(HEADER))
    for r in ROWS:
        # Excel'de tutar/bakiyeyi metin olarak bırakıyoruz ki uygulamanın TR
        # ondalık ayrıştırması sınansın (gerçek export'lar da çoğu kez metindir).
        ws.append(list(r))
    wb.save(path)
    print(f"[ok] {path} ({len(ROWS)} hareket)")


def make_pdf(path="mock_statement.pdf"):
    try:
        from reportlab.pdfgen import canvas
    except ImportError:
        print(f"[atlandı] {path}: reportlab yok (pip install reportlab)")
        return
    c = canvas.Canvas(path)
    c.setFont("Helvetica-Bold", 12)
    # Başlık: "akbank" ilk 20 satırda geçmeli ki AkbankPdfParser tetiklensin.
    c.drawString(40, 800, "AKBANK T.A.S. - Hesap Ozeti / Ekstre")
    c.setFont("Helvetica", 9)
    c.drawString(40, 785, "Musteri: Test Kullanici   IBAN: TR00 0004 6000 0000 0000 0000 01")
    c.drawString(40, 772, "Hesap No: 1234567   Para Birimi: TL   Donem: 01/07/2026 - 31/07/2026")

    # Sütun x konumları — layoutText:true çıkarımında Tutar+Bakiye yan yana
    # gelir; parser 2 parasal token'dan sondan bir öncekini (Tutar) seçmeli.
    x_date, x_desc, x_amt, x_bal = 40, 120, 380, 470
    y = 745
    c.setFont("Helvetica-Bold", 9)
    c.drawString(x_date, y, HEADER[0])
    c.drawString(x_desc, y, HEADER[1])
    c.drawString(x_amt, y, HEADER[2])
    c.drawString(x_bal, y, HEADER[3])
    c.setFont("Helvetica", 9)
    y -= 18

    for i, (date, desc, amt, bal) in enumerate(ROWS):
        c.drawString(x_date, y, date)
        c.drawString(x_amt, y, amt)
        c.drawString(x_bal, y, bal)
        # 2. satır (16/07 maaş): açıklamayı bilerek İKİ fiziksel satıra sararak
        # parser'ın "tarihle başlamayan satır = önceki kaydın devamı" mantığını
        # sınıyoruz. İlk parça tarih satırında, devamı altta (tarihsiz).
        if i == 1:
            c.drawString(x_desc, y, "MAAS ODEMESI TEMMUZ 2026")
            y -= 13
            c.drawString(x_desc, y, "BORDRO REF 998877 (devam satiri)")
        else:
            c.drawString(x_desc, y, desc.replace("İ", "I").replace("ı", "i"))
        y -= 20
    c.save()
    print(f"[ok] {path} ({len(ROWS)} hareket, Bakiye sutunlu + saran aciklama)")


if __name__ == "__main__":
    make_csv()
    make_xlsx()
    make_pdf()
    print("Fixture'lar hazir. Smoke test'i ELLE/ADB ile bizzat kosun; durumu "
          "script'le degil, gercek gozleme gore isaretleyin.")

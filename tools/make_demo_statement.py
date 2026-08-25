#!/usr/bin/env python3
"""Mağaza karesi için SAHTE banka ekstresi (CSV) üretir.

Neden: ekstre içe aktarma ekranı vitrinin en güçlü karesi ama gerçek bir
ekstreyle çekilemez — açıklamalar, tutarlar ve şube adları kişisel veridir.
Bu betik hiçbir gerçek kaydı taşımayan, ama uygulamanın ayrıştırıcısından
tam not alan bir dosya üretir.

İki şeye dikkat edildi:

* **Açıklamalar tanınır olmalı.** `CategoryGuesser` kategoriyi AÇIKLAMADAN
  tahmin ediyor. "115 kategorisiz" yazan bir kare özelliği satmıyor, tersine
  "bu iş yarım kalıyor" izlenimi veriyor. Buradaki açıklamalar sözlüğün
  MARKA OLMAYAN anahtarlarını kullanır (market, restoran, kafe, akaryakit,
  otopark, taksi...) — gerçek marka adı Play'de fikri mülkiyet itirazına
  açık alan bırakır.
* **Bakiye zinciri tutmalı.** Ekran "Aritmetik olarak doğrulandı · Bakiye
  zinciri N/N" rozetini ekstrenin kendi bakiye sütunuyla hesabı
  karşılaştırarak veriyor (`statement_verification`). Bakiye her satırda
  yeniden hesaplanır; elle yazılsa rozet kırmızıya döner ve kare değerini
  kaybeder.

Kullanım:
    python3 tools/make_demo_statement.py ornek_ekstre.csv
"""

from __future__ import annotations

import csv
import random
import sys
from datetime import date, timedelta

RNG = random.Random(20260825)

# Açılış, en düşük ara bakiye bile eksiye düşmeyecek kadar yüksek:
# eksi bakiyeli bir ekstre vitrinde "batmış hesap" izlenimi veriyor.
OPENING = 47_800.00

# (açıklama, tutar) — tutar negatifse gider. Açıklamalar CategoryGuesser'ın
# jenerik anahtarlarına denk gelir; marka adı YOK.
PATTERNS: list[tuple[str, float, float]] = [
    ("MARKET ALISVERISI", -180, -1450),
    ("MARKET ALISVERISI", -220, -980),
    ("RESTORAN ODEMESI", -240, -1180),
    ("KAFE ODEMESI", -85, -320),
    ("AKARYAKIT ISTASYONU", -900, -2400),
    ("OTOPARK UCRETI", -40, -160),
    ("TAKSI ODEMESI", -110, -420),
    ("ECZANE ODEMESI", -95, -640),
    ("ELEKTRIK FATURASI", -380, -1250),
    ("SU FATURASI", -110, -340),
    ("DOGALGAZ FATURASI", -260, -1400),
    ("INTERNET FATURASI", -420, -680),
    ("TELEFON FATURASI", -300, -560),
    ("SINEMA ODEMESI", -140, -420),
    ("SPOR SALONU UYELIGI", -750, -1350),
    ("KIRTASIYE ODEMESI", -60, -280),
    ("KUAFOR ODEMESI", -250, -700),
]


def main() -> None:
    out = sys.argv[1] if len(sys.argv) > 1 else "ornek_ekstre.csv"

    today = date.today()
    start = today - timedelta(days=88)

    rows: list[tuple[date, str, float]] = []
    day = start
    while day <= today:
        # Maaş: her ayın 5'i.
        if day.day == 5:
            rows.append((day, "MAAS ODEMESI", 52_400.00))
        # Kira: her ayın 1'i.
        if day.day == 1:
            rows.append((day, "KIRA ODEMESI", -18_500.00))

        for _ in range(RNG.randint(0, 3)):
            desc, lo, hi = RNG.choice(PATTERNS)
            amount = round(RNG.uniform(lo, hi), 2)
            rows.append((day, desc, amount))
        day += timedelta(days=1)

    rows.sort(key=lambda r: r[0])

    # Bakiye HER SATIRDA yeniden hesaplanır; ekranın doğrulama rozeti buna
    # bakıyor (bkz. modül başlığı).
    balance = OPENING
    with open(out, "w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh, delimiter=";")
        w.writerow(["Tarih", "Açıklama", "Tutar", "Bakiye"])
        for d, desc, amount in rows:
            balance = round(balance + amount, 2)
            w.writerow([
                d.strftime("%d.%m.%Y"),
                desc,
                f"{amount:.2f}".replace(".", ","),
                f"{balance:.2f}".replace(".", ","),
            ])

    income = sum(a for _, _, a in rows if a > 0)
    expense = -sum(a for _, _, a in rows if a < 0)
    print(f"{out} yazıldı")
    print(f"  {len(rows)} hareket, {rows[0][0]} → {rows[-1][0]}")
    print(f"  açılış {OPENING:,.2f}  gelir {income:,.2f}  "
          f"gider {expense:,.2f}  kapanış {balance:,.2f}")


if __name__ == "__main__":
    main()

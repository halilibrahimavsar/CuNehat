#!/usr/bin/env python3
"""Mağaza ekran görüntüleri için SAHTE veri yedeği üretir (şema v9).

Neden: Play listelemesinde gerçek kişisel finans verisi gösterilmemeli, ama
3 işlemlik boş bir liste de "kimse kullanmıyor" izlenimi verir. Bu betik
inandırıcı ama tamamen uydurma bir defter üretir.

TARİHE GÖRELİ üretir (bugünden geriye ~4 ay). Sebebi bütçe ekranı:
GetBudgetsUsecase harcamayı `DateTime.now()`un AYINDAN sayıyor, sabit tarihli
veri bir sonraki ay bütçeleri boş gösterirdi.

Uygulamanın koruduğu değişmezler burada da korunur, yoksa uygulama açılışta
kendi hesabını yazıp ekrandaki rakamları değiştirir:
  balance    = openingBalance + Σ imzalı(tüm işlemler)     (syncBalance)
  debt       = Σ remainingAmount(ödenmemiş borçlar)        (syncDebt)
  credit     = Σ amount(tahsil edilmemiş alacaklar)        (syncCredit)
  investment = Σ currentValue(yatırımlar)                  (syncInvestment)

İçerik, önerilen ekran görüntüsü setine göre seçildi:
  * 3 birikim hedefi FARKLI dolulukta (%28 / %69 / %87) + 1 bağsız varlık
  * iki altın kaydı da varsayılan amber → halka grafiğinin renk ayrıştırması
    ekranda görünür
  * biri taksitli (12 ay), biri taksitsiz (termMonths=0 + vade tarihi) borç
  * 7 düzenli şablon; 2'si onay bekliyor, 5'i yaklaşan
    (iki sekme de dolu görünmeli — sıfır/az sayaç özelliği anlatmıyor)
  * bu ayda maaş dışında 2 gelir kalemi (rapor tek dilime düşmesin)
  * bütçelerde biri aşılmış (%111), gerisi %27'ye kadar iniyor

Üçüncü taraf marka adı YOK: gerçek banka/şirket adı, uygulamanın o kurumla
resmî bir ilişkisi varmış izlenimi verip Play incelemesinde fikri mülkiyet
itirazına açık alan bırakıyor.

Şema uyumu `test/tools/demo_backup_generator_test.dart` ile kilitli: betik
çalıştırılıp çıktısı uygulamanın KENDİ ayrıştırıcısına veriliyor.

Kullanım:
    python3 tools/make_demo_backup.py cunehat_demo.json
"""

from __future__ import annotations

import json
import random
import sys
import uuid
from datetime import date, datetime, timedelta

# Üretim tekrarlanabilir olsun: aynı tohum aynı defteri verir, ekran
# görüntüsünü yeniden çekmek gerekirse rakamlar değişmez.
RNG = random.Random(20260821)

USER = "local_user"
TODAY = date.today()

# CashMovementTags (wallet_metrics_service.dart) — bunlar kategori DEĞİL.
TAG_DEBT = "Borç"
TAG_DEBT_PAYMENT = "Borç Ödemesi"
TAG_RECEIVABLE = "Alacak"
TAG_RECEIVABLE_COLLECTION = "Alacak Tahsilatı"
TAG_INVESTMENT_BUY = "Yatırım Alımı"

# category_starter_pack.dart ile birebir aynı (ada göre eşleşen ekstre
# tahmini sözlüğü bozulmasın).
EXPENSE_PACK = [
    ("Market", "shopping_cart", [("Manav", "restaurant"), ("Kasap", "restaurant"),
                                 ("Su & İçecek", "local_cafe")]),
    ("Yemek", "restaurant", [("Restoran", "restaurant"), ("Kafe", "local_cafe"),
                             ("Paket Servis", "two_wheeler")]),
    ("Ulaşım", "directions_bus", [("Yakıt", "local_gas_station"),
                                  ("Toplu Taşıma", "directions_bus"),
                                  ("Taksi", "local_taxi"),
                                  ("Otopark", "directions_car")]),
    ("Fatura", "receipt_long", [("Elektrik", "lightbulb"), ("Su", "water_drop"),
                                ("Doğalgaz", "emergency"), ("İnternet", "language"),
                                ("Telefon", "phone_android")]),
    ("Konut", "home", [("Kira", "home"), ("Aidat", "apartment"),
                       ("Bakım & Onarım", "construction")]),
    ("Alışveriş", "shopping_bag", [("Giyim", "checkroom"), ("Elektronik", "devices"),
                                   ("Ev Eşyası", "chair")]),
    ("Sağlık", "medical_services", [("İlaç", "health_and_safety"),
                                    ("Doktor", "medical_services"),
                                    ("Spor", "fitness_center")]),
    ("Eğitim", "school", [("Okul & Kurs", "school"), ("Kitap", "menu_book")]),
    ("Eğlence", "movie", [("Sinema & Konser", "movie"), ("Abonelikler", "tv"),
                          ("Oyun", "sports_esports")]),
    ("Kişisel", "face", [("Kuaför", "content_cut"), ("Kozmetik", "face")]),
    ("Yatırım", "trending_up", []),
    ("Diğer", "category", []),
]

INCOME_PACK = [
    ("Maaş", "payments", []),
    ("Ek Gelir", "savings", [("Prim & İkramiye", "savings"),
                             ("Serbest Çalışma", "work")]),
    ("Kira Geliri", "apartment", []),
    ("Yatırım", "trending_up", []),
    ("Diğer Gelir", "category", []),
]

# Kategori -> (başlık havuzu, tutar aralığı, ayda kaç kez)
# Tutarlar 2026 Türkiye'si için makul tutuldu; ekran görüntüsünde "bu rakamlar
# olmaz" dedirtmemeli.
PLAN = {
    # Başlıklar BİLEREK jenerik: gerçek marka adı (Migros, Starbucks, Netflix…)
    # mağaza görselinde uygulamanın o kurumla resmî bir ilişkisi varmış
    # izlenimi verir ve Play incelemesinde fikri mülkiyet itirazına açık alan
    # bırakır. Kategori zaten `tag` ile atandığı için CategoryGuesser'ın marka
    # sözlüğüne burada ihtiyaç yok.
    "Manav":           (["Manav", "Semt Pazarı", "Sebze Meyve"], (180, 520), 4),
    "Kasap":           (["Kasap", "Et Reyonu"], (450, 1250), 2),
    "Su & İçecek":     (["Damacana Su", "Bakkal"], (90, 260), 3),
    "Market":          (["Market Alışverişi", "Haftalık Market", "Süpermarket",
                         "Zincir Market"], (420, 2400), 6),
    "Restoran":        (["Kebapçı", "Balıkçı", "Köfteci", "Pide Salonu"],
                        (380, 1450), 4),
    "Kafe":            (["Kahveci", "Kafe", "Fırın & Pastane"], (120, 380), 6),
    "Paket Servis":    (["Paket Servis", "Eve Sipariş"], (240, 720), 4),
    "Yakıt":           (["Akaryakıt İstasyonu", "Benzin"], (1400, 2600), 3),
    "Toplu Taşıma":    (["Ulaşım Kartı Yükleme", "Metro Bileti"], (150, 400), 3),
    "Taksi":           (["Taksi", "Şehir İçi Taksi"], (180, 520), 2),
    "Otopark":         (["Katlı Otopark", "Otopark Ücreti"], (60, 180), 3),
    "Elektrik":        (["Elektrik Faturası"], (880, 1480), 1),
    "Su":              (["Su Faturası"], (210, 390), 1),
    "Doğalgaz":        (["Doğalgaz Faturası"], (340, 1650), 1),
    "İnternet":        (["İnternet Faturası"], (649, 649), 1),
    "Telefon":         (["Telefon Faturası"], (429, 489), 1),
    "Kira":            (["Ev Kirası"], (18500, 18500), 1),
    "Aidat":           (["Apartman Aidatı"], (1750, 1750), 1),
    "Bakım & Onarım":  (["Tesisatçı", "Boya Badana"], (600, 2400), 0.4),
    "Giyim":           (["Giyim Mağazası", "Ayakkabı", "Kışlık Mont"],
                        (450, 2200), 1.5),
    "Elektronik":      (["Elektronik Mağazası", "Kulaklık"], (1200, 6500), 0.4),
    "Ev Eşyası":       (["Mobilya", "Hırdavat", "Ev Tekstili"], (350, 2400), 0.8),
    "İlaç":            (["Eczane", "Nöbetçi Eczane"], (180, 620), 1.5),
    "Doktor":          (["Özel Muayene", "Diş Hekimi"], (900, 2600), 0.4),
    "Spor":            (["Spor Salonu Üyeliği"], (1100, 1100), 1),
    "Okul & Kurs":     (["İngilizce Kursu"], (2400, 2400), 0.5),
    "Kitap":           (["Kitapçı", "Kırtasiye"], (180, 640), 0.8),
    "Sinema & Konser": (["Sinema Bileti", "Konser Bileti"], (280, 1400), 1),
    "Abonelikler":     (["Dijital Abonelik", "Müzik Aboneliği",
                         "Video Aboneliği"], (99, 299), 3),
    "Oyun":            (["Oyun Satın Alma", "Oyun İçi Kredi"], (240, 900), 0.6),
    "Kuaför":          (["Kuaför", "Berber"], (250, 700), 1.2),
    "Kozmetik":        (["Kozmetik", "Kişisel Bakım"], (200, 780), 1),
    "Diğer":           (["Hediye", "Bağış", "Kargo"], (120, 900), 1.5),
}


def uid() -> str:
    return str(uuid.uuid4())


def iso(d: date, hour: int = 0, minute: int = 0) -> str:
    return datetime(d.year, d.month, d.day, hour, minute).isoformat()


def money(lo: float, hi: float) -> float:
    """Gerçek fiş gibi görünen tutar: tam sayı değil, kuruşlu."""
    if lo == hi:
        return float(lo)
    v = RNG.uniform(lo, hi)
    return round(v, 2) if RNG.random() < 0.75 else float(round(v / 10) * 10)


def month_starts(count: int) -> list[date]:
    """Bugünün ayı dahil, geriye doğru `count` ayın ilk günü (eskiden yeniye)."""
    out = []
    y, m = TODAY.year, TODAY.month
    for _ in range(count):
        out.append(date(y, m, 1))
        m -= 1
        if m == 0:
            y, m = y - 1, 12
    return list(reversed(out))


def day_in(month_start: date, max_day: int | None = None) -> date:
    """Ay içinde rastgele gün; içinde bulunulan ayda bugünü geçmez."""
    if month_start.month == TODAY.month and month_start.year == TODAY.year:
        last = TODAY.day
    else:
        nxt = date(month_start.year + (month_start.month // 12),
                   month_start.month % 12 + 1, 1)
        last = (nxt - timedelta(days=1)).day
    if max_day:
        last = min(last, max_day)
    return date(month_start.year, month_start.month, RNG.randint(1, max(1, last)))


# --------------------------------------------------------------------------
# Kategoriler
# --------------------------------------------------------------------------
def build_categories():
    cats, index = [], {}
    for is_expense, pack in ((True, EXPENSE_PACK), (False, INCOME_PACK)):
        for order, (name, icon, children) in enumerate(pack, start=1):
            pid = uid()
            cats.append({"id": pid, "name": name, "iconName": icon,
                         "isExpense": is_expense, "parentId": None,
                         "sortOrder": order})
            index[(is_expense, name)] = pid
            for corder, (cname, cicon) in enumerate(children, start=1):
                cid = uid()
                cats.append({"id": cid, "name": cname, "iconName": cicon,
                             "isExpense": is_expense, "parentId": pid,
                             "sortOrder": corder})
                index[(is_expense, cname)] = cid
    return cats, index


# --------------------------------------------------------------------------
# Ana üretim
# --------------------------------------------------------------------------
def build():
    cats, cat = build_categories()
    months = month_starts(4)

    w_main, w_cash, w_usd = uid(), uid(), uid()
    created = iso(months[0] - timedelta(days=10), 9, 30)

    txs: list[dict] = []

    def add(wallet, title, tag, amount, d, income=False, system=False,
            reference=None, hour=None):
        h = hour if hour is not None else RNG.randint(8, 21)
        # Bugünün kaydı saat olarak GELECEĞE düşmesin: "az önce girilmiş"
        # görünmeli, birkaç saat sonrasına tarihlenmiş değil.
        if d == TODAY:
            h = min(h, max(0, datetime.now().hour - 1))
        txs.append({
            "id": uid(), "userId": USER, "walletId": wallet,
            "title": title, "tag": tag, "amount": round(float(amount), 2),
            "date": iso(d, h,
                        RNG.choice([0, 5, 12, 17, 23, 30, 38, 41, 49, 55])),
            "type": "income" if income else "expense",
            "isSystem": system, "receiptFileName": None, "reference": reference,
        })

    # --- Gelir: maaş + ara sıra prim/serbest iş ---------------------------
    salary = 78500.0
    for i, ms in enumerate(months):
        pay_day = min(5, TODAY.day) if (ms.month == TODAY.month and
                                        ms.year == TODAY.year) else 5
        add(w_main, "Maaş Ödemesi", cat[(False, "Maaş")], salary + i * 1500,
            date(ms.year, ms.month, max(1, pay_day)), income=True, hour=9,
            reference=f"MAAS{ms.year}{ms.month:02d}")
    add(w_main, "Yıllık Prim", cat[(False, "Prim & İkramiye")], 14500,
        day_in(months[1]), income=True)
    add(w_main, "Web Sitesi Projesi", cat[(False, "Serbest Çalışma")], 8750,
        day_in(months[2]), income=True)
    add(w_main, "Dükkan Kirası", cat[(False, "Kira Geliri")], 9500,
        day_in(months[-2], 12), income=True)
    # İçinde bulunulan ay: rapor ekranı varsayılan olarak bu aya bakıyor ve
    # tek gelir kalemi varsa kategori dağılımı "%100 Maaş" tek dilimine
    # düşüyordu — grafik hiçbir şey anlatmıyor.
    if TODAY.day >= 8:
        add(w_main, "Dükkan Kirası", cat[(False, "Kira Geliri")], 9500,
            date(TODAY.year, TODAY.month, min(8, TODAY.day)), income=True)
    if TODAY.day >= 14:
        add(w_main, "Logo Tasarımı", cat[(False, "Serbest Çalışma")], 6200,
            date(TODAY.year, TODAY.month, min(14, TODAY.day)), income=True)

    # --- Gider: plana göre --------------------------------------------------
    for ms in months:
        for name, (titles, (lo, hi), per_month) in PLAN.items():
            n = int(per_month) + (1 if RNG.random() < (per_month % 1) else 0)
            # İçinde bulunulan ay henüz bitmedi: harcamayı gün oranıyla kırp,
            # yoksa "ayın 21'inde tam ay harcaması" tutarsız görünür.
            if ms.month == TODAY.month and ms.year == TODAY.year:
                n = max(0, round(n * TODAY.day / 30))
            for _ in range(n):
                wallet = w_cash if (name in ("Manav", "Kafe", "Taksi",
                                             "Otopark", "Su & İçecek")
                                    and RNG.random() < 0.6) else w_main
                add(wallet, RNG.choice(titles), cat[(True, name)],
                    money(lo, hi), day_in(ms))

    # --- Nakit çekme (ana hesaptan nakde geçiş hissi) ----------------------
    for ms in months:
        add(w_main, "ATM Nakit Çekme", cat[(True, "Diğer")], 3000,
            day_in(ms, 10))
        add(w_cash, "ATM Nakit Çekme", cat[(False, "Diğer Gelir")], 3000,
            day_in(ms, 10), income=True)

    # --- USD cüzdanı (çoklu para birimi vitrini) --------------------------
    add(w_usd, "Freelance Ödemesi", cat[(False, "Serbest Çalışma")], 1200,
        day_in(months[1]), income=True)
    add(w_usd, "Freelance Ödemesi", cat[(False, "Serbest Çalışma")], 850,
        day_in(months[3]), income=True)
    add(w_usd, "Adobe Aboneliği", cat[(True, "Abonelikler")], 29.99,
        day_in(months[2]))
    add(w_usd, "AWS", cat[(True, "Diğer")], 42.30, day_in(months[3]))

    # --- Borçlar -----------------------------------------------------------
    loan_start = months[0] - timedelta(days=20)
    loan_principal = 60000.0
    loan_installment = 6120.0
    loan_term = 12
    loan_total = round(loan_installment * loan_term, 2)   # fixedInstallment
    loan_payments = []
    for i, ms in enumerate(months[:-1]):          # bu ayın taksiti henüz yok
        pd = date(ms.year, ms.month, min(15, TODAY.day if
                  (ms.month == TODAY.month and ms.year == TODAY.year) else 15))
        loan_payments.append({"id": uid(), "date": iso(pd, 10),
                              "amount": loan_installment,
                              "overdueInterestPart": 0.0, "notes": None})
        add(w_main, "Kredi Taksiti — Örnek Banka", TAG_DEBT_PAYMENT,
            loan_installment, pd, system=True, hour=10)

    personal_principal = 7500.0
    personal_paid = 2500.0
    pd = day_in(months[2])
    personal_payments = [{"id": uid(), "date": iso(pd, 14),
                          "amount": personal_paid,
                          "overdueInterestPart": 0.0, "notes": "Elden ödendi"}]
    add(w_main, "Borç Ödemesi — Ayşe Kaya", TAG_DEBT_PAYMENT,
        personal_paid, pd, system=True)

    debts = [
        {"id": uid(), "userId": USER, "walletId": w_main,
         "title": "İhtiyaç Kredisi", "counterparty": "Örnek Banka",
         "type": "bankLoan", "calcMode": "fixedInstallment",
         "principalAmount": loan_principal, "interestRate": 0.0,
         "termMonths": loan_term, "overdueInterestRate": 0.0,
         "startDate": iso(loan_start, 11), "dueDate": iso(
             date(loan_start.year + (1 if loan_start.month > 12 - loan_term else 0),
                  (loan_start.month + loan_term - 1) % 12 + 1,
                  min(loan_start.day, 28)), 11),
         "payments": loan_payments, "isPaid": False,
         "notes": "Aylık 6.120 ₺ sabit taksit",
         "expectedTotalAmount": loan_total, "principalToWallet": False},
        {"id": uid(), "userId": USER, "walletId": w_main,
         "title": "Arkadaş Borcu", "counterparty": "Ayşe Kaya",
         "type": "personalDebt", "calcMode": "none",
         "principalAmount": personal_principal, "interestRate": 0.0,
         "termMonths": 0, "overdueInterestRate": 0.0,
         "startDate": iso(months[1] + timedelta(days=3), 12),
         "dueDate": iso(TODAY + timedelta(days=25), 12),
         "payments": personal_payments, "isPaid": False, "notes": None,
         "expectedTotalAmount": personal_principal,
         "principalToWallet": False},
    ]

    # --- Alacaklar ---------------------------------------------------------
    coll_d = day_in(months[2])
    add(w_main, "Alacak Tahsilatı — Mehmet Demir", TAG_RECEIVABLE_COLLECTION,
        4000, coll_d, income=True, system=True)
    receivables = [
        {"id": uid(), "userId": USER, "walletId": w_main,
         "debtorName": "Elif Kaya", "amount": 6500.0,
         "dueDate": iso(TODAY + timedelta(days=18), 12),
         "createdAt": iso(months[2] + timedelta(days=6), 15),
         "collectedAt": None, "isPaid": False,
         "notes": "Ev eşyası için verilen borç"},
        {"id": uid(), "userId": USER, "walletId": w_main,
         "debtorName": "Mehmet Demir", "amount": 4000.0,
         "dueDate": iso(coll_d, 12),
         "createdAt": iso(months[1] + timedelta(days=4), 15),
         "collectedAt": iso(coll_d, 16), "isPaid": True, "notes": None},
    ]

    # --- Birikim hedefleri + yatırımlar ------------------------------------
    # Hedefler kasıtlı olarak ÜÇ FARKLI doluluk seviyesinde: erken / orta /
    # neredeyse tamam. Üçü de %60 civarı olsaydı ekran görüntüsü tek bir
    # durumu anlatırdı.
    g_ev, g_araba, g_acil = uid(), uid(), uid()
    goals = [
        {"id": g_ev, "userId": USER, "walletId": w_main, "name": "Ev Peşinatı",
         "targetAmount": 150000.0, "category": "ev", "color": 0xFF009688,
         "createdAt": iso(months[0] - timedelta(days=5), 10)},
        {"id": g_araba, "userId": USER, "walletId": w_main, "name": "Yeni Araba",
         "targetAmount": 60000.0, "category": "araba", "color": 0xFF3F51B5,
         "createdAt": iso(months[1] + timedelta(days=2), 10)},
        {"id": g_acil, "userId": USER, "walletId": w_main, "name": "Acil Fon",
         "targetAmount": 12000.0, "category": "acil_fon", "color": 0xFF4CAF50,
         "createdAt": iso(months[2] + timedelta(days=1), 10)},
    ]

    # Deftere işlenen alımlar. "Zaten bende" olan kısım (unbookedCost)
    # cüzdandan HİÇ çıkmadı, dolayısıyla karşılık gelen işlem de yok —
    # portföy inandırıcı büyüklükte kalırken bakiye şişmiyor.
    gold_d, quarter_d = day_in(months[0]), day_in(months[0], 12)
    stock_d, fund_d = day_in(months[1]), day_in(months[2])
    silver_d = day_in(months[3], 20)
    add(w_main, "Gram Altın Alımı", TAG_INVESTMENT_BUY, 24600, gold_d, system=True)
    add(w_main, "Örnek Havacılık Alımı", TAG_INVESTMENT_BUY, 15400, stock_d,
        system=True)
    add(w_main, "Serbest Fon Alımı", TAG_INVESTMENT_BUY, 10000, fund_d, system=True)
    add(w_main, "Vadeli Mevduat", TAG_INVESTMENT_BUY, 3500, silver_d, system=True)

    investments = [
        # İKİ altın kaydı da varsayılan amber ile geliyor (ekleme sayfasının
        # varsayılanı). Halka grafiği artık çakışan rengi kendi ton ailesinde
        # kaydırıyor — bu veri o düzeltmeyi ekranda gösteriyor.
        {"id": uid(), "userId": USER, "walletId": w_main, "name": "Gram Altın",
         "amount": 49200.0, "currentValue": 54681.00,
         "type": "InvestmentType.gold", "color": 0xFFFFC107,
         "dateAdded": iso(gold_d, 11), "symbol": "gram-altin",
         "returnRate": 0.0, "quantity": 12.0, "goalId": g_ev,
         "currency": "TRY", "unbookedCost": 24600.0},
        {"id": uid(), "userId": USER, "walletId": w_main, "name": "Çeyrek Altın",
         "amount": 46000.0, "currentValue": 48900.00,
         "type": "InvestmentType.gold", "color": 0xFFFFC107,
         "dateAdded": iso(quarter_d, 11), "symbol": "ceyrek-altin",
         "returnRate": 0.0, "quantity": 10.0, "goalId": g_ev,
         "currency": "TRY", "unbookedCost": 46000.0},
        {"id": uid(), "userId": USER, "walletId": w_main,
         "name": "Örnek Havacılık", "amount": 15400.0, "currentValue": 16985.0,
         "type": "InvestmentType.stock", "color": 0xFF2196F3,
         "dateAdded": iso(stock_d, 11), "symbol": "ORNK",
         "returnRate": 0.0, "quantity": 55.0, "goalId": g_araba,
         "currency": "TRY", "unbookedCost": 0.0},
        {"id": uid(), "userId": USER, "walletId": w_main, "name": "Serbest Fon",
         "amount": 10000.0, "currentValue": 10420.0,
         "type": "InvestmentType.custom", "color": 0xFF4CAF50,
         "dateAdded": iso(fund_d, 11), "symbol": None,
         "returnRate": 4.2, "quantity": None, "goalId": g_acil,
         "currency": "TRY", "unbookedCost": 0.0},
        # Hedefe bağlı DEĞİL: "Bağsız varlıklar" bölümü de dolu görünsün.
        #
        # Tür `custom`: gümüş bu uygulamada bir ALTIN TÜRÜ değil
        # (`kGoldTypeKeys`). `gold` + `symbol: "gumus"` denendiğinde
        # `goldTypeLabel` tanımadığı anahtarı olduğu gibi döndürüyor ve kart
        # "gumus" rozetiyle, "100 gumus · Birim…" satırıyla, tür olarak da
        # "Altın" yazıyordu. Sembolsüz `custom` doğru kayıt: rozet ve miktar
        # satırı hiç kurulmaz.
        {"id": uid(), "userId": USER, "walletId": w_main,
         "name": "Vadeli Mevduat", "amount": 3500.0, "currentValue": 3780.0,
         "type": "InvestmentType.custom", "color": 0xFF00897B,
         "dateAdded": iso(silver_d, 11), "symbol": None,
         "returnRate": 8.0, "quantity": None, "goalId": None,
         "currency": "TRY", "unbookedCost": 0.0},
    ]

    # --- Tekrarlayan şablonlar --------------------------------------------
    # İKİSİ BEKLEMEDE (nextExecutionDate geçmişte): `isRecurringDue` kuralı
    # `isActive && nextExecutionDate <= now`. Hepsi geleceğe tarihlenirse
    # "Onay Bekleyenler 0" görünür ve sekme özelliğin ne işe yaradığını
    # anlatmaz. DİKKAT: bekleyen kalem varken uygulama açılışta onay
    # hatırlatmasını gösterir — ekran görüntüsünden önce kapat.
    nxt = date(TODAY.year + (1 if TODAY.month == 12 else 0),
               TODAY.month % 12 + 1, 1)
    recurring = [
        {"id": uid(), "userId": USER, "walletId": w_main, "title": "Ev Kirası",
         "tag": cat[(True, "Kira")], "amount": 18500.0, "type": "expense",
         "frequency": "monthly", "nextExecutionDate": iso(nxt, 9),
         "anchorDay": 1, "isActive": True},
        {"id": uid(), "userId": USER, "walletId": w_main, "title": "Maaş Ödemesi",
         "tag": cat[(False, "Maaş")], "amount": 83000.0, "type": "income",
         "frequency": "monthly",
         "nextExecutionDate": iso(date(nxt.year, nxt.month, 5), 9),
         "anchorDay": 5, "isActive": True},
        {"id": uid(), "userId": USER, "walletId": w_main,
         "title": "Dijital Abonelik", "tag": cat[(True, "Abonelikler")],
         "amount": 229.99, "type": "expense", "frequency": "monthly",
         "nextExecutionDate": iso(TODAY - timedelta(days=2), 9),
         "anchorDay": 12, "isActive": True},
        {"id": uid(), "userId": USER, "walletId": w_main,
         "title": "Spor Salonu", "tag": cat[(True, "Spor")],
         "amount": 1250.0, "type": "expense", "frequency": "monthly",
         "nextExecutionDate": iso(TODAY - timedelta(days=1), 9),
         "anchorDay": 20, "isActive": True},
        # Aşağıdaki üçü "Şablonlar" sekmesi İÇİN var: iki kalemle sekme
        # ekranın %60'ını boş bırakıyor ve mağaza karesinde "kimse
        # kullanmıyor" izlenimi veriyordu. Hiçbiri işlem üretmez, yalnız
        # ileri tarihli şablondur — cüzdan değişmezlerine dokunmaz.
        {"id": uid(), "userId": USER, "walletId": w_main,
         "title": "İnternet Faturası", "tag": cat[(True, "İnternet")],
         "amount": 649.0, "type": "expense", "frequency": "monthly",
         "nextExecutionDate": iso(date(nxt.year, nxt.month, 8), 9),
         "anchorDay": 8, "isActive": True},
        {"id": uid(), "userId": USER, "walletId": w_main,
         "title": "Elektrik Faturası", "tag": cat[(True, "Elektrik")],
         "amount": 1480.0, "type": "expense", "frequency": "monthly",
         "nextExecutionDate": iso(date(nxt.year, nxt.month, 15), 9),
         "anchorDay": 15, "isActive": True},
        {"id": uid(), "userId": USER, "walletId": w_main,
         "title": "Müzik Aboneliği", "tag": cat[(True, "Abonelikler")],
         "amount": 199.99, "type": "expense", "frequency": "monthly",
         "nextExecutionDate": iso(date(nxt.year, nxt.month, 22), 9),
         "anchorDay": 22, "isActive": True},
    ]

    # --- Bütçeler: içinde bulunulan ayın GERÇEK harcamasından türetilir ----
    # Hedef oranlar ekran görüntüsü için seçildi: biri aşılmış, biri sınırda,
    # gerisi rahat. Limit uydurulursa çubuklar rastgele görünür.
    kids = {}
    for c in cats:
        if c["parentId"]:
            kids.setdefault(c["parentId"], []).append(c["id"])

    def subtree(root_id):
        return {root_id, *kids.get(root_id, [])}

    def spent_this_month(wallet, root_id):
        ids = subtree(root_id)
        return round(sum(
            t["amount"] for t in txs
            if t["walletId"] == wallet and t["type"] == "expense"
            and t["tag"] in ids
            and t["date"][:7] == f"{TODAY.year}-{TODAY.month:02d}"), 2)

    targets = {"Yemek": 1.12, "Market": 0.86, "Fatura": 0.71,
               "Ulaşım": 0.58, "Eğlence": 0.44, "Alışveriş": 0.27}
    budgets = []
    for name, ratio in targets.items():
        root = cat[(True, name)]
        spent = spent_this_month(w_main, root)
        limit = max(500.0, round((spent / ratio) / 50) * 50) if spent else 2000.0
        budgets.append({"categoryId": root, "limitAmount": float(limit),
                        "walletId": w_main})

    # --- Cüzdan değişmezleri ------------------------------------------------
    def signed_sum(wallet):
        return round(sum((t["amount"] if t["type"] == "income" else -t["amount"])
                         for t in txs if t["walletId"] == wallet), 2)

    def remaining(d):
        principal_paid = round(sum(p["amount"] - p["overdueInterestPart"]
                                   for p in d["payments"]), 2)
        return round(round(d["expectedTotalAmount"], 2) - principal_paid, 2)

    def metrics(wallet):
        return (
            round(sum(remaining(d) for d in debts
                      if d["walletId"] == wallet and not d["isPaid"]), 2),
            round(sum(r["amount"] for r in receivables
                      if r["walletId"] == wallet and not r["isPaid"]), 2),
            round(sum(i["currentValue"] for i in investments
                      if i["walletId"] == wallet), 2),
        )

    wallets = []
    for wid, name, color, icon, opening, currency, order in (
        (w_main, "Vadesiz Hesap", "0xFF2196F3", "account_balance", 12400.0, "TRY", 1),
        (w_cash, "Nakit", "0xFF4CAF50", "payments", 850.0, "TRY", 2),
        (w_usd, "Döviz Hesabı", "0xFF9C27B0", "currency_exchange", 300.0, "USD", 3),
    ):
        d, c, inv = metrics(wid)
        wallets.append({
            "id": wid, "userId": USER, "name": name,
            "balance": round(opening + signed_sum(wid), 2),
            "debt": d, "credit": c, "investment": inv,
            "colorHex": color, "iconName": icon, "createdAt": created,
            "isActive": True, "sortOrder": order,
            "openingBalance": opening, "currency": currency,
        })

    txs.sort(key=lambda t: t["date"])

    return {
        "version": 9,
        "timestamp": datetime.now().isoformat(),
        "wallets": wallets,
        "transactions": txs,
        "investments": investments,
        "debts": debts,
        "receivables": receivables,
        "budgets": budgets,
        "recurringTransactions": recurring,
        "users": {USER: {"activeWalletId": w_main}},
        "categories": cats,
        "goals": goals,
    }


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "cunehat_demo.json"
    data = build()
    with open(out, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False)
    print(f"{out} yazıldı")
    print(f"  {len(data['categories'])} kategori, {len(data['transactions'])} işlem, "
          f"{len(data['budgets'])} bütçe, {len(data['debts'])} borç, "
          f"{len(data['receivables'])} alacak, {len(data['investments'])} yatırım, "
          f"{len(data['goals'])} hedef")
    inv_by_goal = {}
    for i in data["investments"]:
        inv_by_goal.setdefault(i["goalId"], []).append(i)
    for g in data["goals"]:
        saved = sum(i["currentValue"] for i in inv_by_goal.get(g["id"], []))
        pct = saved / g["targetAmount"] * 100 if g["targetAmount"] else 0
        print(f"  hedef {g['name']:<14} %{pct:5.1f}  "
              f"{saved:>12,.2f} / {g['targetAmount']:,.2f}  "
              f"({len(inv_by_goal.get(g['id'], []))} varlık)")
    loose = len(inv_by_goal.get(None, []))
    print(f"  bağsız varlık: {loose}")
    pending = sum(1 for r in data["recurringTransactions"]
                  if r["isActive"] and r["nextExecutionDate"] <= datetime.now().isoformat())
    print(f"  onay bekleyen şablon: {pending}  (açılışta hatırlatma çıkar)")
    for w in data["wallets"]:
        print(f"  {w['name']:<14} bakiye {w['balance']:>12,.2f} {w['currency']}"
              f"  borç {w['debt']:>10,.2f}  alacak {w['credit']:>8,.2f}"
              f"  yatırım {w['investment']:>10,.2f}")

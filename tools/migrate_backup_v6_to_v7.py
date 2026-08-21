#!/usr/bin/env python3
"""cunehat yedeği v6 -> v7.

v7'nin tek yapısal değişikliği kategori sistemi (bkz. DataSerializationService
sürüm notları):
  - kategoriler ham SharedPreferences string'i değil GERÇEK BİR LİSTE,
  - `id` kullanıcının verdiği ad değil UUID; ad ayrı `name` alanında,
  - `parentId` eklendi (v6'da hiyerarşi yok -> hepsi null),
  - `isDefault` / `displayName` kaldırıldı.

Kimlik ad iken deftere `tag` olarak, bütçeye `categoryId` olarak yazılmıştı;
id UUID'ye dönünce bu atıflar da çevrilmek zorunda, yoksa 137 işlem
kategorisiz kalır.
"""
import json
import sys
import uuid

# v6'da kategorilerin bir kısmı prefs'te değil KODDA yaşıyordu; yedek yalnız
# özel kategorileri ve varsayılan üzerindeki düzenlemeleri taşıyor. Taban
# liste 8cb6de7^:category_model.dart'tan alındı.
DEFAULT_EXPENSE = [
    ("Market", "shopping_cart", 1),
    ("Yemek", "restaurant", 2),
    ("Ulaşım", "directions_bus", 3),
    ("Fatura", "receipt_long", 4),
    ("Kira", "home", 5),
    ("Alışveriş", "shopping_bag", 6),
    ("Sağlık", "medical_services", 7),
    ("Eğitim", "school", 8),
    ("Eğlence", "movie", 9),
]
DEFAULT_INCOME = [
    ("Maaş", "payments", 1),
    ("Ek Gelir", "savings", 2),
    ("Serbest", "work", 3),
    ("Yatırım", "trending_up", 4),
]

# Sistem hareketlerinin etiketi kategori DEĞİLDİR (CashMovementTags); olduğu
# gibi kalır.
SYSTEM_TAGS = {
    "Borç", "Borç Ödemesi", "Alacak", "Alacak Tahsilatı",
    "Yatırım Alımı", "Yatırım Satışı", "Yatırım Düzeltmesi", "Transfer",
}


def effective_categories(raw, is_expense):
    """v6 okuma algoritmasının aynısı: taban varsayılanlar + override + özel."""
    base = DEFAULT_EXPENSE if is_expense else DEFAULT_INCOME
    key_over = "updated_expense_defaults" if is_expense else "updated_income_defaults"
    key_custom = "expense_categories" if is_expense else "income_categories"

    overrides = {}
    if raw.get(key_over):
        for j in json.loads(raw[key_over]):
            overrides[j["id"]] = j

    out = []
    for cid, icon, order in base:
        o = overrides.get(cid)
        if o:
            out.append({
                "old_id": cid,
                "name": o.get("displayName") or cid,
                "iconName": o["iconName"],
                "sortOrder": o["sortOrder"],
            })
        else:
            out.append({"old_id": cid, "name": cid, "iconName": icon,
                        "sortOrder": order})

    if raw.get(key_custom):
        for j in json.loads(raw[key_custom]):
            out.append({
                "old_id": j["id"],
                "name": j.get("displayName") or j["id"],
                "iconName": j["iconName"],
                "sortOrder": j["sortOrder"],
            })

    out.sort(key=lambda c: c["sortOrder"])
    return out


def main(src, dst):
    with open(src, encoding="utf-8") as f:
        data = json.load(f)

    if data.get("version") != 6:
        sys.exit(f"beklenen sürüm 6, bulunan: {data.get('version')!r}")

    raw = data["categories"]
    if not isinstance(raw, dict):
        sys.exit("v6 kategorileri prefs haritası olmalı")

    categories = []
    # tag/categoryId eşlemesi TÜRE GÖRE ayrı: v6'da gelir ve gider listeleri
    # bağımsızdı, 'Yatırım' hem gider (özel) hem gelir (varsayılan) olarak var.
    id_map = {True: {}, False: {}}

    for is_expense in (True, False):
        for order, c in enumerate(effective_categories(raw, is_expense), start=1):
            new_id = str(uuid.uuid4())
            id_map[is_expense][c["old_id"]] = new_id
            categories.append({
                "id": new_id,
                "name": c["name"],
                "iconName": c["iconName"],
                "isExpense": is_expense,
                "parentId": None,   # v6'da hiyerarşi yoktu
                "sortOrder": order,
            })

    unmapped = []

    for t in data["transactions"]:
        tag = t["tag"]
        if tag in SYSTEM_TAGS:
            continue
        is_expense = t["type"] == "expense"
        new = id_map[is_expense].get(tag)
        if new is None:
            unmapped.append(("transaction", t["id"], tag, t["type"]))
            continue
        t["tag"] = new

    for b in data["budgets"]:
        # Bütçe yalnız gider kategorilerine kurulur.
        new = id_map[True].get(b["categoryId"])
        if new is None:
            unmapped.append(("budget", b["walletId"], b["categoryId"], "expense"))
            continue
        b["categoryId"] = new

    for r in data.get("recurringTransactions", []):
        is_expense = r["type"] == "expense"
        new = id_map[is_expense].get(r["tag"])
        if new is None:
            unmapped.append(("recurring", r.get("id"), r["tag"], r["type"]))
            continue
        r["tag"] = new

    if unmapped:
        print("EŞLEŞMEYEN ATIFLAR:", file=sys.stderr)
        for row in unmapped:
            print("  ", row, file=sys.stderr)
        sys.exit("eşleşmeyen kategori atfı var — dosya yazılmadı")

    data["categories"] = categories
    data["version"] = 7

    with open(dst, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False)

    print(f"{len(categories)} kategori, {len(data['transactions'])} işlem, "
          f"{len(data['budgets'])} bütçe -> v7")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])

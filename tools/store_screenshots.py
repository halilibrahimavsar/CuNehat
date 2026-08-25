#!/usr/bin/env python3
"""Play Store ekran görüntüsü kompozisyonu.

Ham cihaz çekimini (9:20 — Play'in kabul etmediği bir oran) 1080x1920 tam 9:16
bir tuvale, marka zemini ve başlık şeridiyle yerleştirir.

Neden betik: şerit metni ya da renk değişince görsellerin hepsi tek komutla
yeniden üretilir. Elle tasarımda her değişiklik N kez tekrar iş demek.

KARE BAŞINA BİR EKRAN DEĞİL, BİR KATEGORİ. Play telefon için en fazla 8 görsel
alıyor; eski set 8 karede 8 ekran gösteriyordu, yani 23 yetenek alanının
6'sı. Şimdi her kare bir TEMA ve başlığın altında o temanın özelliklerini
adıyla sayan bir çip satırı var: ekran sayısı düşerken anlatılan özellik
sayısı artıyor. Çipler karenin TEMSİL ETTİĞİ kategorinin özelliklerini
adlandırır, illa o karede piksel olarak görüneni değil — ama uygulamada
GERÇEKTEN bulunmalı ve o kategoriye ait olmalı. Olmayan bir özelliği çipe
yazmak Play politikasında yanıltıcı beyandır; "Reklam yok" gibi iddialar da
Data safety formundaki beyanla birebir uyuşmalı.

Sıra "en güzel ekran" değil "en ikna edici iddia" mantığıyla: ilk 3 görsel
arama sonucunda kaydırmadan görülen tek şey.

Kullanım:
    python3 tools/store_screenshots.py            # tamamı
    python3 tools/store_screenshots.py 3 5        # yalnız 3 ve 5
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

# --- Play kısıtı ------------------------------------------------------------
# Uzun kenar kısa kenarın en fazla 2 katı olabilir. 1080x1920 tam 9:16.
CANVAS = (1080, 1920)

# --- Marka ------------------------------------------------------------------
# Renkler tahmin değil: header gradyanı 1_2_Islemler.jpg'den örneklendi, alt
# renk pubspec.yaml'daki splash rengi (#061B49) — ikon, açılış ekranı ve mağaza
# görseli aynı kimliği taşısın diye.
BG_TOP = (16, 62, 133)
BG_BOTTOM = (5, 22, 60)
ACCENT = (76, 173, 255)
TEXT = (255, 255, 255)
SUBTEXT = (163, 194, 232)

FONT_VAR = "/home/garuda/.local/share/fonts/InterVariable.ttf"
FONT_FALLBACK = "/usr/share/fonts/noto/NotoSans-Bold.ttf"

# --- Yerleşim ---------------------------------------------------------------
MARGIN_X = 76
CAPTION_TOP = 108
CAPTION_SIZE = 78
CAPTION_LEAD = 92
SUB_SIZE = 37
SUB_GAP = 30
SHOT_GAP = 58
CHIP_SIZE = 31        # çip yazısı; 30'un altında Play küçük resimde okunmuyor
CHIP_PAD_X = 22
CHIP_PAD_Y = 13
CHIP_GAP = 12
CHIP_TOP_GAP = 26
SHOT_W = 900          # her karede sabit: set tutarlı görünsün
SHOT_RADIUS = 44
# Durum çubuğu ÖLÇÜLDÜ: saat/pil satırı kaynakta y≈16–40 arasında bitiyor.
# Eski değer (108) fazla cömertti ve ekranın kendi içeriğini yiyordu:
#   * başlıktaki cüzdan rozeti (y≈67–120) ikiye bölünüyor, geriye render
#     hatası gibi duran boş bir yay kalıyordu;
#   * "Banka Ekstresi İçe Aktar"da İ'nin noktası (y≈100–107) kesiliyor,
#     başlık cihazda "Içe" olarak okunuyordu.
# 52 hem saati/pili atar hem 8px pay bırakır. DEĞİŞTİRMEDEN ÖNCE ÖLÇ.
STATUS_BAR = 52

SRC_DIR = Path.home() / "Masaüstü" / "cunehat emulator shots"
OUT_DIR = Path(__file__).resolve().parent.parent / "docs" / "store" / "screenshots"


@dataclass
class Shot:
    index: int
    source: str
    caption: str              # *yıldız* içindeki kelime vurgu rengiyle çizilir
    subtitle: str = ""
    # Çıktı dosyasının adı; Play'e yüklerken sıra buradan okunur.
    slug: str = ""
    # Bu karede GÖRÜNEN özelliklerin adları. Karenin taşıdığı yükün yarısı
    # bunlar; ekranın kendisi tek bir anı gösterir, çipler kapsamı söyler.
    chips: tuple[str, ...] = ()
    crop: tuple[int, int] = (STATUS_BAR, 2290)   # kaynakta korunacak satır aralığı
    anchor: float = 0.0       # taşma nereden kırpılsın: 0=üstü koru, 1=altı koru
    notes: str = field(default="", repr=False)


# Kaynak: 1080x2400 emülatör çekimleri (aynı en-boy oranı, durum çubuğu
# zaten kırpıldığı için cihaz farkı görsele yansımıyor). Hepsi TEK oturumda
# ve TEK veri kümesiyle alındı — set içi tutarlılık için önemli.

# SEKİZ kare, 24 adlandırılmış özellik — Play'in telefon için verdiği yuvanın
# tamamı. Eski set 8 karede 8 EKRAN gösteriyordu; bu set 8 karede 8 KATEGORİ
# gösterip her birinin altında üç özelliği adıyla sayıyor.
#
# Sıra: tanınma → farklılaşma → derinlik → güven.
#   1 defter    arama sonucunda "bu benim para uygulamam" dedirten kare
#   2 ekstre    rakiplerde olmayan tek şey, dönüşümü o alıyor
#   3-4 hedef+portföy   birikim tarafı, duygusal kanca
#   5-6 bütçe+borç      disiplin tarafı
#   7 düzenli   otomasyon
#   8 gizlilik  kapanış güvencesi
SHOTS = [
    Shot(1, "01_liste.png",
         "Gelir ve giderin\n*tek defterde*",
         "Aylık net durum, günlük döküm ve tek dokunuşla kayıt.",
         slug="islem-defteri",
         chips=("Takvim görünümü", "Arama ve filtre", "Çoklu cüzdan")),

    Shot(2, "02_ekstre.png",
         "Ekstreni at,\n*satırlar hazır* gelsin",
         "Okunan tutarlar ekstrenin kendi bakiyesiyle doğrulanır.",
         slug="banka-ekstresi",
         chips=("PDF ve Excel", "Fotoğraftan OCR", "Aritmetik doğrulama")),

    Shot(3, "03_hedefler.png",
         "Hedefini kur,\n*varlıklarını* bağla",
         "Altın ve hisseni hedefe bağla, ilerlemeyi tek bakışta gör.",
         slug="birikim-hedefleri",
         chips=("Altın, hisse ve fon", "Canlı fiyat", "Kâr/zarar takibi")),

    Shot(4, "07_portfoy.png",
         "Portföyün *ne kadar*\nkazandırdı?",
         "Toplam değer, maliyet ve kâr/zarar; dağılımı halkada gör.",
         slug="portfoy",
         chips=("Maliyet muhasebesi", "Kısmi satış", "Çoklu para birimi")),

    Shot(5, "04_butce.png",
         # ESKİ ŞERİT: "Limitini aşmadan *önce* uyarır". Kare bunu YALANLIYOR:
         # özet kartında "1 bütçe aşıldı" rozeti ve kırmızı çubuk duruyor.
         # Uygulamada kartın "limite yaklaşıyor" görsel durumu YOK (yalnız
         # tam %100'de turuncu); %80 uyarısı bildirim olarak çıkıyor — o
         # yüzden söz alt satıra, karenin kanıtlayabildiği iddia şeride.
         "Bütçeni *aşınca*\nhemen gör",
         "Her kategoriye aylık limit; %80'ini geçince bildirim gelir.",
         slug="butce",
         chips=("Kategori limitleri", "Aşım uyarısı", "Gelir–gider raporu")),

    Shot(6, "05_borc.png",
         "Borcunu ve alacağını\n*unutma*",
         "Taksit, vade ve kalan tutar; ödedikçe ilerlemeyi gör.",
         slug="borc-takibi",
         # Çipler karenin KENDİ kategorisinden olmalı: "Düzenli işlemler"
         # buradaydı, borç ekranıyla ilgisi yoktu ve 7. karenin konusunu
         # çalıyordu.
         chips=("Taksit ve vade", "Kısmi ödeme", "Gecikme faizi")),

    Shot(7, "08_duzenli.png",
         "Kira, maaş, abonelik —\n*kendiliğinden* gelsin",
         "Bir kez tanımla; zamanı gelince onayınla deftere işlensin.",
         slug="duzenli-islemler",
         chips=("Aylık şablonlar", "Onay bekleyenler", "Bildirim hatırlatması")),

    Shot(8, "06_yedek.png",
         "Verilerin\n*sende* kalır",
         "Sunucumuz yok. Yedek senin Google Drive hesabına gider.",
         slug="gizlilik",
         chips=("Google Drive yedeği", "CSV dışa aktarım", "Reklam yok")),
]



def load_font(size: int, weight: str = "Bold") -> ImageFont.FreeTypeFont:
    try:
        font = ImageFont.truetype(FONT_VAR, size)
        font.set_variation_by_name(weight)
        return font
    except Exception:
        return ImageFont.truetype(FONT_FALLBACK, size)


def background() -> Image.Image:
    """Dikey gradyan + sol üstte yumuşak vurgu.

    Gradyan kimliğin yarısı (bkz. pubspec flutter_launcher_icons notu); düz renge
    düşürülürse görsel cansızlaşıyor.
    """
    w, h = CANVAS
    strip = Image.new("RGB", (1, h))
    px = strip.load()
    for y in range(h):
        t = (y / (h - 1)) ** 0.85
        px[0, y] = tuple(
            round(BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * t) for i in range(3)
        )
    img = strip.resize((w, h), Image.BILINEAR)

    glow = Image.new("L", (w, h), 0)
    ImageDraw.Draw(glow).ellipse((-520, -760, 860, 620), fill=105)
    glow = glow.filter(ImageFilter.GaussianBlur(240))
    img.paste(Image.new("RGB", (w, h), ACCENT), (0, 0), glow)
    return img


def draw_caption(canvas: Image.Image, shot: Shot) -> int:
    """Şeridi çizer; ekran görüntüsünün başlayacağı y'yi döner."""
    draw = ImageDraw.Draw(canvas)
    font = load_font(CAPTION_SIZE)
    y = CAPTION_TOP

    for line in shot.caption.split("\n"):
        x = MARGIN_X
        # *yıldızlı* parça vurgu renginde: göz başlıkta anahtar kelimeye takılsın.
        for part in re.split(r"(\*[^*]+\*)", line):
            if not part:
                continue
            hit = part.startswith("*") and part.endswith("*")
            word = part[1:-1] if hit else part
            draw.text((x, y), word, font=font, fill=ACCENT if hit else TEXT)
            x += draw.textlength(word, font=font)
        y += CAPTION_LEAD

    y += 14
    draw.rounded_rectangle((MARGIN_X, y, MARGIN_X + 104, y + 8), radius=4, fill=ACCENT)
    y += 8

    if shot.subtitle:
        y += SUB_GAP
        sub = load_font(SUB_SIZE, "Medium")
        for line in wrap(shot.subtitle, sub, CANVAS[0] - 2 * MARGIN_X, draw):
            draw.text((MARGIN_X, y), line, font=sub, fill=SUBTEXT)
            y += SUB_SIZE + 12

    if shot.chips:
        y = draw_chips(canvas, draw, shot.chips, y + CHIP_TOP_GAP)

    return y + SHOT_GAP


def draw_chips(canvas, draw, chips: tuple[str, ...], y: int) -> int:
    """Özellik adlarını kapsül rozetler halinde satıra dizer, sığmayanı alt
    satıra taşır. Rozetler yarı saydam: ekran görüntüsünün önüne geçmesinler,
    başlıkla ekran arasında bir köprü olsunlar."""
    font = load_font(CHIP_SIZE, "Medium")
    max_x = CANVAS[0] - MARGIN_X
    x = MARGIN_X
    row_h = CHIP_SIZE + 2 * CHIP_PAD_Y

    for text in chips:
        w = round(draw.textlength(text, font=font)) + 2 * CHIP_PAD_X
        if x + w > max_x and x > MARGIN_X:
            x = MARGIN_X
            y += row_h + CHIP_GAP
        chip = Image.new("RGBA", (w, row_h), (0, 0, 0, 0))
        ImageDraw.Draw(chip).rounded_rectangle(
            (0, 0, w - 1, row_h - 1), radius=row_h // 2,
            fill=(*ACCENT, 38), outline=(*ACCENT, 120), width=2)
        canvas.alpha_composite(chip, (x, y))
        draw.text((x + CHIP_PAD_X, y + CHIP_PAD_Y), text, font=font, fill=TEXT)
        x += w + CHIP_GAP

    return y + row_h


def wrap(text: str, font, max_w: int, draw) -> list[str]:
    lines, cur = [], ""
    for word in text.split():
        trial = f"{cur} {word}".strip()
        if draw.textlength(trial, font=font) <= max_w:
            cur = trial
        else:
            lines.append(cur)
            cur = word
    if cur:
        lines.append(cur)
    return lines


def frame(raw: Image.Image, shot: Shot, box_h: int) -> Image.Image:
    """Kaynağı kadraj penceresine göre kırpar, sabit genişliğe ölçekler.

    Taşan yükseklik `anchor` ile kırpılır: 0 üstü korur (başlık + ilk kartlar),
    1 altı korur (kaydet düğmesi gibi alta oturan içerik).
    """
    top, bottom = shot.crop
    raw = raw.crop((0, top, raw.width, min(bottom, raw.height)))

    h = round(raw.height * SHOT_W / raw.width)
    raw = raw.resize((SHOT_W, h), Image.LANCZOS)

    if h > box_h:
        off = round((h - box_h) * shot.anchor)
        raw = raw.crop((0, off, SHOT_W, off + box_h))
    return raw


def rounded_top(img: Image.Image, radius: int) -> Image.Image:
    """Üst köşeleri yuvarlar; alt kenar tuvalden taştığı için düz kalır."""
    mask = Image.new("L", img.size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, img.width - 1, img.height - 1), radius=radius, fill=255)
    d.rectangle((0, img.height - radius, img.width, img.height), fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def compose(shot: Shot) -> Path:
    src = SRC_DIR / shot.source
    if not src.exists():
        raise FileNotFoundError(src)

    canvas = background().convert("RGBA")
    shot_top = draw_caption(canvas, shot)
    box_h = CANVAS[1] - shot_top          # alt kenara kadar: taşan çerçeve modern durur

    phone = rounded_top(frame(Image.open(src).convert("RGB"), shot, box_h), SHOT_RADIUS)
    x = (CANVAS[0] - SHOT_W) // 2

    shadow = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (x + 16, shot_top + 26, x + SHOT_W - 16, CANVAS[1]),
        radius=SHOT_RADIUS, fill=(0, 0, 0, 165))
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(34)))

    canvas.alpha_composite(phone, (x, shot_top))

    # İnce kenar: koyu zeminde ekranın nerede bittiğini belli eder.
    ImageDraw.Draw(canvas).rounded_rectangle(
        (x, shot_top, x + SHOT_W - 1, CANVAS[1] + SHOT_RADIUS),
        radius=SHOT_RADIUS, outline=(255, 255, 255, 90), width=3)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out = OUT_DIR / f"{shot.index:02d}_{shot.slug}.png"
    canvas.convert("RGB").save(out, "PNG")   # 24-bit, alfa yok — Play şartı
    return out


def main() -> None:
    wanted = {int(a) for a in sys.argv[1:]} or None
    for shot in SHOTS:
        if wanted and shot.index not in wanted:
            continue
        try:
            path = compose(shot)
        except FileNotFoundError as exc:
            print(f"  atlandı  #{shot.index}: kaynak yok — {exc}")
            continue
        w, h = Image.open(path).size
        print(f"  yazıldı  #{shot.index}  {w}x{h}  {path.name}")
        if shot.notes:
            print(f"           ⚠  {shot.notes}")


if __name__ == "__main__":
    main()

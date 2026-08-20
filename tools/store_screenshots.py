#!/usr/bin/env python3
"""Play Store ekran görüntüsü kompozisyonu.

Ham cihaz çekimini (9:20 — Play'in kabul etmediği bir oran) 1080x1920 tam 9:16
bir tuvale, marka zemini ve başlık şeridiyle yerleştirir.

Neden betik: şerit metni ya da renk değişince 8 görselin hepsi tek komutla
yeniden üretilir. Elle tasarımda her değişiklik 8 kez tekrar iş demek.

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
SHOT_W = 900          # her karede sabit: set tutarlı görünsün
SHOT_RADIUS = 44
STATUS_BAR = 78       # kişisel bildirim ikonu + %16 kırmızı pil kırpılıyor

SRC_DIR = Path.home() / "Masaüstü" / "cunehat screenshots"
OUT_DIR = Path(__file__).resolve().parent.parent / "docs" / "store" / "screenshots"


@dataclass
class Shot:
    index: int
    source: str
    caption: str              # *yıldız* içindeki kelime vurgu rengiyle çizilir
    subtitle: str = ""
    crop: tuple[int, int] = (STATUS_BAR, 2712)   # kaynakta korunacak satır aralığı
    anchor: float = 0.0       # taşma nereden kırpılsın: 0=üstü koru, 1=altı koru
    notes: str = field(default="", repr=False)


# Sıra "en güzel ekran" değil "en ikna edici iddia" mantığıyla: ilk 3 görsel
# arama sonucunda kaydırmadan görülen tek şey.
SHOTS = [
    # crop üstü 700: tutar satırı (kaynakta ~719-841) ortadan bölünmesin diye
    # tam üstünden başlıyor. 400'den başlatınca taşma "500 ₺"yi ikiye kesiyordu.
    Shot(1, "Ekstra_1_Islem_Ekleme.jpg",
         "Gider ekle,\n*10 saniyede* bitsin",
         "Kategori, fiş fotoğrafı ve tekrar eden ödeme",
         crop=(700, 2712), anchor=0.0),
    Shot(2, "3_4_Akilli_Icgoru.jpg",
         "Paran nereye\n*gidiyor*, gör",
         "En çok harcanan kategori ve birikim oranın",
         crop=(STATUS_BAR, 2100), anchor=0.0),
    Shot(3, "2_1_Butce_Planlama.jpg",
         "Bütçeni *aşmadan*\nönce uyarır",
         "Kategori bazlı aylık limit ve ilerleme takibi",
         crop=(STATUS_BAR, 2090), anchor=0.0),
    Shot(4, "1_2_Islemler.jpg",
         "Tüm hesapların\n*tek ekranda*",
         "Nakit, banka, kredi kartı — anlık net durum",
         crop=(STATUS_BAR, 2070), anchor=0.0),
    Shot(5, "3_3_Pasta_Grafikleri.jpg",
         "Gelir ve gider,\n*grafiklerle*",
         "Kategori dağılımı, trend ve dönem karşılaştırması",
         crop=(STATUS_BAR, 2420), anchor=0.30,
         notes="Pasta tek dilim (%98 Yatırım Alımı) — 6-8 kategoriyle yeniden çek"),
    Shot(6, "5_1_Varlik_Portfoyu.jpg",
         "Döviz ve altın,\n*güncel kurla*",
         "Portföyünün anlık değeri ve dağılımı",
         crop=(STATUS_BAR, 2420), anchor=0.12,
         notes="Kazanç +0,0% / ₺0 ve tek varlık — birkaç varlık ve kâr/zararla çek"),
    Shot(7, "4_2_Borc_Takibi.jpg",
         "Kime ne borçlusun,\n*unutma*",
         "Borç ve alacak, taksit planı ve vade takibi",
         crop=(STATUS_BAR, 2070), anchor=0.0,
         notes="Tek borç kaydı, ekranın yarısı boş — 3-4 kayıtla yeniden çek"),
    Shot(8, "5_2_Banka_Ekstresi_Ice_Aktar.jpg",
         "Ekstreni oku,\n*tek tek girme*",
         "PDF, Excel ve CSV — işlemler hazır gelir",
         crop=(STATUS_BAR, 2070), anchor=0.0,
         notes="ZORUNLU: bu boş form. Ayrıştırılmış satırların olduğu "
               "INCELEME ekranını çek — en güçlü farkımızın kanıtı bu"),
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

    return y + SHOT_GAP


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
    out = OUT_DIR / f"{shot.index:02d}_{Path(shot.source).stem.lower()}.png"
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

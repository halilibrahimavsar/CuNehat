#!/usr/bin/env python3
"""Play feature graphic'in YAZI bloğunu yeniden çizer (1024x500).

Neden betik: marka adı `CuNehat` iken `ÇuNehat` oldu ve grafik elle çizilmiş
tek bir PNG'ydi — üreteci yoktu, yani her metin değişikliği elde yeniden
tasarım demekti.

Neden "yeniden çizim" ve sıfırdan üretim değil: işaret (halka + yükselen ok)
ve zemin gradyanı elle yapılmış, kaynağı yok. Bu yüzden görselin kendisi
KORUNUR; yalnız yazı bloğu silinip yeniden yazılır. Silme işi zemini
"boyamaz": metin kutusunun solundaki ve sağındaki gerçek zemin sütunları
satır satır enterpole edilir — gradyan iki eksende de yumuşak olduğu için
dikiş görünmez.

Kullanım:
    python3 tools/make_feature_graphic.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

SRC = Path(__file__).resolve().parent.parent / "docs" / "store" / \
    "play-feature-graphic-1024x500.png"

# Ölçüldü (parlak piksel profili): yazı blokları y 189-245 / 284-314 / 328-359,
# sol kenar x=433. Temizlenecek kutu bunları pay bırakarak sarar; işaretin
# parıltısı x≈360'ta bitiyor, sağ kenar zaten boş.
BOX = (416, 172, 912, 376)

LEFT = 433
WORDMARK_BASELINE = 245
SUB_LINE1_TOP = 284
SUB_LINE2_TOP = 328

WORDMARK = "ÇuNehat"
SUB_LINES = ("Kişisel finans — cüzdanlar,", "bütçeler, borçlar, yatırımlar")

TEXT = (255, 255, 255)
SUBTEXT = (198, 219, 245)

FONT_VAR = "/home/garuda/.local/share/fonts/InterVariable.ttf"
FONT_FALLBACK = "/usr/share/fonts/noto/NotoSans-Bold.ttf"


def load_font(size: int, weight: str) -> ImageFont.FreeTypeFont:
    try:
        font = ImageFont.truetype(FONT_VAR, size)
        font.set_variation_by_name(weight)
        return font
    except Exception:
        return ImageFont.truetype(FONT_FALLBACK, size)


def erase_text_block(img: Image.Image) -> None:
    """Yazı kutusunu, kutunun İKİ YANINDAKİ gerçek zeminden enterpole ederek
    doldurur. Düz renkle doldurmak gradyanda bant bırakırdı."""
    x0, y0, x1, y1 = BOX
    px = img.load()
    span = x1 - x0
    for y in range(y0, y1):
        left = px[x0 - 1, y]
        right = px[x1 + 1, y]
        for x in range(x0, x1 + 1):
            t = (x - x0) / span
            px[x, y] = tuple(
                round(left[c] + (right[c] - left[c]) * t) for c in range(3))


def main() -> None:
    img = Image.open(SRC).convert("RGB")
    erase_text_block(img)

    draw = ImageDraw.Draw(img)

    # Kelime işareti: özgün blokla aynı genişliğe (353 px) oturan boy.
    word_font = load_font(82, "Bold")
    # `anchor="ls"` = sol/temel çizgi; özgün temel çizgi ölçüldü.
    draw.text((LEFT, WORDMARK_BASELINE), WORDMARK, font=word_font,
              fill=TEXT, anchor="ls")

    sub_font = load_font(31, "Regular")
    draw.text((LEFT, SUB_LINE1_TOP), SUB_LINES[0], font=sub_font,
              fill=SUBTEXT, anchor="lt")
    draw.text((LEFT, SUB_LINE2_TOP), SUB_LINES[1], font=sub_font,
              fill=SUBTEXT, anchor="lt")

    img.save(SRC, "PNG")
    print(f"  yazıldı  {SRC.name}  {img.size[0]}x{img.size[1]}")


if __name__ == "__main__":
    main()

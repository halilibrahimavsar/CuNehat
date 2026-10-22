import 'package:flutter/widgets.dart';

/// Bir seçici (tarih, saat, kategori) açılmadan ÖNCE metin alanının odağını
/// bırakır.
///
/// Flutter, üstte açılan route kapanınca odağı bir önceki odaklı alana geri
/// verir: formda not alanına dokunup ardından tarih ya da kategori seçen
/// kullanıcıda seçici kapanır kapanmaz klavye kendiliğinden açılıyor, küçük
/// ekranda formun yarısını kapatıyordu. Odak seçiciden önce bırakılırsa geri
/// verilecek bir alan kalmaz.
void releaseInputFocus() => FocusManager.instance.primaryFocus?.unfocus();

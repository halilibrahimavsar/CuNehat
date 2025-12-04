#!/bin/bash

# 🔨 Hive TypeAdapter'ları Yeniden Oluşturma
# Bu komutları projenizin root dizininde çalıştırın

echo "🧹 Eski oluşturulmuş dosyaları temizliyorum..."
flutter clean

echo "📦 Bağımlılıkları yüklüyorum..."
flutter pub get

echo "🔧 TypeAdapter'ları oluşturuyorum..."
flutter pub run build_runner build --delete-conflicting-outputs

echo "✅ Tamamlandı! Artık uygulamanızı çalıştırabilirsiniz."
echo ""
echo "Not: Eğer hala hata alırsanız:"
echo "1. Android Studio'yu kapatın"
echo "2. Projeyi yeniden açın"
echo "3. 'flutter run' ile çalıştırın"
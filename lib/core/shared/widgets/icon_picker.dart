// icon_data.dart - İkon verilerini yöneten model
import 'package:flutter/material.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';

class IconCategory {
  final String name;
  final List<IconItem> icons;

  const IconCategory({
    required this.name,
    required this.icons,
  });
}

class IconItem {
  final String name;
  final IconData iconData;

  const IconItem({
    required this.name,
    required this.iconData,
  });
}

// İkon kategorilerini tanımlayan sınıf
class AppIcons {
  static const List<IconCategory> categories = [
    IconCategory(
      name: 'Finans',
      icons: [
        IconItem(name: 'account_balance', iconData: Icons.account_balance),
        IconItem(
            name: 'account_balance_wallet',
            iconData: Icons.account_balance_wallet),
        IconItem(name: 'credit_card', iconData: Icons.credit_card),
        IconItem(name: 'attach_money', iconData: Icons.attach_money),
        IconItem(name: 'payments', iconData: Icons.payments),
        IconItem(name: 'savings', iconData: Icons.savings),
        IconItem(name: 'request_quote', iconData: Icons.request_quote),
        IconItem(name: 'receipt', iconData: Icons.receipt),
        IconItem(name: 'receipt_long', iconData: Icons.receipt_long),
        IconItem(name: 'currency_exchange', iconData: Icons.currency_exchange),
      ],
    ),
    IconCategory(
      name: 'Grafikler',
      icons: [
        IconItem(name: 'trending_up', iconData: Icons.trending_up),
        IconItem(name: 'trending_down', iconData: Icons.trending_down),
        IconItem(name: 'show_chart', iconData: Icons.show_chart),
      ],
    ),
    IconCategory(
      name: 'İş & Ofis',
      icons: [
        IconItem(name: 'work', iconData: Icons.work),
        IconItem(name: 'business_center', iconData: Icons.business_center),
        IconItem(name: 'work_outline', iconData: Icons.work_outline),
        IconItem(name: 'apartment', iconData: Icons.apartment),
      ],
    ),
    IconCategory(
      name: 'Alışveriş',
      icons: [
        IconItem(name: 'shopping_bag', iconData: Icons.shopping_bag),
        IconItem(name: 'shopping_cart', iconData: Icons.shopping_cart),
        IconItem(name: 'storefront', iconData: Icons.storefront),
        IconItem(name: 'local_mall', iconData: Icons.local_mall),
        IconItem(name: 'checkroom', iconData: Icons.checkroom),
      ],
    ),
    IconCategory(
      name: 'Yemek & İçecek',
      icons: [
        IconItem(name: 'restaurant', iconData: Icons.restaurant),
        IconItem(name: 'local_cafe', iconData: Icons.local_cafe),
        IconItem(name: 'fastfood', iconData: Icons.fastfood),
        IconItem(name: 'ramen_dining', iconData: Icons.ramen_dining),
        IconItem(name: 'icecream', iconData: Icons.icecream),
        IconItem(name: 'bakery_dining', iconData: Icons.bakery_dining),
        IconItem(name: 'lunch_dining', iconData: Icons.lunch_dining),
        IconItem(name: 'dinner_dining', iconData: Icons.dinner_dining),
      ],
    ),
    IconCategory(
      name: 'Ulaşım',
      icons: [
        IconItem(name: 'directions_bus', iconData: Icons.directions_bus),
        IconItem(name: 'directions_car', iconData: Icons.directions_car),
        IconItem(name: 'local_taxi', iconData: Icons.local_taxi),
        IconItem(name: 'directions_subway', iconData: Icons.directions_subway),
        IconItem(name: 'local_gas_station', iconData: Icons.local_gas_station),
        IconItem(name: 'two_wheeler', iconData: Icons.two_wheeler),
        IconItem(name: 'flight', iconData: Icons.flight),
      ],
    ),
    IconCategory(
      name: 'Ev & Yaşam',
      icons: [
        IconItem(name: 'home', iconData: Icons.home),
        IconItem(name: 'villa', iconData: Icons.villa),
        IconItem(name: 'king_bed', iconData: Icons.king_bed),
        IconItem(name: 'chair', iconData: Icons.chair),
        IconItem(name: 'lightbulb', iconData: Icons.lightbulb),
        IconItem(name: 'water_drop', iconData: Icons.water_drop),
      ],
    ),
    IconCategory(
      name: 'Eğlence',
      icons: [
        IconItem(name: 'movie', iconData: Icons.movie),
        IconItem(name: 'music_note', iconData: Icons.music_note),
        IconItem(name: 'sports_esports', iconData: Icons.sports_esports),
        IconItem(name: 'theater_comedy', iconData: Icons.theater_comedy),
        IconItem(name: 'celebration', iconData: Icons.celebration),
        IconItem(name: 'nightlife', iconData: Icons.nightlife),
      ],
    ),
    IconCategory(
      name: 'Sağlık & Spor',
      icons: [
        IconItem(name: 'health_and_safety', iconData: Icons.health_and_safety),
        IconItem(name: 'fitness_center', iconData: Icons.fitness_center),
        IconItem(name: 'medical_services', iconData: Icons.medical_services),
        IconItem(name: 'monitor_heart', iconData: Icons.monitor_heart),
        IconItem(name: 'emergency', iconData: Icons.emergency),
      ],
    ),
    IconCategory(
      name: 'Eğitim',
      icons: [
        IconItem(name: 'school', iconData: Icons.school),
        IconItem(name: 'menu_book', iconData: Icons.menu_book),
        IconItem(name: 'science', iconData: Icons.science),
        IconItem(name: 'language', iconData: Icons.language),
      ],
    ),
    IconCategory(
      name: 'Kişisel Bakım',
      icons: [
        IconItem(name: 'child_care', iconData: Icons.child_care),
        IconItem(name: 'face', iconData: Icons.face),
        IconItem(name: 'content_cut', iconData: Icons.content_cut),
      ],
    ),
    IconCategory(
      name: 'Hayvanlar',
      icons: [
        IconItem(name: 'pets', iconData: Icons.pets),
        IconItem(name: 'cruelty_free', iconData: Icons.cruelty_free),
      ],
    ),
    IconCategory(
      name: 'Seyahat',
      icons: [
        IconItem(name: 'beach_access', iconData: Icons.beach_access),
        IconItem(name: 'luggage', iconData: Icons.luggage),
        IconItem(name: 'hotel', iconData: Icons.hotel),
        IconItem(name: 'hiking', iconData: Icons.hiking),
      ],
    ),
    IconCategory(
      name: 'Teknoloji',
      icons: [
        IconItem(name: 'computer', iconData: Icons.computer),
        IconItem(name: 'phone_android', iconData: Icons.phone_android),
        IconItem(name: 'devices', iconData: Icons.devices),
        IconItem(name: 'headphones', iconData: Icons.headphones),
        IconItem(name: 'tv', iconData: Icons.tv),
        IconItem(name: 'videogame_asset', iconData: Icons.videogame_asset),
      ],
    ),
    IconCategory(
      name: 'İletişim',
      icons: [
        IconItem(name: 'phone', iconData: Icons.phone),
        IconItem(name: 'mail', iconData: Icons.mail),
        IconItem(name: 'message', iconData: Icons.message),
      ],
    ),
    IconCategory(
      name: 'Hediye & Bağış',
      icons: [
        IconItem(name: 'card_giftcard', iconData: Icons.card_giftcard),
        IconItem(name: 'redeem', iconData: Icons.redeem),
        IconItem(
            name: 'volunteer_activism', iconData: Icons.volunteer_activism),
      ],
    ),
    IconCategory(
      name: 'Hizmetler',
      icons: [
        IconItem(name: 'car_repair', iconData: Icons.car_repair),
        IconItem(name: 'plumbing', iconData: Icons.plumbing),
        IconItem(
            name: 'electrical_services', iconData: Icons.electrical_services),
        IconItem(name: 'construction', iconData: Icons.construction),
        IconItem(name: 'cleaning_services', iconData: Icons.cleaning_services),
      ],
    ),
    IconCategory(
      name: 'Diğer',
      icons: [
        IconItem(name: 'category', iconData: Icons.category),
        IconItem(name: 'more_horiz', iconData: Icons.more_horiz),
        IconItem(name: 'label', iconData: Icons.label),
        IconItem(name: 'bookmark', iconData: Icons.bookmark),
        IconItem(name: 'star', iconData: Icons.star),
        IconItem(name: 'favorite', iconData: Icons.favorite),
        IconItem(name: 'thumb_up', iconData: Icons.thumb_up),
      ],
    ),
  ];

  // İkon adından IconData almak için yardımcı metod
  static IconData getIconData(String iconName) {
    for (var category in categories) {
      for (var icon in category.icons) {
        if (icon.name == iconName) {
          return icon.iconData;
        }
      }
    }
    return Icons.account_balance; // Varsayılan ikon
  }

  // Tüm ikonları düz liste olarak almak için
  static List<IconItem> getAllIcons() {
    return categories.expand((category) => category.icons).toList();
  }
}

// modern_icon_picker.dart - Modern, aranabilir ikon seçici
class IconPicker extends StatefulWidget {
  final String selectedIcon;
  final Function(String) onIconSelected;
  final Color iconColor;
  final String title;

  const IconPicker({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
    this.iconColor = Colors.blue,
    this.title = 'İkon Seçin',
  });

  @override
  State<IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<IconPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AppIcons.categories.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<IconItem> _getFilteredIcons(List<IconItem> icons) {
    if (_searchQuery.isEmpty) return icons;
    return icons.where((icon) {
      return icon.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Başlık ve Kapat Butonu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Arama Kutusu
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: context.l10n.hintIkonAra,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // Kategori Tabları (Sadece arama yoksa göster)
          if (_searchQuery.isEmpty)
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: widget.iconColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: widget.iconColor,
              tabs: AppIcons.categories
                  .map((cat) =>
                      Tab(text: context.translateIconCategory(cat.name)))
                  .toList(),
            ),

          // İkon Grid'i
          Expanded(
            child: _searchQuery.isEmpty
                ? TabBarView(
                    controller: _tabController,
                    children: AppIcons.categories.map((category) {
                      return _buildIconGrid(category.icons);
                    }).toList(),
                  )
                : _buildIconGrid(
                    _getFilteredIcons(AppIcons.getAllIcons()),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconGrid(List<IconItem> icons) {
    if (icons.isEmpty) {
      return Center(
        child: Text(
          context.l10n.ikonBulunamadi,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final icon = icons[index];
        final isSelected = icon.name == widget.selectedIcon;

        return GestureDetector(
          onTap: () {
            widget.onIconSelected(icon.name);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? widget.iconColor.withValues(alpha: 0.15)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? widget.iconColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon.iconData,
              size: 32,
              color: isSelected ? widget.iconColor : Colors.grey.shade700,
            ),
          ),
        );
      },
    );
  }
}

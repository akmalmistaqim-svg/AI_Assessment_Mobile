import 'package:flutter/material.dart';

import '../models/announcement.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/demo_badge.dart';
import 'announcement_detail_page.dart';

/// Halaman Informasi yang menampilkan pencarian, filter kategori dinamis,
/// serta daftar pengumuman akademik contoh.
class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final filteredAnnouncements = appState.filteredAnnouncements;
    final totalCount = appState.totalAnnouncementCount;
    final categories = appState.availableCategories;
    final isFiltered =
        appState.searchQuery.trim().isNotEmpty ||
        appState.selectedCategory != 'Semua';

    // Sinkronkan text controller jika reset dilakukan dari luar (misal tombol reset hasil kosong)
    if (_searchController.text != appState.searchQuery) {
      _searchController.value = TextEditingValue(
        text: appState.searchQuery,
        selection: TextSelection.collapsed(offset: appState.searchQuery.length),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informasi Akademik'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(child: DemoBadge(label: 'Data demo')),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          key: const PageStorageKey('information-scroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // Header ikut bergulir agar tetap dapat digunakan saat keyboard terbuka.
            SliverToBoxAdapter(
              child: Container(
                color: AppTheme.surfaceWhite,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kolom Pencarian
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => appState.setSearchQuery(value),
                      decoration: InputDecoration(
                        hintText: 'Cari judul atau isi informasi...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.navyPrimary,
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  size: 18,
                                  color: AppTheme.textMuted,
                                ),
                                tooltip: 'Hapus pencarian',
                                onPressed: () {
                                  _searchController.clear();
                                  appState.setSearchQuery('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppTheme.backgroundLight,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppTheme.borderLight,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppTheme.borderLight,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppTheme.navyPrimary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Filter Kategori (Horizontal Chips)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((cat) {
                          final isSelected = appState.selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: InkWell(
                              onTap: () => appState.setSelectedCategory(cat),
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.navyPrimary
                                      : AppTheme.surfaceWhite,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.navyPrimary
                                        : AppTheme.borderLight,
                                  ),
                                ),
                                child: Text(
                                  cat == 'Semua' ? 'Semua Kategori' : cat,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppTheme.surfaceWhite
                                        : AppTheme.textDark,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Keterangan status filter jika aktif
                    if (isFiltered) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Text(
                            'Menampilkan ${filteredAnnouncements.length} dari $totalCount informasi',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _searchController.clear();
                              appState.resetFilters();
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                'Reset filter',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.skyBlue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.borderLight,
              ),
            ),
            if (filteredAnnouncements.isEmpty)
              SliverToBoxAdapter(
                child: _EmptySearchResultView(
                  query: appState.searchQuery,
                  category: appState.selectedCategory,
                  onReset: () {
                    _searchController.clear();
                    appState.resetFilters();
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.separated(
                  itemCount: filteredAnnouncements.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final announcement = filteredAnnouncements[index];
                    return _AnnouncementCard(
                      announcement: announcement,
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AnnouncementDetailPage(
                              announcement: announcement,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tampilan informatif saat hasil pencarian dan filter kosong.
class _EmptySearchResultView extends StatelessWidget {
  final String query;
  final String category;
  final VoidCallback onReset;

  const _EmptySearchResultView({
    required this.query,
    required this.category,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppTheme.chipBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_outlined,
                size: 32,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada informasi yang cocok',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.trim().isNotEmpty
                  ? 'Tidak ditemukan pengumuman dengan kata kunci "${query.trim()}"'
                        '${category != 'Semua' ? ' pada kategori "$category"' : ''}.'
                  : 'Tidak ada pengumuman untuk kategori "$category".',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Kembali ke Daftar Lengkap'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.navyPrimary,
                side: const BorderSide(color: AppTheme.navyPrimary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onTap;

  const _AnnouncementCard({required this.announcement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris Kategori & Tanggal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.chipBackground,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Text(
                      announcement.category,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.navyPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      announcement.date,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Judul
              Text(
                announcement.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Ringkasan
              Text(
                announcement.summary,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              // Tautan baca selengkapnya
              const Row(
                children: [
                  Flexible(
                    child: Text(
                      'Baca selengkapnya',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.skyBlue,
                      ),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 13, color: AppTheme.skyBlue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

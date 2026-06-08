import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const HavaDurumuApp());
}

// Uygulamanın ana yapısı ve tema ayarları
class HavaDurumuApp extends StatelessWidget {
  const HavaDurumuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hava Durumu Ödevi',
      debugShowCheckedModeBanner: false,
      // Hocanın istediği modern görünüm için Dark Mode (Koyu Tema) seçtik
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const AnaEkran(),
    );
  }
}

// ==========================================
// EKRAN 1: ANA EKRAN (Arama ve Geçiş Ekranı)
// ==========================================
class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  // Kullanıcının yazdığı şehri yakalamak için controller (Türkçe karakter düzeltildi)
  final TextEditingController _sehirController = TextEditingController();

  // Kolaylık Değişkeni: Veritabanı yerine şimdilik RAM'de tutulan sahte yerel veritabanı listesi
  static List<String> favoriSehirler = ['İstanbul', 'Ankara', 'İzmir'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🌤️ Hava Durumu Keşfet')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Modern arama çubuğu tasarımı
            TextField(
              controller: _sehirController,
              decoration: InputDecoration(
                labelText: 'Şehir Adı Yazın',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),
            // Detay ekranına geçiş butonu
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (_sehirController.text.isNotEmpty) {
                  // EKRAN 2'ye (Detay Ekranı) geçiş yapıyoruz ve şehri gönderiyoruz
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetayEkrani(sehirAdi: _sehirController.text),
                    ),
                  );
                }
              },
              child: const Text('Hava Durumunu Sorgula'),
            ),
            const SizedBox(height: 40),
            // EKRAN 3'e (Favoriler) geçiş butonu
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FavoriEkrani(favoriler: favoriSehirler),
                  ),
                );
              },
              icon: const Icon(Icons.star, color: Colors.amber),
              label: const Text('Favori Şehirlerimi Listele', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// EKRAN 2: DETAY EKRANI (API Entegrasyonu)
// ==========================================
class DetayEkrani extends StatelessWidget {
  final String sehirAdi;
  const DetayEkrani({super.key, required this.sehirAdi});

  // DIŞ SERVİS ENTEGRASYONU: Ücretsiz OpenWeatherMap API'sinden veri çeken fonksiyon
  Future<Map<String, dynamic>> havaDurumuGetir() async {
    // NOT: Hoca test ederken çalışsın diye test amaçlı hazır bir API key koyulmuştur
    final String apiKey = "b1b15e88fa797225412429c1c50c122a1";
    final String url = "https://api.openweathermap.org/data/2.5/weather?q=$sehirAdi&appid=$apiKey&units=metric&lang=tr";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // Gelen JSON verisini çözümlüyoruz
      return jsonDecode(response.body);
    } else {
      throw Exception('Şehir bulunamadı veya API hatası oluştu.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$sehirAdi Hava Durumu')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: havaDurumuGetir(),
        builder: (context, snapshot) {
          // İnternetten veri yüklenirken dönen yuvarlak yükleniyor animasyonu
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Eğer bir hata oluştuysa ekranda gösterilecek mesaj
          if (snapshot.hasError) {
            return const Center(child: Text('❌ Şehir adı bulunamadı veya internet yok.'));
          }

          // Veri başarıyla geldiğinde ekran arayüzünü dolduruyoruz
          final veri = snapshot.data!;
          final sicaklik = veri['main']['temp'].toString();
          final aciklama = veri['weather'][0]['description'].toString().toUpperCase();

          return Center(
            child: Card(
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wb_cloudy, size: 80, color: Colors.blueAccent),
                    const SizedBox(height: 20),
                    Text(sehirAdi.toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text('$sicaklik °C', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300)),
                    const SizedBox(height: 10),
                    Text(aciklama, style: const TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 20),
                    // Favorilere Ekleme Simülasyonu (Veri Yönetimi Kriteri için)
                    ElevatedButton.icon(
                      onPressed: () {
                        if (!_AnaEkranState.favoriSehirler.contains(sehirAdi)) {
                          _AnaEkranState.favoriSehirler.add(sehirAdi);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$sehirAdi Favorilere Eklendi!')),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Favorilerime Kaydet'),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// EKRAN 3: FAVORİLER EKRANI (Veri Yönetimi)
// ==========================================
class FavoriEkrani extends StatelessWidget {
  final List<String> favoriler;
  const FavoriEkrani({super.key, required this.favoriler});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('⭐ Kaydedilen Şehirler')),
      body: favoriler.isEmpty
          ? const Center(child: Text('Henüz favori şehir eklemediniz.'))
          : ListView.builder(
        itemCount: favoriler.length, // DÜZELTİLDİ: count yerine length yazıldı
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.location_city, color: Colors.blueAccent),
              title: Text(favoriler[index]),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Favori listedeki şehre tıklayınca direkt detayına gitsin
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetayEkrani(sehirAdi: favoriler[index]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
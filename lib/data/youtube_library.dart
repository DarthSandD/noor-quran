/// Curated, freely-available Qur'an recitation videos on YouTube.
///
/// These are used by the embedded player. Keep the list small and verified —
/// a broken id shows as an error frame inside the app.
class YoutubeClip {
  final String title;
  final String channel;
  final String videoId;
  const YoutubeClip({required this.title, required this.channel, required this.videoId});
}

class YoutubeLibrary {
  const YoutubeLibrary._();

  /// Featured recitations — one tap to play, embedded.
  static const clips = <YoutubeClip>[
    YoutubeClip(title: 'Surah Yasin — Abdul Rahman Al-Sudais', channel: 'Daily Quran Recitation', videoId: '2OFWn-ZkjRw'),
    YoutubeClip(title: 'Surah Ar-Rahman — Saad Al-Ghamdi', channel: 'Quran Recitation', videoId: 'FLmHcBzVbC0'),
    YoutubeClip(title: 'Juz 30 (Juz Amma) — Mishary Alafasy', channel: 'Mishary Rashid Alafasy', videoId: 'Gb9HhW9pwzs'),
    YoutubeClip(title: 'Complete Qur\'an — Mishary Rashid Alafasy', channel: 'Alafasy', videoId: 'S_AMtPG0Rlc'),
  ];

  /// Full-recitation playlists. Played embedded, so the queue advances
  /// continuously inside the app — the YouTube equivalent of "play album".
  static const playlists = <YoutubeClip>[
    YoutubeClip(title: 'Complete Qur\'an — Mishary Rashid Alafasy', channel: 'Playlist • 114 surah', videoId: 'PLU-KD5_azXnzXFkYDArkZU_dMHgVetbDI'),
    YoutubeClip(title: 'Juz 1–30 — Mishary Rashid Alafasy', channel: 'Playlist • 30 juz', videoId: 'PLU-KD5_azXnyfbcVHoO8gef0D25UCHU73'),
    YoutubeClip(title: 'Complete Recitation — Qur\'an', channel: 'Playlist • full', videoId: 'PLstCeyw8DbpQSslHZNJjiC9mnsyb9p95v'),
  ];
}

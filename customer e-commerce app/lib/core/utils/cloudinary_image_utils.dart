class CloudinaryImageUtils {
  // Inserts a Cloudinary transformation (w_,h_,c_fill,f_auto,q_auto)
  // into an existing secure_url. Safe no-op if the URL isn't Cloudinary.
  static String transform(
    String url, {
    required int width,
    required int height,
    String crop = 'fill',
    String gravity = 'auto',
  }) {
    if (url.isEmpty) return url;
    const marker = '/upload/';
    final idx = url.indexOf(marker);
    if (!url.contains('res.cloudinary.com') || idx == -1) return url;

    final before = url.substring(0, idx + marker.length);
    final after = url.substring(idx + marker.length);

    final transformation =
        'w_$width,h_$height,c_$crop,g_$gravity,f_auto,q_auto/';

    return '$before$transformation$after';
  }
}

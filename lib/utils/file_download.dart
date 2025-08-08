// Plattform-agnostische Schnittstelle
// Diese Datei verwendet conditional imports um die richtige Implementierung zu laden

// Exportiere die downloadFile Funktion basierend auf der Plattform
export 'file_download_io.dart' if (dart.library.html) 'file_download_web.dart'
    show downloadFile;

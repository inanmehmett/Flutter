class LocalConfig {
  // Central place to manage your LAN base URL for physical devices
  // 
  // IMPORTANT: This is for LOCAL DEVELOPMENT ONLY
  // - Update this value when your development machine's IP changes
  // - DO NOT commit real IP addresses to version control
  // - For production, use --dart-define API_BASE_URL=<url>
  // 
  // Defaults to localhost - update for physical device testing on your local network
  // Example: 'http://192.168.1.XXX:5001' (replace XXX with your machine's IP)
  static const String lanBaseUrl = 'http://localhost:5001';
}



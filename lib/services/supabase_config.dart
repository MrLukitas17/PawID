import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://ujsokaxksqwqojvctvtx.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqc29rYXhrc3F3cW9qdmN0dnR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5NDczMjYsImV4cCI6MjA5NjUyMzMyNn0.-Z2vF2M6KuBgv0xikU603xgJV2SegB3P0a8CNlTL9IM';

  static SupabaseClient get client => Supabase.instance.client;
}
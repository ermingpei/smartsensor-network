import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling referral rewards
class ReferralService {
  static const double REFERRAL_BONUS = 500.0;
  static const double BOOST_MULTIPLIER = 1.2;

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Process referral when a new user signs up with an invite code
  Future<bool> processReferral(String refereeId, String inviterCode) async {
    try {
      // 1. Find referrer by invite code
      final referrerResponse = await _supabase
          .from('user_profiles')
          .select('id')
          .eq('invite_code', inviterCode)
          .maybeSingle();

      if (referrerResponse == null) {
        debugPrint('⚠️ Invalid invite code: $inviterCode');
        return false;
      }

      final referrerId = referrerResponse['id'] as String;

      // 2. Check if referee was already referred
      final existingReferral = await _supabase
          .from('referral_rewards')
          .select('id')
          .eq('referee_id', refereeId)
          .maybeSingle();

      if (existingReferral != null) {
        debugPrint('⚠️ User already referred: $refereeId');
        return false;
      }

      // 3. Insert referral reward record
      await _supabase.from('referral_rewards').insert({
        'referrer_id': referrerId,
        'referee_id': refereeId,
        'bonus_points': REFERRAL_BONUS,
        'boost_multiplier': BOOST_MULTIPLIER,
      });

      // 4. Update referrer's stats using RPC
      await _supabase.rpc('add_referral_reward', params: {
        'user_id': referrerId,
        'points': REFERRAL_BONUS,
        'boost': BOOST_MULTIPLIER,
      });

      debugPrint('✅ Referral processed: $referrerId referred $refereeId');
      debugPrint('   Bonus: $REFERRAL_BONUS QBit, Boost: ${BOOST_MULTIPLIER}x');

      return true;
    } catch (e) {
      debugPrint('❌ Error processing referral: $e');
      return false;
    }
  }

  /// Get referral boost multiplier for a user
  Future<double> getReferralBoost(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('referral_boost_multiplier')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return 1.0;
      return (response['referral_boost_multiplier'] as num?)?.toDouble() ?? 1.0;
    } catch (e) {
      debugPrint('⚠️ Error loading referral boost: $e');
      return 1.0;
    }
  }

  /// Get referral count for a user
  Future<int> getReferralCount(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('referral_count')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return 0;
      return (response['referral_count'] as int?) ?? 0;
    } catch (e) {
      debugPrint('⚠️ Error loading referral count: $e');
      return 0;
    }
  }

  /// Get referral history for a user
  Future<List<Map<String, dynamic>>> getReferralHistory(String userId) async {
    try {
      final response = await _supabase
          .from('referral_rewards')
          .select('*')
          .eq('referrer_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('⚠️ Error loading referral history: $e');
      return [];
    }
  }
}

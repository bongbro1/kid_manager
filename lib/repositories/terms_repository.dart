import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kid_manager/models/terms_model.dart';

class TermsRepository {
  final FirebaseFirestore _db;

  TermsRepository(this._db);

  Future<TermsModel> getTerms() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final languageCode = await _resolveLanguageCode();
    final isEnglish = languageCode == 'en';

    return TermsModel(
      title: isEnglish ? 'Terms of Use' : 'Điều khoản sử dụng',
      lastUpdated: '07/03/2026',
      content: isEnglish ? _termsContentEn : _termsContentVi,
    );
  }

  Future<String> _resolveLanguageCode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      try {
        final snap = await _db.collection('users').doc(uid).get();
        final lang = (snap.data()?['locale']?.toString() ?? '').toLowerCase();
        if (lang == 'en') return 'en';
        if (lang == 'vi') return 'vi';
      } catch (_) {}
    }

    return PlatformDispatcher.instance.locale.languageCode.toLowerCase() == 'en'
        ? 'en'
        : 'vi';
  }
}

const String _termsContentVi = '''
1. Mục đích ứng dụng
Ứng dụng được thiết kế để hỗ trợ phụ huynh quản lý và theo dõi hoạt động của con cái.

2. Tài khoản người dùng
Người dùng cần cung cấp thông tin chính xác khi tạo tài khoản và chịu trách nhiệm bảo mật tài khoản của mình.

3. Quyền riêng tư
Ứng dụng có thể thu thập dữ liệu cần thiết để cung cấp dịch vụ.

4. Trách nhiệm người dùng
Không sử dụng ứng dụng cho mục đích vi phạm pháp luật.

5. Giới hạn trách nhiệm
Ứng dụng được cung cấp trên cơ sở "nguyên trạng".

6. Thay đổi điều khoản
Chúng tôi có thể cập nhật điều khoản theo thời gian.

7. Liên hệ
support@yourapp.com
''';

const String _termsContentEn = '''
1. App purpose
This app is designed to help parents manage and monitor their children's activities.

2. User accounts
Users must provide accurate information when creating an account and are responsible for keeping their account secure.

3. Privacy
The app may collect necessary data to provide its services.

4. User responsibilities
Do not use the app for any unlawful purpose.

5. Limitation of liability
The app is provided on an "as is" basis.

6. Changes to the terms
We may update these terms from time to time.

7. Contact
support@yourapp.com
''';

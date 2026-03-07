import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kid_manager/models/terms_model.dart';

class TermsRepository {
  final FirebaseFirestore _db;

  TermsRepository(this._db);
  Future<TermsModel> getTerms() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return TermsModel(
      title: "Điều Khoản Sử Dụng",
      lastUpdated: "07/03/2026",
      content: 
"""
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
""",
    );
  }
}

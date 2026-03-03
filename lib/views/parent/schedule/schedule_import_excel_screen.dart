import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/services/schedule_import_service.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import 'package:kid_manager/core/app_colors.dart';
import 'package:kid_manager/core/app_text_styles.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/schedule_import_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/viewmodels/schedule_vm.dart';

class ScheduleImportExcelScreen extends StatefulWidget {
  const ScheduleImportExcelScreen({super.key});

  @override
  State<ScheduleImportExcelScreen> createState() =>
      _ScheduleImportExcelScreenState();
}

class _ScheduleImportExcelScreenState extends State<ScheduleImportExcelScreen> {
  Uint8List? _pickedBytes;
  String? _pickedName;

  bool _didInit = false;
  bool _needReload = false;

  String? _parentUid(BuildContext context) {
    final storage = context.read<StorageService>();
    return storage.getString(StorageKeys.uid);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final parentUid = _parentUid(context);
      if (parentUid == null) return;

      final userVm = context.read<UserVm>();
      // ✅ đúng API bạn đang dùng ở ScheduleScreen
      userVm.watchChildren(parentUid);

      // auto select bé đầu tiên (nếu đã có sẵn children)
      final importVm = context.read<ScheduleImportVM>();
      if (importVm.selectedChildId == null && userVm.children.isNotEmpty) {
        importVm.setChild(userVm.children.first.uid);
      }
    });
  }

  void _resetPickedFile() {
  setState(() {
    _pickedBytes = null;
    _pickedName = null;
  });
  context.read<ScheduleImportVM>().resetAllKeepChild();
}

  Future<void> _pickExcel() async {
  // reset preview trước khi pick lại
  context.read<ScheduleImportVM>().resetAllKeepChild();

  final res = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['xlsx'],
    withData: true,
  );
  if (res == null) return;

  final file = res.files.first;
  if (file.bytes == null) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không đọc được file, thử lại.')),
    );
    return;
  }

  setState(() {
    _pickedBytes = file.bytes!;
    _pickedName = file.name;
  });

  final parentUid = _parentUid(context);
  if (parentUid == null) return;

  if (!mounted) return;
  await context.read<ScheduleImportVM>().previewFile(
    bytes: _pickedBytes!,
    parentUid: parentUid,
  );
}

  Future<void> _downloadTemplate() async {
  const tag = '[SCHEDULE_TEMPLATE]';

  try {
    debugPrint('$tag ===== START =====');

    final svc = context.read<ScheduleImportVM>().service;
    final File tempFile = await svc.generateTemplateExcel();
    final Uint8List bytes = await tempFile.readAsBytes();

    debugPrint('$tag tempFile.path = ${tempFile.path}');
    debugPrint('$tag tempFile.exists = ${await tempFile.exists()}');
    debugPrint('$tag tempFile.length = ${await tempFile.length()}');
    debugPrint('$tag bytes.length = ${bytes.length}');

    debugPrint('$tag calling FileSaver.saveFile ...');
    final result = await FileSaver.instance.saveFile(
      name: 'schedule_template_${DateTime.now().millisecondsSinceEpoch}',
      bytes: bytes,
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );

    debugPrint('$tag FileSaver result = $result (type=${result.runtimeType})');

    if (!mounted) return;
    final msg = (result is String && result.isNotEmpty)
        ? 'Đã lưu file mẫu: $result'
        : 'Đã lưu file mẫu (không trả về đường dẫn).';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

    debugPrint('$tag ===== END OK =====');
  } catch (e, s) {
    debugPrint('$tag ERROR = $e');
    debugPrint('$tag STACK = $s');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tải file mẫu thất bại: $e')),
    );
  }
}

Future<void> _showSuccessDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F0FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.check, size: 42, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Thành công',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thêm lịch thành công',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  // ✅ đóng dialog bằng context của dialog
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text(
                    'Tiếp tục',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      );
    },
  );
}

  Future<void> _importNow() async {
    final parentUid = _parentUid(context);
    if (parentUid == null) return;

    final vm = context.read<ScheduleImportVM>();

    final imported = await vm.importNow(parentUid: parentUid);

    if (!mounted) return;

    // ❌ thất bại
    if (vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import thất bại: ${vm.error}')),
      );
      return;
    }

    // không có dòng hợp lệ
    if (imported <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có lịch hợp lệ để import.')),
      );
      return;
    }

    // ✅ 1) reload lịch bên ngoài NGAY LẬP TỨC
    // Vì ScheduleViewModel ở Provider phía trên ScheduleScreen
    try {
      await context.read<ScheduleViewModel>().loadMonth();
    } catch (e) {
      // nếu Provider không có ScheduleViewModel thì thôi, vẫn đánh dấu needReload
      debugPrint('[SCHEDULE_IMPORT] cannot reload ScheduleViewModel here: $e');
    }

    // ✅ 2) đánh dấu cần reload khi quay về
    _needReload = true;

    // ✅ 3) hiện thông báo thành công
    await _showSuccessDialog(context);
    if (!mounted) return;

    // ✅ 4) reset giao diện import để tiếp tục import
    _resetPickedFile();

    // NOTE: không pop về Schedule ở đây nữa
  }

  @override
  Widget build(BuildContext context) {
    final userVm = context.watch<UserVm>();
    final importVm = context.watch<ScheduleImportVM>();

    final children = userVm.children;

    // ✅ auto select khi children vừa load về (watchChildren async)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (importVm.selectedChildId == null && children.isNotEmpty) {
        importVm.setChild(children.first.uid);
      }
    });

    return WillPopScope(
    onWillPop: () async {
      Navigator.pop(context, _needReload);
      return false; // chặn pop mặc định
    },
    child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Thêm file Excel',
          style: AppTextStyles.scheduleAppBarTitle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context, _needReload), // trả về needReload khi pop
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chọn bé', style: AppTextStyles.body),
                const SizedBox(height: 10),
                _ChildDropdown(
                  children: children,
                  selectedId: importVm.selectedChildId,
                  onChanged: (id) {
                    importVm.setChild(id);
                    setState(() {
                      _pickedBytes = null;
                      _pickedName = null;
                    });
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _PrimaryOutlineButton(
                        text: 'Tải file mẫu',
                        icon: Icons.download,
                        onTap: importVm.loading ? null : _downloadTemplate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PrimaryButton(
                        text: _pickedName == null ? 'Chọn file Excel' : 'Chọn file khác',
                        icon: Icons.upload_file,
                        onTap: importVm.loading ? null : _pickExcel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Đã chọn: $_pickedName',
                          style: AppTextStyles.scheduleItemTime,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: importVm.loading ? null : _resetPickedFile,
                        child: const Text('Đổi file'),
                      )
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (importVm.loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(),
              ),
            ),
          if (!importVm.loading && importVm.error != null)
            _SectionCard(
              child: Text(
                importVm.error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          if (!importVm.loading && importVm.preview != null) ...[
            _PreviewSummary(preview: importVm.preview!),
            const SizedBox(height: 10),
            _PreviewList(preview: importVm.preview!),
            const SizedBox(height: 14),
            _PrimaryButton(
              text: 'Thêm ${importVm.preview!.okCount} lịch',
              icon: Icons.check_circle,
              onTap: importVm.preview!.okCount == 0 ? null : _importNow,

            ),
          ],
        ],
      ),
    ),
    );
  }
}

// ================= UI WIDGETS =================

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ChildDropdown extends StatelessWidget {
  final List<AppUser> children;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _ChildDropdown({
    required this.children,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const Text('Chưa có bé', style: AppTextStyles.body);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedId ?? children.first.uid,
          items: children
              .map(
                (c) => DropdownMenuItem(
                  value: c.uid,
                  child: Text(
                    (c.displayName ?? c.email ?? c.uid),
                    style: AppTextStyles.body,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(text, style: AppTextStyles.scheduleCreateButton),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryOutlineButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;

  const _PrimaryOutlineButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                text,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewSummary extends StatelessWidget {
  final ImportPreview preview;
  const _PreviewSummary({required this.preview});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        children: [
          _Chip(
            label: 'OK: ${preview.okCount}',
            bg: const Color(0xFFE9F9EF),
            fg: AppColors.success,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Trùng: ${preview.duplicateCount}',
            bg: const Color(0xFFFFF7D6),
            fg: const Color(0xFF8A6D00),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Lỗi: ${preview.errorCount}',
            bg: const Color(0xFFFFE8E8),
            fg: AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Chip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.scheduleItemTime
            .copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PreviewList extends StatelessWidget {
  final ImportPreview preview;
  const _PreviewList({required this.preview});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Xem trước dữ liệu', style: AppTextStyles.title),
          const SizedBox(height: 10),
          ...preview.rows.map((r) => _PreviewRow(r: r)),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final ImportRowResult r;
  const _PreviewRow({required this.r});

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.white;
    String status = 'OK';

    if (r.error != null) {
      bg = const Color(0xFFFFE8E8);
      status = 'LỖI';
    } else if (r.isDuplicateInFile || r.isDuplicateInDb) {
      bg = const Color(0xFFFFF7D6);
      status = 'TRÙNG';
    }

    final s = r.schedule;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              status,
              style: AppTextStyles.scheduleItemTime
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: r.error != null
                ? Text('Dòng ${r.rowIndex}: ${r.error}',
                    style: AppTextStyles.body)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dòng ${r.rowIndex}: ${s!.title}',
                        style: AppTextStyles.scheduleItemTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_fmtDate(s.date)}  ${_fmtTime(s.startAt)}-${_fmtTime(s.endAt)}',
                        style: AppTextStyles.scheduleItemTime,
                      ),
                      if ((s.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(s.description!, style: AppTextStyles.scheduleItemTime),
                      ],
                      if (r.isDuplicateInDb)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Trùng với dữ liệu đã có trên hệ thống',
                            style: TextStyle(fontSize: 12, color: Color(0xFF8A6D00)),
                          ),
                        ),
                      if (r.isDuplicateInFile)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Trùng trong file',
                            style: TextStyle(fontSize: 12, color: Color(0xFF8A6D00)),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _fmtTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';
  static String _fmtDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';
}
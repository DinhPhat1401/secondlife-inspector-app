import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../models/inspection_order.dart';
import '../providers/inspection_provider.dart';

class ChecklistExecutionScreen extends ConsumerStatefulWidget {
  final InspectionOrder? order;
  const ChecklistExecutionScreen({super.key, this.order});

  @override
  ConsumerState<ChecklistExecutionScreen> createState() => _ChecklistExecutionScreenState();
}

class _ChecklistExecutionScreenState extends ConsumerState<ChecklistExecutionScreen> {
  late InspectionOrder _order;
  double _conditionScore = 92;
  String _conditionGrade = 'A - Rất Tốt';
  final _sealIdController = TextEditingController(text: 'SL-SEAL-9081-A1');
  final _barcodeController = TextEditingController(text: 'SL90812026');
  final _videoUrlController = TextEditingController(
      text: 'https://cloudinary.com/secondlife/inspection/video_proof_daikin.mp4');
  final _overallNoteController = TextEditingController(
      text: 'Máy nén hoạt động êm ái, bo mạch nguyên zin chưa qua sửa chữa, độ lạnh đạt chuẩn 16°C sau 10 phút.');

  @override
  void initState() {
    super.initState();
    _order = widget.order ??
        ref.read(inspectionProvider).selectedOrder ??
        ref.read(inspectionProvider).orders.first;

    if (_order.tamperSealId != null) {
      _sealIdController.text = _order.tamperSealId!;
    }
    if (_order.barcode != null) {
      _barcodeController.text = _order.barcode!;
    }
    if (_order.conditionScore != null) {
      _conditionScore = _order.conditionScore!.toDouble();
    }
    if (_order.conditionGrade != null) {
      _conditionGrade = _order.conditionGrade!;
    }

    Future.microtask(() {
      ref.read(inspectionProvider.notifier).fetchChecklistForOrder(_order.id);
    });
  }

  @override
  void dispose() {
    _sealIdController.dispose();
    _barcodeController.dispose();
    _videoUrlController.dispose();
    _overallNoteController.dispose();
    super.dispose();
  }

  void _submit(String outcome) async {
    final success = await ref.read(inspectionProvider.notifier).submitInspectionResult(
          orderId: _order.id,
          status: outcome,
          conditionScore: _conditionScore.toInt(),
          conditionGrade: _conditionGrade,
          tamperSealId: _sealIdController.text.trim(),
          barcode: _barcodeController.text.trim(),
          videoProofUrl: _videoUrlController.text.trim(),
          note: _overallNoteController.text.trim(),
        );

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                outcome == 'PASSED' ? Icons.verified : Icons.warning_amber_rounded,
                color: outcome == 'PASSED' ? AppColors.passGreen : AppColors.failRed,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(outcome == 'PASSED' ? 'Kiểm Định ĐẠT CHUẨN' : 'Kiểm Định KHÔNG ĐẠT'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Biên bản kỹ thuật và kết quả checklist đã được nộp thành công lên hệ thống SecondLife.',
                style: TextStyle(fontSize: 14, color: AppColors.slate700),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mã tem niêm phong: ${_sealIdController.text}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Điểm đánh giá: ${_conditionScore.toInt()}/100 ($_conditionGrade)',
                        style: const TextStyle(fontSize: 13, color: AppColors.slate700)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/dashboard');
              },
              child: const Text('VỀ DANH SÁCH'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/seal-verification', extra: _sealIdController.text.trim());
              },
              child: const Text('XEM CHỨNG THƯ TEM'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inspectionProvider);
    final checklist = state.currentChecklist;

    final allMandatoryPassed = checklist
        .where((item) => item.mandatory)
        .every((item) => item.passed == true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biên Bản Kỹ Thuật & Cấp Tem'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: AppColors.slate100,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.settings_suggest, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Đơn kiểm định #${_order.id}',
                              style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
                          Text(_order.postTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Section 1: Checklist Items
            const Text(
              '1. Danh Mục Tiêu Chuẩn Kiểm Định (Checklist)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.slate900),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    allMandatoryPassed
                        ? 'Tất cả tiêu chí bắt buộc đã ĐẠT CHUẨN'
                        : 'Đánh giá từng hạng mục bắt buộc. Phải đạt tất cả mục để cấp tem PASSED.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: allMandatoryPassed ? FontWeight.bold : FontWeight.normal,
                      color: allMandatoryPassed ? AppColors.passGreen : AppColors.slate500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...checklist.map((item) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.primaryContainer,
                            child: Text(
                              '${item.orderIndex}',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.itemTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          if (item.mandatory)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Bắt buộc',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.criteriaDescription,
                        style: const TextStyle(fontSize: 12, color: AppColors.slate600),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ref.read(inspectionProvider.notifier).updateChecklistItem(
                                      item.id,
                                      true,
                                      item.inspectorNote,
                                      item.photoProofUrl,
                                    );
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 16),
                              label: const Text('ĐẠT (PASS)'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: item.passed == true ? AppColors.passGreenLight : null,
                                foregroundColor: item.passed == true ? AppColors.passGreen : AppColors.slate600,
                                side: BorderSide(
                                  color: item.passed == true ? AppColors.passGreen : AppColors.cardBorder,
                                  width: item.passed == true ? 2 : 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ref.read(inspectionProvider.notifier).updateChecklistItem(
                                      item.id,
                                      false,
                                      item.inspectorNote,
                                      item.photoProofUrl,
                                    );
                              },
                              icon: const Icon(Icons.cancel_outlined, size: 16),
                              label: const Text('HỎNG (FAIL)'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: item.passed == false ? AppColors.failRedLight : null,
                                foregroundColor: item.passed == false ? AppColors.failRed : AppColors.slate600,
                                side: BorderSide(
                                  color: item.passed == false ? AppColors.failRed : AppColors.cardBorder,
                                  width: item.passed == false ? 2 : 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Section 2: Score & Condition Grade
            const Text(
              '2. Điểm Số Đánh Giá & Phân Hạng Máy (Condition Score)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.slate900),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Điểm chất lượng:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(
                          '${_conditionScore.toInt()} / 100',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                        ),
                      ],
                    ),
                    Slider(
                      value: _conditionScore,
                      min: 40,
                      max: 100,
                      divisions: 60,
                      activeColor: AppColors.primary,
                      label: '${_conditionScore.toInt()}',
                      onChanged: (val) {
                        setState(() {
                          _conditionScore = val;
                          if (val >= 95) {
                            _conditionGrade = 'S - Nguyên Bản Mới';
                          } else if (val >= 88) {
                            _conditionGrade = 'A - Rất Tốt';
                          } else if (val >= 75) {
                            _conditionGrade = 'B - Tốt (Ổn Định)';
                          } else {
                            _conditionGrade = 'C - Trung Bình';
                          }
                        });
                      },
                    ),
                    Row(
                      children: [
                        const Text('Phân hạng máy: ', style: TextStyle(fontSize: 13, color: AppColors.slate600)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _conditionGrade,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Section 3: Tamper Seal & Video Proof
            const Text(
              '3. Tem Niêm Phong Chống Tráo & Bằng Chứng Video',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.slate900),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _sealIdController,
                      decoration: InputDecoration(
                        labelText: 'Mã Tem Niêm Phong (Tamper Seal ID)',
                        prefixIcon: const Icon(Icons.qr_code, color: AppColors.secondary),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                          tooltip: 'Quét camera mã tem',
                          onPressed: () async {
                            final scanned = await context.push<String>('/seal-scanner');
                            if (scanned != null && scanned.isNotEmpty) {
                              setState(() => _sealIdController.text = scanned);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Mã Vạch / Barcode Thân Máy',
                        prefixIcon: Icon(Icons.barcode_reader, color: AppColors.slate600),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _videoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Đường dẫn Video kiểm tra máy (Cloudinary / S3)',
                        prefixIcon: Icon(Icons.videocam_outlined, color: AppColors.mapBlue),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _overallNoteController,
                      decoration: const InputDecoration(
                        labelText: 'Kết luận chuyên môn của Kỹ thuật viên',
                        prefixIcon: Icon(Icons.edit_note, color: AppColors.slate600),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Buttons: PASS or FAIL
            ElevatedButton.icon(
              onPressed: state.isSubmitting ? null : () => _submit('PASSED'),
              icon: const Icon(Icons.verified_outlined),
              label: const Text('KÝ DUYỆT & CẤP CHỨNG NHẬN ĐẠT CHUẨN (PASSED)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.passGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: state.isSubmitting ? null : () => _submit('FAILED'),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('KÝ TỪ CHỐI - KHÔNG ĐẠT YÊU CẦU (FAILED)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.failRed,
                side: const BorderSide(color: AppColors.failRed),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/theme/AppColors.dart';
import 'package:benhvien7c/core/widgets/AppButton.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/TypeFourResultViewModel.dart';

class TypeFourResultView extends StatefulWidget {
  const TypeFourResultView({super.key});

  @override
  State<TypeFourResultView> createState() => _TypeFourResultViewState();
}

class _TypeFourResultViewState extends State<TypeFourResultView> {
  late final TypeFourResultViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TypeFourResultViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF4B90E2),
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Bước C - Kết quả',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6FBFF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD9EAFE)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F6EB),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF1F9D57),
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Bạn đã đến bước C',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Đây là màn cuối của demo dạng 4. Bây giờ bạn có thể thử bấm back để quan sát stack quay ngược lại.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ..._viewModel.highlights.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _HighlightRow(text: line),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Quay lại bước B',
                icon: Icons.undo_rounded,
                onPressed: () => AppNavigator.safePop(context),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sau khi quay về B, bạn bấm back thêm lần nữa sẽ trở về lại màn A ban đầu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCEAF8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.subdirectory_arrow_right_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

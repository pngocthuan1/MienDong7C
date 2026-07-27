import 'package:flutter/material.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/theme/AppColors.dart';
import 'package:benhvien7c/core/widgets/AppButton.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/TypeFourProcessingViewModel.dart';

class TypeFourProcessingView extends StatefulWidget {
  const TypeFourProcessingView({super.key});

  @override
  State<TypeFourProcessingView> createState() => _TypeFourProcessingViewState();
}

class _TypeFourProcessingViewState extends State<TypeFourProcessingView> {
  late final TypeFourProcessingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TypeFourProcessingViewModel();

    if (!_viewModel.hasForwarded) {
      _viewModel.markForwarded();
      AppNavigator.forwardAfterBuild(context, RouteNames.typeFourResult);
    }
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
          backgroundColor: const Color(0xFFF7FBFF),
          appBar: AppBar(
            backgroundColor: const Color(0xFF4B90E2),
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Bước B - Trung chuyển',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4FF),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Bước B đang tự chuyển sang bước C',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Màn này dùng cơ chế forward sau build. Khi bạn quay lại từ bước C, bước B vẫn còn trong stack nên bạn sẽ thấy lại màn này.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDCEAF8)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cách đọc stack hiện tại',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'A đã push B. Sau đó B tự push sang C. Vì B không bị replace nên back từ C sẽ quay lại đúng bước B.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Quay lại bước A',
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => AppNavigator.safePop(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

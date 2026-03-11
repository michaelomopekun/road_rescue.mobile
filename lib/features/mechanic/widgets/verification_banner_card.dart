import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:road_rescue/shared/widgets/primary_button.dart';
import 'package:road_rescue/theme/app_colors.dart';
import 'package:road_rescue/models/verification_status.dart';

class VerificationBannerCard extends StatelessWidget {
  final VoidCallback onVerifyPressed;
  final VerificationStatus? verificationStatus;

  const VerificationBannerCard({
    super.key,
    required this.onVerifyPressed,
    this.verificationStatus,
  });

  String get _bannerTitle {
    if (verificationStatus == null || verificationStatus!.isNotStarted) {
      return 'Complete your account';
    } else if (verificationStatus!.isPending) {
      return 'Verification in Progress';
    } else if (verificationStatus!.isApproved) {
      return 'Verified!';
    }
    return 'Complete your account';
  }

  String get _bannerSubtitle {
    if (verificationStatus == null || verificationStatus!.isNotStarted) {
      return 'Verify your workshop to start\nreceiving roadside requests.';
    } else if (verificationStatus!.isPending) {
      return 'Your documents are under review.\nThis usually takes 24-48 hours.';
    } else if (verificationStatus!.isApproved) {
      return 'Your account is verified. You can\nnow receive roadside requests.';
    }
    return 'Verify your workshop to start\nreceiving roadside requests.';
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = verificationStatus?.isApproved ?? false;
    final isPending = verificationStatus?.isPending ?? false;

    return Container(
      decoration: BoxDecoration(
        color: isVerified ? Colors.green[50] : AppColors.lightSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isVerified ? AppColors.success : AppColors.secondaryBorder,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _bannerTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 25,
                            color: isVerified
                                ? Colors.green[700]
                                : AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _bannerSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isVerified
                            ? Colors.green[600]
                            : Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 119.75,
                height: 91.27,
                decoration: BoxDecoration(
                  color: isVerified
                      ? Colors.green[50]
                      : AppColors.lightSecondary,
                ),
                child: Transform.translate(
                  offset: const Offset(-20, -5),
                  child: isVerified
                      ? Icon(
                          Icons.verified_user,
                          size: 60,
                          color: Colors.green[600],
                        )
                      : SvgPicture.asset(
                          'assets/svg/verification_badge.svg',
                          width: 119.75,
                          height: 91.27,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isVerified)
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: isPending ? 'Verification Pending' : 'Verify Account',
                label: isPending ? 'Verification Pending' : 'Verify Account',
                isPending: isPending,
                onPressed: isPending ? null : onVerifyPressed,
              ),
            ),
        ],
      ),
    );
  }
}

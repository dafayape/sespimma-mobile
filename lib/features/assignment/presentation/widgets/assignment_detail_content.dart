import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/features/assignment/data/models/assignment_model.dart';
import 'package:sespimma/features/assignment/presentation/widgets/assignment_attachment_section.dart';
import 'package:sespimma/features/assignment/presentation/widgets/assignment_deadline_card_widget.dart';
import 'package:sespimma/features/assignment/presentation/widgets/assignment_header_widget.dart';
import 'package:sespimma/features/assignment/presentation/widgets/assignment_instruction_section.dart';
import 'package:sespimma/features/assignment/presentation/widgets/assignment_submitted_section_widget.dart';
import 'package:sespimma/features/assignment/presentation/widgets/assignment_upload_section_widget.dart';

class AssignmentDetailContent extends StatelessWidget {
  final AssignmentModel assignment;
  final bool isAktif;
  final bool isExpired;
  final bool isFileAttached;
  final String fileName;
  final Animation<double> fadeAnimation;
  final VoidCallback onPickFile;
  final VoidCallback onRemoveFile;
  final ValueChanged<String> onDownloadFile;

  const AssignmentDetailContent({
    super.key,
    required this.assignment,
    required this.isAktif,
    required this.isExpired,
    required this.isFileAttached,
    required this.fileName,
    required this.fadeAnimation,
    required this.onPickFile,
    required this.onRemoveFile,
    required this.onDownloadFile,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: AppColors.background,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.xxl,
              vertical: AppDimensions.xxxl,
            ),
            child: AssignmentHeaderWidget(assignment: assignment),
          ),
          FadeTransition(
            opacity: fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AssignmentDeadlineCardWidget(
                    assignment: assignment,
                    isAktif: isAktif,
                    isExpired: isExpired,
                  ),
                  const SizedBox(height: AppDimensions.xxxl),
                  AssignmentInstructionSection(deskripsi: assignment.deskripsi),
                  if (assignment.attachmentName?.isNotEmpty == true) ...[
                    const SizedBox(height: AppDimensions.xxl),
                    AssignmentAttachmentSection(
                      attachmentName: assignment.attachmentName!,
                      onDownload: () =>
                          onDownloadFile(assignment.attachmentName!),
                    ),
                  ],
                  const SizedBox(height: AppDimensions.xxxl),
                  if (isAktif)
                    AssignmentUploadSectionWidget(
                      isFileAttached: isFileAttached,
                      fileName: fileName,
                      isExpired: isExpired,
                      onPickFile: onPickFile,
                      onRemoveFile: onRemoveFile,
                    )
                  else
                    AssignmentSubmittedSectionWidget(
                      assignment: assignment,
                      onDownload: () => onDownloadFile(
                        assignment.submissionFileName ?? 'Berkas Terlampir',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

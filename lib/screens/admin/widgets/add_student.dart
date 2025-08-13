import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import 'dart:io';
import '../../../controllers/student_controller.dart';
import '../../../controllers/subject_controller.dart';
import '../../../models/subject.dart';
import '../../../core/themes/app_colors.dart';

class StudentFormWidget extends StatefulWidget {
  const StudentFormWidget({super.key});

  @override
  State<StudentFormWidget> createState() => _StudentFormWidgetState();
}

class _StudentFormWidgetState extends State<StudentFormWidget> {
  late final StudentController controller;
  final ImagePicker picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    controller = StudentController();
  }

  bool _validateCurrentStep() {
    switch (controller.currentStep) {
      case 0: // Basic Details
        if (controller.studentClassController.text.isEmpty) {
          controller.showSnackBar('Class is required', isError: true);
          return false;
        }

        if (controller.feePaidController.text.isEmpty) {
          controller.showSnackBar('Fee paid is required', isError: true);
          return false;
        }
        if (controller.feeTotalController.text.isEmpty) {
          controller.showSnackBar('Total fee is required', isError: true);
          return false;
        }
        if (controller.birthdateController.text.isEmpty) {
          controller.showSnackBar('Birth date is required', isError: true);
          return false;
        }
        if (controller.addressController.text.isEmpty) {
          controller.showSnackBar('Address is required', isError: true);
          return false;
        }
        return true;

      case 1: // Education Details
        if (controller.boardController.text.isEmpty) {
          controller.showSnackBar('Board is required', isError: true);
          return false;
        }
        if (controller.schoolController.text.isEmpty) {
          controller.showSnackBar('School is required', isError: true);
          return false;
        }
        if (controller.fnameController.text.isEmpty) {
          controller.showSnackBar('First name is required', isError: true);
          return false;
        }
        if (controller.mnameController.text.isEmpty) {
          controller.showSnackBar('Middle name is required', isError: true);
          return false;
        }
        if (controller.lnameController.text.isEmpty) {
          controller.showSnackBar('Last name is required', isError: true);
          return false;
        }
        if (controller.mediumController.text.isEmpty) {
          controller.showSnackBar('Medium is required', isError: true);
          return false;
        }
        return true;

      case 2: // Contact Details
        // Student contact is optional, but if provided must be 10 digits

        // Parent contact is required
        if (controller.parentContactController.text.isEmpty) {
          controller.showSnackBar('Parent contact is required', isError: true);
          return false;
        }
        if (controller.parentContactController.text.length != 10) {
          controller.showSnackBar('Parent contact must be 10 digits',
              isError: true);
          return false;
        }
        return true;

      default:
        return false;
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final extension = image.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png'].contains(extension)) {
          controller.showSnackBar('Only JPG, JPEG, and PNG images are allowed',
              isError: true);
          return;
        }
        controller.setImage(File(image.path));
      }
    } catch (e) {
      controller.showSnackBar('Error picking image: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          key: controller.scaffoldKey,
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: const Text('Add Student',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                )),
            backgroundColor: AppColors.primary,
            elevation: 4,
          ),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              width: double.infinity,
              height: double.infinity,
              color: AppColors.scaffoldBackground,
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: AppColors.primary,
                    secondary: AppColors.secondary,
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 16),
                      child: ListenableBuilder(
                        listenable: controller,
                        builder: (context, _) => Card(
                          color: AppColors.cardBackground,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 20),
                            child: Stepper(
                              type: StepperType.vertical,
                              currentStep: controller.currentStep,
                              onStepContinue: () {
                                if (controller.currentStep < 2) {
                                  if (_validateCurrentStep()) {
                                    controller.nextStep();
                                  } else {
                                    _formKey.currentState?.validate();
                                  }
                                } else {
                                  if (_validateCurrentStep()) {
                                    controller.submitForm();
                                  } else {
                                    _formKey.currentState?.validate();
                                  }
                                }
                              },
                              onStepCancel: () {
                                if (controller.currentStep > 0) {
                                  controller.previousStep();
                                }
                              },
                              controlsBuilder: (context, details) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: controller.isLoading
                                              ? null
                                              : details.onStepContinue,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: 2,
                                            shadowColor: AppColors.primary
                                                .withOpacity(0.2),
                                          ),
                                          child: Text(
                                            controller.currentStep == 2
                                                ? 'Submit'
                                                : 'Continue',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (controller.currentStep > 0) ...[
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: controller.isLoading
                                                ? null
                                                : details.onStepCancel,
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.primary,
                                              side: const BorderSide(
                                                  color: AppColors.primary),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text('Back'),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                              steps: [
                                Step(
                                  title: const Text('Basic Details'),
                                  content: Column(
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withOpacity(0.1),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child:
                                              DropdownButtonFormField<String>(
                                            value: controller
                                                    .studentClassController
                                                    .text
                                                    .isEmpty
                                                ? null
                                                : controller
                                                    .studentClassController
                                                    .text,
                                            dropdownColor: Colors.white,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 16,
                                            ),
                                            decoration: InputDecoration(
                                              labelText: 'Class',
                                              floatingLabelBehavior:
                                                  FloatingLabelBehavior.never,
                                              labelStyle: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              prefixIcon: Container(
                                                margin: const EdgeInsets.only(
                                                    left: 12, right: 8),
                                                child: const Icon(
                                                  Icons.class_,
                                                  color: AppColors.primary,
                                                  size: 20,
                                                ),
                                              ),
                                              prefixIconConstraints:
                                                  const BoxConstraints(
                                                      minWidth: 40,
                                                      minHeight: 40),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: AppColors.primary,
                                                  width: 1.5,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide(
                                                  color: AppColors.primary
                                                      .withOpacity(0.2),
                                                ),
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 16,
                                              ),
                                              hintStyle: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 15,
                                              ),
                                            ),
                                            hint: const Text(
                                              'Select Class',
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 15,
                                              ),
                                            ),
                                            icon: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 12),
                                              child: Icon(
                                                Icons.arrow_drop_down_circle,
                                                color: AppColors.primary,
                                                size: 24,
                                              ),
                                            ),
                                            isExpanded: true,
                                            menuMaxHeight: 300,
                                            items: [
                                              DropdownMenuItem(
                                                value: '7',
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 8),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppColors
                                                              .primary
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: const Icon(
                                                          Icons.school,
                                                          color:
                                                              AppColors.primary,
                                                          size: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                        '7th Class',
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .textPrimary,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: '8',
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 8),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppColors
                                                              .primary
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: const Icon(
                                                          Icons.school,
                                                          color:
                                                              AppColors.primary,
                                                          size: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                        '8th Class',
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .textPrimary,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: '9',
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 8),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppColors
                                                              .primary
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: const Icon(
                                                          Icons.school,
                                                          color:
                                                              AppColors.primary,
                                                          size: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                        '9th Class',
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .textPrimary,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: '10',
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 8),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppColors
                                                              .primary
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: const Icon(
                                                          Icons.school,
                                                          color:
                                                              AppColors.primary,
                                                          size: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                        '10th Class',
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .textPrimary,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              if (value != null) {
                                                controller
                                                    .studentClassController
                                                    .text = value;
                                              }
                                            },
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Class is required';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 14),
                                        child: FutureBuilder<List<Subject>>(
                                          future:
                                              SubjectController().getSubjects(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors.primary
                                                          .withOpacity(0.1),
                                                      blurRadius: 4,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            AppColors.primary),
                                                  ),
                                                ),
                                              );
                                            }

                                            if (snapshot.hasError) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                      color: AppColors.primary
                                                          .withOpacity(0.2)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.error_outline,
                                                      color: AppColors.error,
                                                      size: 24,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        'Failed to load subjects. Please try again.',
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .textPrimary,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        setState(
                                                            () {}); // Retry loading
                                                      },
                                                      child: Text(
                                                        'Retry',
                                                        style: TextStyle(
                                                          color:
                                                              AppColors.primary,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }

                                            final subjects =
                                                snapshot.data ?? [];

                                            if (subjects.isEmpty) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                      color: AppColors.primary
                                                          .withOpacity(0.2)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.info_outline,
                                                      color: AppColors.primary,
                                                      size: 24,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        'No subjects available. Please add subjects first.',
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .textPrimary,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }

                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 8),
                                                  child: Text(
                                                    'Select Subjects',
                                                    style: TextStyle(
                                                      color:
                                                          AppColors.textPrimary,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: AppColors.primary
                                                            .withOpacity(0.1),
                                                        blurRadius: 4,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  child: GridView.builder(
                                                    shrinkWrap: true,
                                                    physics:
                                                        const NeverScrollableScrollPhysics(),
                                                    gridDelegate:
                                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: 2,
                                                      crossAxisSpacing: 12,
                                                      mainAxisSpacing: 12,
                                                      childAspectRatio: 2.5,
                                                    ),
                                                    itemCount: subjects.length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      final subject =
                                                          subjects[index];
                                                      final isSelected =
                                                          controller
                                                              .selectedSubjects
                                                              .contains(
                                                                  subject.id);

                                                      return InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            if (isSelected) {
                                                              controller
                                                                  .selectedSubjects
                                                                  .remove(
                                                                      subject
                                                                          .id);
                                                            } else {
                                                              controller
                                                                  .selectedSubjects
                                                                  .add(subject
                                                                      .id);
                                                            }
                                                            controller
                                                                .notifyListeners();
                                                          });
                                                        },
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(24),
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        24),
                                                            border: Border.all(
                                                              color: isSelected
                                                                  ? AppColors
                                                                      .primary
                                                                  : AppColors
                                                                      .textSecondary
                                                                      .withOpacity(
                                                                          0.3),
                                                              width: isSelected
                                                                  ? 1.5
                                                                  : 1,
                                                            ),
                                                          ),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                isSelected
                                                                    ? Icons
                                                                        .check_circle
                                                                    : Icons
                                                                        .circle_outlined,
                                                                color: isSelected
                                                                    ? AppColors
                                                                        .primary
                                                                    : AppColors
                                                                        .textSecondary,
                                                                size: 20,
                                                              ),
                                                              const SizedBox(
                                                                  width: 8),
                                                              Flexible(
                                                                child: Text(
                                                                  subject.name,
                                                                  style:
                                                                      TextStyle(
                                                                    color: isSelected
                                                                        ? AppColors
                                                                            .primary
                                                                        : AppColors
                                                                            .textPrimary,
                                                                    fontWeight: isSelected
                                                                        ? FontWeight
                                                                            .w600
                                                                        : FontWeight
                                                                            .w400,
                                                                    fontSize:
                                                                        15,
                                                                  ),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                      _buildInputField(
                                        controller:
                                            controller.feePaidController,
                                        label: 'Fee Paid',
                                        icon: Icons.payments,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Fee paid is required';
                                          }
                                          if (double.tryParse(value) == null) {
                                            return 'Please enter a valid amount';
                                          }
                                          return null;
                                        },
                                      ),
                                      _buildInputField(
                                        controller:
                                            controller.feeTotalController,
                                        label: 'Total Fee',
                                        icon: Icons.account_balance_wallet,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Total fee is required';
                                          }
                                          if (double.tryParse(value) == null) {
                                            return 'Please enter a valid amount';
                                          }
                                          return null;
                                        },
                                      ),
                                      _buildInputField(
                                        controller:
                                            controller.birthdateController,
                                        label: 'Birth Date',
                                        icon: Icons.calendar_today,
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime.now(),
                                          );
                                          if (date != null) {
                                            controller
                                                    .birthdateController.text =
                                                '${date.day}/${date.month}/${date.year}';
                                          }
                                        },
                                        readOnly: true,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Birth date is required';
                                          }
                                          return null;
                                        },
                                      ),
                                      _buildInputField(
                                        controller:
                                            controller.addressController,
                                        label: 'Address',
                                        icon: Icons.location_on,
                                        maxLines: 3,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Address is required';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                  isActive: controller.currentStep >= 0,
                                ),
                                Step(
                                  title: const Text('Education Details'),
                                  content: Column(
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 14),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors
                                                .white, // Light peach color from screenshot
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: FormField<String>(
                                            validator: (value) {
                                              if (controller.boardController
                                                  .text.isEmpty) {
                                                return 'Board is required';
                                              }
                                              return null;
                                            },
                                            builder:
                                                (FormFieldState<String> state) {
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(left: 16),
                                                        child: Icon(
                                                          Icons.school,
                                                          color:
                                                              AppColors.primary,
                                                          size: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child:
                                                            DropdownButtonHideUnderline(
                                                          child: DropdownButton<
                                                              String>(
                                                            value: controller
                                                                    .boardController
                                                                    .text
                                                                    .isEmpty
                                                                ? null
                                                                : controller
                                                                    .boardController
                                                                    .text,
                                                            hint: Text(
                                                              'Board',
                                                              style: TextStyle(
                                                                color: AppColors
                                                                    .textSecondary,
                                                                fontSize: 15,
                                                              ),
                                                            ),
                                                            icon: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      right:
                                                                          16),
                                                              child: Icon(
                                                                Icons
                                                                    .arrow_drop_down_circle,
                                                                color: AppColors
                                                                    .primary,
                                                                size: 24,
                                                              ),
                                                            ),
                                                            isExpanded: true,
                                                            dropdownColor:
                                                                Colors.white,
                                                            style:
                                                                const TextStyle(
                                                              color: AppColors
                                                                  .textPrimary,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                            items: [
                                                              DropdownMenuItem(
                                                                value: 'CBSE',
                                                                child: Text(
                                                                    'CBSE'),
                                                              ),
                                                              DropdownMenuItem(
                                                                value: 'GSEB',
                                                                child: Text(
                                                                    'GSEB'),
                                                              ),
                                                            ],
                                                            onChanged: (value) {
                                                              if (value !=
                                                                  null) {
                                                                setState(() {
                                                                  controller
                                                                      .boardController
                                                                      .text = value;
                                                                  state.didChange(
                                                                      value);
                                                                });
                                                              }
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (state.hasError)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 16, top: 4),
                                                      child: Text(
                                                        state.errorText!,
                                                        style: TextStyle(
                                                          color:
                                                              Colors.red[700],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: TextFormField(
                                          controller:
                                              controller.schoolController,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'School',
                                            floatingLabelBehavior:
                                                FloatingLabelBehavior.auto,
                                            labelStyle: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            floatingLabelStyle: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 15,
                                            ),
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.only(
                                                  left: 12, right: 8),
                                              child: Icon(
                                                Icons.business,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                            ),
                                            prefixIconConstraints:
                                                const BoxConstraints(
                                                    minWidth: 40,
                                                    minHeight: 40),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: AppColors.primary,
                                                width: 1.5,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'School is required';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      _buildInputField(
                                        controller: controller.fnameController,
                                        label: 'First Name',
                                        icon: Icons.person,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'First name is required';
                                          }
                                          return null;
                                        },
                                      ),
                                      _buildInputField(
                                        controller: controller.mnameController,
                                        label: 'Middle Name',
                                        icon: Icons.person,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Middle name is required';
                                          }
                                          return null;
                                        },
                                      ),
                                      Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: TextFormField(
                                          controller:
                                              controller.lnameController,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Last Name',
                                            floatingLabelBehavior:
                                                FloatingLabelBehavior.auto,
                                            labelStyle: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            floatingLabelStyle: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 15,
                                            ),
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.only(
                                                  left: 12, right: 8),
                                              child: Icon(
                                                Icons.person,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                            ),
                                            prefixIconConstraints:
                                                const BoxConstraints(
                                                    minWidth: 40,
                                                    minHeight: 40),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: AppColors.primary,
                                                width: 1.5,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Last name is required';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 14),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors
                                                .white, // Light peach color from screenshot
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: FormField<String>(
                                            validator: (value) {
                                              if (controller.mediumController
                                                  .text.isEmpty) {
                                                return 'Medium is required';
                                              }
                                              return null;
                                            },
                                            builder:
                                                (FormFieldState<String> state) {
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(left: 16),
                                                        child: Icon(
                                                          Icons.language,
                                                          color:
                                                              AppColors.primary,
                                                          size: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child:
                                                            DropdownButtonHideUnderline(
                                                          child: DropdownButton<
                                                              String>(
                                                            value: controller
                                                                    .mediumController
                                                                    .text
                                                                    .isEmpty
                                                                ? null
                                                                : controller
                                                                    .mediumController
                                                                    .text,
                                                            hint: Text(
                                                              'Medium',
                                                              style: TextStyle(
                                                                color: AppColors
                                                                    .textSecondary,
                                                                fontSize: 15,
                                                              ),
                                                            ),
                                                            icon: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      right:
                                                                          16),
                                                              child: Icon(
                                                                Icons
                                                                    .arrow_drop_down_circle,
                                                                color: AppColors
                                                                    .primary,
                                                                size: 24,
                                                              ),
                                                            ),
                                                            isExpanded: true,
                                                            dropdownColor:
                                                                Colors.white,
                                                            style:
                                                                const TextStyle(
                                                              color: AppColors
                                                                  .textPrimary,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                            items: [
                                                              DropdownMenuItem(
                                                                value:
                                                                    'English',
                                                                child: Text(
                                                                    'English'),
                                                              ),
                                                              DropdownMenuItem(
                                                                value:
                                                                    'Gujarati',
                                                                child: Text(
                                                                    'Gujarati'),
                                                              ),
                                                            ],
                                                            onChanged: (value) {
                                                              if (value !=
                                                                  null) {
                                                                setState(() {
                                                                  controller
                                                                      .mediumController
                                                                      .text = value;
                                                                  state.didChange(
                                                                      value);
                                                                });
                                                              }
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (state.hasError)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 16, top: 4),
                                                      child: Text(
                                                        state.errorText!,
                                                        style: TextStyle(
                                                          color:
                                                              Colors.red[700],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  isActive: controller.currentStep >= 1,
                                ),
                                Step(
                                  title: const Text('Contact Details'),
                                  content: Column(
                                    children: [
                                      Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: TextFormField(
                                          controller:
                                              controller.contactController,
                                          keyboardType: TextInputType.phone,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            labelText:
                                                'Student Contact (Optional)',
                                            floatingLabelBehavior:
                                                FloatingLabelBehavior.never,
                                            labelStyle: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.only(
                                                  left: 12, right: 8),
                                              child: const Icon(
                                                Icons.phone,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                            ),
                                            prefixIconConstraints:
                                                const BoxConstraints(
                                                    minWidth: 40,
                                                    minHeight: 40),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: AppColors.primary,
                                                width: 1.5,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value != null &&
                                                value.isNotEmpty) {
                                              if (value.length != 10) {
                                                return 'Contact number must be 10 digits';
                                              }
                                              if (!RegExp(r'^[0-9]+$')
                                                  .hasMatch(value)) {
                                                return 'Only numbers are allowed';
                                              }
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                            // Remove any non-digit characters
                                            final digitsOnly = value.replaceAll(
                                                RegExp(r'[^0-9]'), '');
                                            // Limit to 10 digits
                                            if (digitsOnly.length > 10) {
                                              controller
                                                      .contactController.text =
                                                  digitsOnly.substring(0, 10);
                                              controller.contactController
                                                      .selection =
                                                  TextSelection.fromPosition(
                                                      TextPosition(
                                                          offset: controller
                                                              .contactController
                                                              .text
                                                              .length));
                                            }
                                          },
                                        ),
                                      ),
                                      Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: TextFormField(
                                          controller: controller
                                              .parentContactController,
                                          keyboardType: TextInputType.phone,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Parent Contact',
                                            floatingLabelBehavior:
                                                FloatingLabelBehavior.never,
                                            labelStyle: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            prefixIcon: Container(
                                              margin: const EdgeInsets.only(
                                                  left: 12, right: 8),
                                              child: const Icon(
                                                Icons.phone,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                            ),
                                            prefixIconConstraints:
                                                const BoxConstraints(
                                                    minWidth: 40,
                                                    minHeight: 40),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: AppColors.primary,
                                                width: 1.5,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Parent contact is required';
                                            }
                                            if (value.length != 10) {
                                              return 'Contact number must be 10 digits';
                                            }
                                            if (!RegExp(r'^[0-9]+$')
                                                .hasMatch(value)) {
                                              return 'Only numbers are allowed';
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                            // Remove any non-digit characters
                                            final digitsOnly = value.replaceAll(
                                                RegExp(r'[^0-9]'), '');
                                            // Limit to 10 digits
                                            if (digitsOnly.length > 10) {
                                              controller.parentContactController
                                                      .text =
                                                  digitsOnly.substring(0, 10);
                                              controller.parentContactController
                                                      .selection =
                                                  TextSelection.fromPosition(
                                                      TextPosition(
                                                          offset: controller
                                                              .parentContactController
                                                              .text
                                                              .length));
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      GestureDetector(
                                        onTap: pickImage,
                                        child: Container(
                                          height: 200,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                                color: AppColors.textSecondary
                                                    .withOpacity(0.3)),
                                          ),
                                          child: controller.studentImage != null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: Image.file(
                                                      controller.studentImage!,
                                                      fit: BoxFit.cover),
                                                )
                                              : Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.add_a_photo,
                                                      size: 48,
                                                      color: AppColors.primary,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Add Student Photo (Optional)',
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .textSecondary,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  isActive: controller.currentStep >= 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (controller.isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Adding Student...',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onTap: onTap,
        cursorColor: AppColors.secondary,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          focusColor: AppColors.secondary,
          hoverColor: AppColors.secondary,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: const TextStyle(
            color: AppColors.primary,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.secondary,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
          errorStyle: TextStyle(
            color: AppColors.error,
            fontSize: 12,
          ),
        ),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

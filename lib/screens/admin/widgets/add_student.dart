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
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Add Student'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.primaryGradient,
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.glassBorder.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.primaryGradient,
              ),
            ),
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
                  child: ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) => Stepper(
                      type: StepperType.vertical,
                      currentStep: controller.currentStep,
                      onStepContinue: () {
                        if (controller.currentStep < 2) {
                          if (_validateCurrentStep()) {
                            controller.nextStep();
                          }
                        } else {
                          if (_validateCurrentStep()) {
                            controller.submitForm();
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
                                      borderRadius: BorderRadius.circular(8),
                                    ),
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
                                      foregroundColor: Colors.white,
                                      side:
                                          const BorderSide(color: Colors.white),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
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
                                padding: const EdgeInsets.only(bottom: 16),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.glassBackground
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.glassBorder
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          popupMenuTheme: PopupMenuThemeData(
                                            color: AppColors.glassBackground,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          dropdownMenuTheme:
                                              DropdownMenuThemeData(
                                            textStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                            menuStyle: MenuStyle(
                                              backgroundColor:
                                                  MaterialStateProperty.all(
                                                AppColors.glassBackground,
                                              ),
                                              shape: MaterialStateProperty.all(
                                                RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          value: controller
                                                  .studentClassController
                                                  .text
                                                  .isEmpty
                                              ? null
                                              : controller
                                                  .studentClassController.text,
                                          dropdownColor:
                                              AppColors.glassBackground,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Class',
                                            labelStyle: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              fontSize: 15,
                                            ),
                                            floatingLabelStyle: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.class_,
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              size: 20,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: AppColors.glassBorder
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: AppColors.glassBorder
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.white,
                                                width: 1.5,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                          ),
                                          items: [
                                            DropdownMenuItem(
                                              value: '7',
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(8),
                                                  ),
                                                ),
                                                child: const Text(
                                                  '7th Class',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: '8',
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(8),
                                                  ),
                                                ),
                                                child: const Text(
                                                  '8th Class',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: '9',
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(8),
                                                  ),
                                                ),
                                                child: const Text(
                                                  '9th Class',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: '10',
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(8),
                                                  ),
                                                ),
                                                child: const Text(
                                                  '10th Class',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            if (value != null) {
                                              controller.studentClassController
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
                                          icon: Icon(
                                            Icons.arrow_drop_down,
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            size: 28,
                                          ),
                                          isExpanded: true,
                                          menuMaxHeight: 300,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: FutureBuilder<List<Subject>>(
                                  future: SubjectController().getSubjects(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: 10, sigmaY: 10),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppColors.glassBackground
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.glassBorder
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    if (snapshot.hasError) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: 10, sigmaY: 10),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppColors.glassBackground
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.error
                                                    .withOpacity(0.5),
                                              ),
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
                                                      color: Colors.white
                                                          .withOpacity(0.9),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    setState(
                                                        () {}); // Retry loading
                                                  },
                                                  child: const Text(
                                                    'Retry',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    final subjects = snapshot.data ?? [];

                                    if (subjects.isEmpty) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: 10, sigmaY: 10),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppColors.glassBackground
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.glassBorder
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                  size: 24,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    'No subjects available. Please add subjects first.',
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.9),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Select Subjects',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                                sigmaX: 10, sigmaY: 10),
                                            child: Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: AppColors.glassBackground
                                                    .withOpacity(0.3),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: AppColors.glassBorder
                                                      .withOpacity(0.5),
                                                ),
                                              ),
                                              child: Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children:
                                                    subjects.map((subject) {
                                                  final isSelected = controller
                                                      .selectedSubjects
                                                      .contains(subject.id);

                                                  return InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        if (isSelected) {
                                                          controller
                                                              .selectedSubjects
                                                              .remove(
                                                                  subject.id);
                                                        } else {
                                                          controller
                                                              .selectedSubjects
                                                              .add(subject.id);
                                                        }
                                                        controller
                                                            .notifyListeners();
                                                      });
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 16,
                                                        vertical: 8,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: isSelected
                                                            ? null
                                                            : AppColors
                                                                .glassBackground
                                                                .withOpacity(
                                                                    0.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        border: Border.all(
                                                          color: isSelected
                                                              ? AppColors
                                                                  .primary
                                                              : AppColors
                                                                  .glassBorder
                                                                  .withOpacity(
                                                                      0.5),
                                                          width: isSelected
                                                              ? 1.5
                                                              : 1,
                                                        ),
                                                        boxShadow: isSelected
                                                            ? [
                                                                BoxShadow(
                                                                  color: AppColors
                                                                      .primary
                                                                      .withOpacity(
                                                                          0.2),
                                                                  blurRadius: 8,
                                                                  offset:
                                                                      const Offset(
                                                                          0, 2),
                                                                ),
                                                              ]
                                                            : null,
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            isSelected
                                                                ? Icons
                                                                    .check_circle
                                                                : Icons
                                                                    .circle_outlined,
                                                            color: isSelected
                                                                ? Colors.white
                                                                : Colors.white
                                                                    .withOpacity(
                                                                        0.7),
                                                            size: 16,
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Text(
                                                            subject.name,
                                                            style: TextStyle(
                                                              color: isSelected
                                                                  ? Colors.white
                                                                  : Colors.white
                                                                      .withOpacity(
                                                                          0.9),
                                                              fontWeight: isSelected
                                                                  ? FontWeight
                                                                      .w600
                                                                  : FontWeight
                                                                      .normal,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInputField(
                                      controller: controller.feePaidController,
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
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildInputField(
                                      controller: controller.feeTotalController,
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
                                  ),
                                ],
                              ),
                              _buildInputField(
                                controller: controller.birthdateController,
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
                                    controller.birthdateController.text =
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
                                controller: controller.addressController,
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
                                padding: const EdgeInsets.only(bottom: 14),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.glassBackground
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.glassBorder
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          popupMenuTheme: PopupMenuThemeData(
                                            color: AppColors.glassBackground,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          dropdownMenuTheme:
                                              DropdownMenuThemeData(
                                            textStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                            menuStyle: MenuStyle(
                                              backgroundColor:
                                                  MaterialStateProperty.all(
                                                AppColors.glassBackground,
                                              ),
                                              shape: MaterialStateProperty.all(
                                                RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          value: controller
                                                  .boardController.text.isEmpty
                                              ? null
                                              : controller.boardController.text,
                                          dropdownColor:
                                              AppColors.glassBackground,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Board',
                                            labelStyle: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              fontSize: 15,
                                            ),
                                            floatingLabelStyle: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.school,
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              size: 20,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: AppColors.glassBorder
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: AppColors.glassBorder
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.white,
                                                width: 1.5,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                          ),
                                          items: [
                                            DropdownMenuItem(
                                              value: 'CBSE',
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(8),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'CBSE',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: 'GSEB',
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(8),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'GSEB',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            if (value != null) {
                                              controller.boardController.text =
                                                  value;
                                            }
                                          },
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Board is required';
                                            }
                                            return null;
                                          },
                                          icon: Icon(
                                            Icons.arrow_drop_down,
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            size: 28,
                                          ),
                                          isExpanded: true,
                                          menuMaxHeight: 300,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              _buildInputField(
                                controller: controller.schoolController,
                                label: 'School',
                                icon: Icons.business,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'School is required';
                                  }
                                  return null;
                                },
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInputField(
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
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildInputField(
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
                                  ),
                                ],
                              ),
                              _buildInputField(
                                controller: controller.lnameController,
                                label: 'Last Name',
                                icon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Last name is required';
                                  }
                                  return null;
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.glassBackground
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.glassBorder
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          popupMenuTheme: PopupMenuThemeData(
                                            color: AppColors.glassBackground,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          dropdownMenuTheme:
                                              DropdownMenuThemeData(
                                            textStyle: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                            menuStyle: MenuStyle(
                                              backgroundColor:
                                                  MaterialStateProperty.all(
                                                AppColors.glassBackground,
                                              ),
                                              shape: MaterialStateProperty.all(
                                                RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          value: controller
                                                  .mediumController.text.isEmpty
                                              ? null
                                              : controller
                                                  .mediumController.text,
                                          dropdownColor:
                                              AppColors.glassBackground,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Medium',
                                            labelStyle: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              fontSize: 15,
                                            ),
                                            floatingLabelStyle: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.language,
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              size: 20,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: AppColors.glassBorder
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: AppColors.glassBorder
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.white,
                                                width: 1.5,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                          ),
                                          items: [
                                            DropdownMenuItem(
                                              value: 'English',
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(8),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'English',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Gujarati',
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                    Radius.circular(8),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Gujarati',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            if (value != null) {
                                              controller.mediumController.text =
                                                  value;
                                            }
                                          },
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Medium is required';
                                            }
                                            return null;
                                          },
                                          icon: Icon(
                                            Icons.arrow_drop_down,
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            size: 28,
                                          ),
                                          isExpanded: true,
                                          menuMaxHeight: 300,
                                        ),
                                      ),
                                    ),
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
                              _buildInputField(
                                controller: controller.contactController,
                                label: 'Student Contact (Optional)',
                                icon: Icons.phone,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    if (value.length != 10) {
                                      return 'Contact number must be 10 digits';
                                    }
                                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                      return 'Only numbers are allowed';
                                    }
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  // Remove any non-digit characters
                                  final digitsOnly =
                                      value.replaceAll(RegExp(r'[^0-9]'), '');
                                  // Limit to 10 digits
                                  if (digitsOnly.length > 10) {
                                    controller.contactController.text =
                                        digitsOnly.substring(0, 10);
                                    controller.contactController.selection =
                                        TextSelection.fromPosition(
                                      TextPosition(
                                          offset: controller
                                              .contactController.text.length),
                                    );
                                  }
                                },
                              ),
                              _buildInputField(
                                controller: controller.parentContactController,
                                label: 'Parent Contact',
                                icon: Icons.phone,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Parent contact is required';
                                  }
                                  if (value.length != 10) {
                                    return 'Contact number must be 10 digits';
                                  }
                                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                    return 'Only numbers are allowed';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  // Remove any non-digit characters
                                  final digitsOnly =
                                      value.replaceAll(RegExp(r'[^0-9]'), '');
                                  // Limit to 10 digits
                                  if (digitsOnly.length > 10) {
                                    controller.parentContactController.text =
                                        digitsOnly.substring(0, 10);
                                    controller.parentContactController
                                        .selection = TextSelection.fromPosition(
                                      TextPosition(
                                          offset: controller
                                              .parentContactController
                                              .text
                                              .length),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: pickImage,
                                child: Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: controller.studentImage != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.file(
                                            controller.studentImage!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_a_photo,
                                              size: 48,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Add Student Photo (Optional)',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 16,
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
        if (controller.isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.glassBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.glassBorder,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Adding Student...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onTap: onTap,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: label,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              labelStyle: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              floatingLabelStyle: TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
              prefixIcon: Icon(
                icon,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.glassBorder.withOpacity(0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.glassBorder.withOpacity(0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: AppColors.glassBackground.withOpacity(0.3),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            validator: validator,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

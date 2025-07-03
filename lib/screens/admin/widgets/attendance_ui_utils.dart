import 'package:flutter/material.dart';

import '../../../core/themes/app_colors.dart';


class AttendanceUIUtils {
  static Widget circularProgressIndicator() {
    return CircularProgressIndicator(
      strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation<Color>(AppColors.scaffoldBackground),
    );
  }

  static Widget circularProgressIndicatorWithMessage(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndError(String message,
      String error) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
        SizedBox(height: 10),
        Text(
          error,
          style: TextStyle(color: Colors.red),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndSuccess(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndWarning(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndInfo(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndQuestion(
      String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndConfirmation(
      String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndCancel(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndDelete(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndEdit(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndView(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndAdd(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndSearch(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndFilter(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndSort(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndImport(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndExport(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndPrint(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndEmail(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndSMS(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndCall(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndMeeting(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndTask(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndNote(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndReminder(
      String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndEvent(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndDocument(
      String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndReport(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndDashboard(
      String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndSettings(
      String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndHelp(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndAbout(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndContact(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndFeedback(
      String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndSurvey(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndAnalysis(
      String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndPrediction(
      String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndRecommendation(
      String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndDecision(
      String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndAction(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndResult(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }

  static Widget circularProgressIndicatorWithMessageAndConclusion(
      String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        circularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          message,
          style: TextStyle(color: AppColors.scaffoldBackground),
        ),
      ],
    );
  }
}
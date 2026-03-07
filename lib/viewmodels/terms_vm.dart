import 'package:flutter/material.dart';
import 'package:kid_manager/models/terms_model.dart';
import 'package:kid_manager/repositories/terms_repository.dart';

class TermsVM extends ChangeNotifier {
  final TermsRepository _repository;

  TermsVM(this._repository);

  TermsModel? terms;
  bool isLoading = false;

  Future<void> loadTerms() async {
    isLoading = true;
    notifyListeners();

    terms = await _repository.getTerms();

    isLoading = false;
    notifyListeners();
  }
}

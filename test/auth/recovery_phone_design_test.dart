import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad/presentation/widgets/recovery_widgets/recovery_phone_form.dart';
import 'package:sanad/presentation/widgets/signup_screen_widgets/signup_steps_form.dart';
import '../support/laravel_auth_fixture.dart';

void main() {
  for (final language in ['en', 'ar']) {
    testWidgets(
      'independent recovery phone preserves signup geometry and text styles in $language',
      (tester) async {
        final fixture = LaravelAuthFixture();
        addTearDown(fixture.close);
        final controllers = List.generate(9, (_) => TextEditingController());
        addTearDown(() {
          for (final controller in controllers) {
            controller.dispose();
          }
        });
        await tester.binding.setSurfaceSize(const Size(780, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        void noop() {}
        const signupPane = ValueKey('signup-design-pane');
        const recoveryPane = ValueKey('recovery-design-pane');
        await tester.pumpWidget(
          fixture.app(
            Scaffold(
              body: Row(
                textDirection: TextDirection.ltr,
                children: [
                  SizedBox(
                    key: signupPane,
                    width: 390,
                    child: SignupStepsForm(
                      regStep: 4,
                      isArabic: language == 'ar',
                      onStepNext: noop,
                      onStepBack: noop,
                      first: controllers[0],
                      last: controllers[1],
                      username: controllers[2],
                      email: controllers[3],
                      phone: controllers[4],
                      address: controllers[5],
                      password: controllers[6],
                      confirm: controllers[7],
                      selectedCountryCode: '+20',
                      expectedPhoneLength: 10,
                      onToggleObscure: noop,
                      onToggleConfirm: noop,
                      onGovTap: noop,
                      onCountryTap: noop,
                      onCountryCodeTap: noop,
                      hasUpper: false,
                      hasNum: false,
                      hasSpec: false,
                      hasMinLen: false,
                      passMatch: false,
                      obscure: true,
                      obscureConfirm: true,
                    ),
                  ),
                  SizedBox(
                    key: recoveryPane,
                    width: 390,
                    child: RecoveryPhoneForm(
                      isArabic: language == 'ar',
                      phone: controllers[8],
                      countryCode: '+20',
                      expectedPhoneLength: 10,
                      onBack: noop,
                      onNext: noop,
                      onCountryCodeTap: noop,
                    ),
                  ),
                ],
              ),
            ),
            language: language,
          ),
        );
        await tester.pumpAndSettle();
        Rect relativeRect(Finder item, Key pane) =>
            tester.getRect(item).shift(-tester.getTopLeft(find.byKey(pane)));
        expect(
          relativeRect(
            find.byKey(const ValueKey('recovery-phone-field')),
            recoveryPane,
          ),
          relativeRect(
            find.byKey(const ValueKey('signup-phone-field')),
            signupPane,
          ),
        );
        expect(
          relativeRect(
            find.byKey(const ValueKey('recovery-phone-next')),
            recoveryPane,
          ),
          relativeRect(find.byKey(const ValueKey('signup-submit')), signupPane),
        );
        for (final text in [
          language == 'ar' ? 'رقم الهاتف' : 'Phone number',
          language == 'ar'
              ? 'يرجى إكمال البيانات للمتابعة'
              : 'Please complete the details to continue',
          language == 'ar' ? 'التالي' : 'Next',
          '+20',
        ]) {
          final original = find
              .descendant(of: find.byKey(signupPane), matching: find.text(text))
              .first;
          final recovery = find
              .descendant(
                of: find.byKey(recoveryPane),
                matching: find.text(text),
              )
              .first;
          expect(
            tester.widget<Text>(recovery).style,
            tester.widget<Text>(original).style,
          );
          expect(
            relativeRect(recovery, recoveryPane),
            relativeRect(original, signupPane),
          );
        }
        await tester.enterText(
          find.byKey(const ValueKey('signup-phone-field')),
          '012',
        );
        await tester.enterText(
          find.byKey(const ValueKey('recovery-phone-field')),
          '012',
        );
        expect(controllers[4].text, isEmpty);
        expect(controllers[8].text, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

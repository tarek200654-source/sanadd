import '../../domain/models/caregiver_link.dart';
import 'app_localizations.dart';

extension CaregivingLocalizations on AppLocalizations {
  String get caregiversTitle => isArabic ? 'مقدمو الرعاية' : 'Caregivers';
  String get caregivingTitle => isArabic ? 'تقديم الرعاية' : 'Caregiving';
  String get linkingEntryHint => isArabic
      ? 'الدعوات والعلاقات المرتبطة بحسابك'
      : 'Manage invitations and your connections';
  String get linkHistory => isArabic ? 'سجل العلاقات' : 'Relationship history';
  String get currentLinks =>
      isArabic ? 'العلاقات الحالية' : 'Current connections';
  String slotsSummary(int occupied) => isArabic
      ? '$occupied من ٣ أماكن مشغولة'
      : '$occupied of 3 slots occupied';
  String get availableSlot => isArabic ? 'مكان متاح' : 'Available slot';
  String get occupiedSlot => isArabic ? 'مكان مشغول' : 'Occupied slot';
  String get findCaregiver =>
      isArabic ? 'ابحث عن مقدم رعاية' : 'Find a caregiver';
  String get exactUsernameHint => isArabic
      ? 'أدخل اسم المستخدم كاملًا لتأكيد مقدم الرعاية.'
      : 'Enter the exact username to confirm your caregiver.';
  String get caregiverUsername =>
      isArabic ? 'اسم مستخدم مقدم الرعاية' : 'Caregiver username';
  String get lookUpCaregiver => isArabic ? 'بحث' : 'Look up';
  String get sendInvitation => isArabic ? 'إرسال دعوة' : 'Send invitation';
  String get confirmCaregiver => isArabic
      ? 'تأكد من مقدم الرعاية قبل إرسال الدعوة'
      : 'Confirm your caregiver before sending';
  String get noConnections =>
      isArabic ? 'لا توجد علاقات حالية' : 'No current connections';
  String get noHistory =>
      isArabic ? 'لا يوجد سجل علاقات بعد' : 'No relationship history yet';
  String get caregiverEmptyHint => isArabic
      ? 'ستظهر دعوات المرضى هنا عند فتح هذا القسم أو تحديثه.'
      : 'Patient invitations appear here when you open or refresh this section.';
  String get patientEmptyHint => isArabic
      ? 'ابحث باسم المستخدم لإرسال دعوة إلى مقدم رعاية.'
      : 'Find a caregiver by username to send an invitation.';
  String get refreshLinks => isArabic ? 'تحديث' : 'Refresh';
  String get moreLinks => isArabic ? 'عرض المزيد' : 'Load more';
  String get relationshipUpdated =>
      isArabic ? 'تم تحديث العلاقة.' : 'Connection updated.';
  String get reconcileLinks => isArabic
      ? 'حدّث القائمة للتحقق من نتيجة الطلب قبل المحاولة مجددًا.'
      : 'Refresh to check the request outcome before trying again.';
  String get revokePatientTitle =>
      isArabic ? 'إزالة مقدم الرعاية؟' : 'Remove caregiver?';
  String get revokeCaregiverTitle =>
      isArabic ? 'مغادرة العلاقة؟' : 'Leave connection?';
  String get revokeExplanation => isArabic
      ? 'ستنتهي صلاحية الوصول المرتبطة بهذه العلاقة. يلزم إرسال دعوة جديدة للربط مجددًا.'
      : 'Access through this connection will end. A new invitation is needed to connect again.';
  String get keepConnection => isArabic ? 'إبقاء العلاقة' : 'Keep connection';
  String get invitedOn => isArabic ? 'تاريخ الدعوة' : 'Invited';
  String get acceptedOn => isArabic ? 'تاريخ القبول' : 'Accepted';
  String get endedOn => isArabic ? 'تاريخ الانتهاء' : 'Ended';
  String linkState(CaregiverLinkStatus status) => switch (status) {
    CaregiverLinkStatus.pending => isArabic ? 'قيد الانتظار' : 'Pending',
    CaregiverLinkStatus.active => isArabic ? 'نشطة' : 'Active',
    CaregiverLinkStatus.declined => isArabic ? 'مرفوضة' : 'Declined',
    CaregiverLinkStatus.revoked => isArabic ? 'منتهية' : 'Revoked',
    CaregiverLinkStatus.cancelled => isArabic ? 'ملغاة' : 'Cancelled',
  };
  String linkAction(String action, {required bool patient}) => switch (action) {
    'accept' => isArabic ? 'قبول' : 'Accept',
    'decline' => isArabic ? 'رفض' : 'Decline',
    'cancel' => isArabic ? 'إلغاء الدعوة' : 'Cancel invitation',
    _ =>
      patient
          ? (isArabic ? 'إزالة مقدم الرعاية' : 'Remove caregiver')
          : (isArabic ? 'مغادرة العلاقة' : 'Leave connection'),
  };
  String linkError(String code) => switch (code) {
    'caregiver-not-found' =>
      isArabic
          ? 'لم يتم العثور على مقدم رعاية بهذا الاسم.'
          : 'No caregiver found with that exact username.',
    'duplicate-live-relationship' =>
      isArabic
          ? 'توجد دعوة معلقة أو علاقة نشطة مع مقدم الرعاية هذا.'
          : 'You already have a pending invitation or active connection with this caregiver.',
    'caregiver-slots-full' =>
      isArabic
          ? 'الأماكن الثلاثة مشغولة. ألغِ دعوة معلقة أو أنهِ علاقة لإتاحة مكان.'
          : 'All three slots are occupied. Cancel an invitation or remove a connection to free a slot.',
    'invalid-relationship-state' || 'relationship-not-found' =>
      isArabic
          ? 'تغيرت هذه العلاقة. راجع القائمة المحدثة.'
          : 'This connection has changed. Check the refreshed list.',
    'too-many-requests' =>
      isArabic
          ? 'طلبات كثيرة. انتظر قليلًا ثم حاول مجددًا.'
          : 'Too many requests. Wait a moment before trying again.',
    'network-request-failed' || 'request-timeout' =>
      isArabic
          ? 'تعذر الاتصال. تحقق من الإنترنت وحدّث القائمة.'
          : 'Could not connect. Check your network and refresh.',
    'validation-failed' || 'invalid-username' => invalidUsernameMessage,
    'forbidden' =>
      isArabic
          ? 'حسابك غير مخوّل لتنفيذ هذا الإجراء.'
          : 'Your account cannot perform this action.',
    'session-changed' || 'unauthenticated' || 'token-expired' =>
      isArabic
          ? 'تغيرت الجلسة. أعد فتح القسم من حسابك الحالي.'
          : 'Your session changed. Reopen this section from your current account.',
    _ =>
      isArabic
          ? 'تعذر تحميل العلاقات. حاول التحديث.'
          : 'Could not load connections. Try refreshing.',
  };
}

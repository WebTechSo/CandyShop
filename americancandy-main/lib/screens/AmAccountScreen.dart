import 'package:flutter/material.dart';
import 'dart:async';
import 'package:nb_utils/nb_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:american_sweets/main.dart';
import 'package:american_sweets/data/repositories/authentication_repository.dart';
import 'package:american_sweets/screens/AmAdressManagerScreen.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmImages.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/utils/AmWidget.dart';
import 'AmOrderListScreen.dart';
import 'package:american_sweets/screens/AmProfileFragment.dart';
import 'package:american_sweets/screens/AmSignIn.dart';

class AmAccountScreen extends StatefulWidget {
  static String tag = '/AmAccountScreen';

  @override
  AmAccountScreenState createState() => AmAccountScreenState();
}

class AmAccountScreenState extends State<AmAccountScreen> {
  var firstNameCont = TextEditingController();
  String _userName = '';
  String? _userEmail;
  String? _profilePicture;
  bool _isLoggedIn = false;
  bool _isEmailVerified = false;
  Timer? _verifyTimer;
  int _verifySecondsRemaining = 0;
  static const String _verifyCooldownKey = 'verify_cooldown_until_ms';
  static const String _cachedUserNameKey = 'cached_user_name';
  static const String _cachedProfilePictureKey = 'cached_profile_picture';

  String _userScopedKey(String base, String uid) => '${base}_$uid';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _isLoggedIn = true;
      _userEmail = user.email;
      _isEmailVerified = user.emailVerified;

      final cachedName =
          getStringAsync(_userScopedKey(_cachedUserNameKey, user.uid)).trim();
      final cachedPic =
          getStringAsync(_userScopedKey(_cachedProfilePictureKey, user.uid))
              .trim();

      _userName = cachedName.isNotEmpty
          ? cachedName
          : ((user.displayName ?? user.email ?? '').toString().trim());
      _profilePicture = cachedPic.isNotEmpty ? cachedPic : null;
    } else {
      _isLoggedIn = false;
      _userName = "Guest User";
      _profilePicture = null;
    }
    _loadUserData();
    _restoreVerifyCooldown();
  }

  @override
  void dispose() {
    _verifyTimer?.cancel();
    super.dispose();
  }

  void _startVerifyCooldown(int seconds) {
    _verifyTimer?.cancel();
    final until =
        DateTime.now().add(Duration(seconds: seconds)).millisecondsSinceEpoch;
    setValue(_verifyCooldownKey, until);
    setState(() {
      _verifySecondsRemaining = seconds;
    });
    _verifyTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_verifySecondsRemaining <= 1) {
        t.cancel();
        setState(() {
          _verifySecondsRemaining = 0;
        });
        removeKey(_verifyCooldownKey);
        return;
      }
      setState(() {
        _verifySecondsRemaining -= 1;
      });
    });
  }

  void _restoreVerifyCooldown() {
    final untilMs = getIntAsync(_verifyCooldownKey, defaultValue: 0);
    if (untilMs <= 0) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final remainingMs = untilMs - nowMs;
    if (remainingMs <= 0) {
      removeKey(_verifyCooldownKey);
      return;
    }
    final seconds = (remainingMs / 1000).ceil();
    _startVerifyCooldown(seconds);
  }

  String _formatRemaining(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final scopedNameKey = _userScopedKey(_cachedUserNameKey, user.uid);
      final scopedPicKey = _userScopedKey(_cachedProfilePictureKey, user.uid);
      setState(() {
        _isLoggedIn = true;
        _userEmail = user.email;
        _isEmailVerified = user.emailVerified;
      });

      // Reload user to get latest verification status
      await user.reload();
      if (mounted) {
        setState(() {
          _isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
        });
      }

      try {
        final doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();
        final data = doc.data();
        final name = data?['full_name'] ?? data?['fullName'] ?? data?['name'];
        final pic = data?['profile_picture'];

        setState(() {
          if (name != null && name.toString().trim().isNotEmpty) {
            _userName = name.toString();
            setValue(scopedNameKey, _userName);
          }
          final picStr = (pic ?? '').toString().trim();
          if (picStr.isNotEmpty) {
            _profilePicture = picStr;
            setValue(scopedPicKey, _profilePicture);
          } else {
            _profilePicture = null;
            removeKey(scopedPicKey);
          }
        });
      } catch (e) {
        print("Error fetching user data: $e");
      }
    } else {
      setState(() {
        _isLoggedIn = false;
        _userName = "Guest User";
        _profilePicture = null;
      });
    }
  }

  Future<void> _sendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        await AuthenticationRepository.instance.sendEmailVerification();
        toast("Verification email sent to ${user.email}");
        if (mounted) _startVerifyCooldown(120);
      } catch (e) {
        toast(e.toString());
      }
    }
  }

  void _showBlockingLoader(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                16.width,
                Expanded(child: Text(message, style: primaryTextStyle())),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteQueryInBatches(Query query) async {
    while (true) {
      final snap = await query.limit(400).get();
      if (snap.docs.isEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _clearLocalUserCache(String uid) async {
    removeKey(_userScopedKey(_cachedUserNameKey, uid));
    removeKey(_userScopedKey(_cachedProfilePictureKey, uid));
    removeKey(_verifyCooldownKey);
  }

  Future<void> _deleteUserData(
      {required String uid, required bool includeUserDoc}) async {
    try {
      await _deleteQueryInBatches(
        FirebaseFirestore.instance
            .collection('cart_product')
            .where('user_id', isEqualTo: uid),
      );
    } catch (_) {}
    try {
      await _deleteQueryInBatches(
        FirebaseFirestore.instance
            .collection('UserWishlist')
            .where('user_id', isEqualTo: uid),
      );
    } catch (_) {}
    try {
      await _deleteQueryInBatches(
        FirebaseFirestore.instance
            .collection('Addresses')
            .where('user_id', isEqualTo: uid),
      );
    } catch (_) {}
    try {
      await _deleteQueryInBatches(
        FirebaseFirestore.instance
            .collection('Notifications')
            .where('userId', isEqualTo: uid),
      );
    } catch (_) {}
    try {
      await FirebaseFirestore.instance.collection('Settings').doc(uid).delete();
    } catch (_) {}
    if (includeUserDoc) {
      try {
        await FirebaseFirestore.instance.collection('Users').doc(uid).delete();
      } catch (_) {}
    }
    await _clearLocalUserCache(uid);
  }

  Future<String?> _promptPasswordForReauth(String email) async {
    final ctrl = TextEditingController();
    bool hidden = true;
    String? result;
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: Text('Confirm Password', style: boldTextStyle()),
            content: TextField(
              controller: ctrl,
              obscureText: hidden,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(hidden ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setStateDialog(() => hidden = !hidden),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  result = null;
                  Navigator.of(ctx).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final v = ctrl.text.trim();
                  result = v.isEmpty ? null : v;
                  Navigator.of(ctx).pop();
                },
                child: const Text('Continue'),
              ),
            ],
          );
        });
      },
    );
    ctrl.dispose();
    return result;
  }

  Future<bool> _confirmDialog({
    required String title,
    required String message,
    String positiveText = 'Yes',
    String negativeText = 'No',
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title, style: boldTextStyle()),
          content: Text(message, style: primaryTextStyle()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(negativeText),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(positiveText),
            ),
          ],
        );
      },
    );
    return res == true;
  }

  Future<void> _deleteDataFlow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      toast('Please sign in to delete data');
      return;
    }

    final confirmed = await _confirmDialog(
      title: 'Delete Data',
      message:
          'This will clear your saved cart items, wishlist, saved addresses, and in-app preferences on this device and in the cloud. Your account will stay active.',
      positiveText: 'Delete',
      negativeText: 'Cancel',
    );
    if (!confirmed) return;

    bool loaderShown = false;
    _showBlockingLoader('Deleting data...');
    loaderShown = true;
    try {
      await _deleteUserData(uid: user.uid, includeUserDoc: false);
      if (loaderShown && mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      toast('Data deleted');
    } catch (e) {
      if (loaderShown && mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      toast('Failed to delete data: $e');
    }
  }

  Future<void> _deleteAccountFlow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      toast('Please sign in to delete your account');
      return;
    }

    final confirmed = await _confirmDialog(
      title: 'Delete Account',
      message:
          'Deleting your account will remove your ability to sign in. We will attempt to delete your profile data, saved addresses, wishlist, cart items, and preferences.',
      positiveText: 'Delete',
      negativeText: 'Cancel',
    );
    if (!confirmed) return;

    bool loaderShown = false;
    _showBlockingLoader('Deleting account...');
    loaderShown = true;
    try {
      await _deleteUserData(uid: user.uid, includeUserDoc: true);

      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          final email = (user.email ?? '').trim();
          if (email.isEmpty) {
            rethrow;
          }
          final password = await _promptPasswordForReauth(email);
          if (password == null || password.isEmpty) {
            if (mounted) Navigator.of(context).pop();
            toast('Account deletion cancelled');
            return;
          }
          final cred =
              EmailAuthProvider.credential(email: email, password: password);
          await user.reauthenticateWithCredential(cred);
          await user.delete();
        } else {
          rethrow;
        }
      }

      if (loaderShown && mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      AmSignIn().launch(context, isNewTask: true);
      toast('Account deleted');
    } catch (e) {
      if (loaderShown && mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      toast('Failed to delete account: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(sh_lbl_account, style: boldTextStyle(size: 18)),
        iconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
        actions: [
          if (_isLoggedIn)
            IconButton(
              tooltip: 'Sign Out',
              icon: Icon(Icons.logout,
                  color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                AmSignIn().launch(context, isNewTask: true);
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          children: <Widget>[
            30.height,
            Card(
              semanticContainer: true,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              elevation: spacing_standard,
              margin: EdgeInsets.all(spacing_control),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100.0)),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: ClipOval(
                    child: (_profilePicture != null &&
                            _profilePicture!.trim().isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: _profilePicture!.trim(),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: sh_view_color,
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      sh_colorPrimary),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              ic_user,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            ic_user,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
            ),
            Text(_userName, style: boldTextStyle(size: 24)),
            if (_isLoggedIn && !_isEmailVerified)
              Container(
                margin: EdgeInsets.all(spacing_standard_new),
                padding: EdgeInsets.all(spacing_middle),
                decoration: BoxDecoration(
                    border: Border.all(color: sh_view_color, width: 1)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text("Please Verify you email",
                            style: primaryTextStyle()),
                        Image.asset(sh_radar, width: 30, height: 30).expand(),
                      ],
                    ),
                    16.height,
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _userEmail ?? "",
                            style: primaryTextStyle(),
                          ),
                        ),
                        16.width,
                        MaterialButton(
                          padding: EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 12.0),
                          child: text(
                              _verifySecondsRemaining > 0
                                  ? 'Verify Count Down ${_formatRemaining(_verifySecondsRemaining)}'
                                  : sh_lbl_verify_now,
                              fontSize: textSizeMedium,
                              fontFamily: fontMedium,
                              textColor: sh_white),
                          textColor: sh_white,
                          shape: RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(40.0)),
                          color: sh_colorPrimary,
                          onPressed: _verifySecondsRemaining > 0
                              ? null
                              : () => _sendVerificationEmail(),
                        )
                      ],
                    )
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.only(
                  left: spacing_standard_new,
                  bottom: spacing_standard_new,
                  right: spacing_standard_new),
              child: Column(
                children: <Widget>[
                  getRowItem("Edit Profile", callback: () {
                    AmProfileFragment().launch(context);
                  }),
                  SizedBox(height: spacing_standard_new),
                  getRowItem(sh_lbl_address_manager, callback: () {
                    AmAddressManagerScreen().launch(context);
                  }),
                  SizedBox(height: spacing_standard_new),
                  getRowItem(sh_lbl_my_order, callback: () {
                    AmOrderListScreen().launch(context);
                  }),
                  SizedBox(height: spacing_standard_new),
                  Observer(
                    builder: (_) => Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: sh_view_color, width: 1)),
                      padding: EdgeInsets.fromLTRB(
                          spacing_standard, 0, spacing_standard, 0),
                      child: Row(
                        children: [
                          Expanded(
                              child:
                                  Text('Dark Mode', style: primaryTextStyle())),
                          Switch(
                            value: appStore.isDarkModeOn,
                            activeColor: sh_colorPrimary,
                            onChanged: (v) async {
                              await appStore.toggleDarkMode(value: v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isLoggedIn) SizedBox(height: spacing_standard_new),
                  if (_isLoggedIn)
                    getRowItem(
                      'Delete Data',
                      callback: () {
                        _deleteDataFlow();
                      },
                    ),
                  if (_isLoggedIn) SizedBox(height: spacing_standard_new),
                  if (_isLoggedIn)
                    getRowItem(
                      'Delete Account',
                      callback: () {
                        _deleteAccountFlow();
                      },
                    ),
                  // SizedBox(height: spacing_standard_new),
                  // getRowItem(sh_lbl_my_offers, callback: () {
                  //   AmOffersScreen().launch(context);
                  // }),
                  // SizedBox(height: spacing_standard_new),
                  // getRowItem(sh_lbl_wish_list, callback: () {
                  //   finish(context);
                  // }),
                  // SizedBox(height: spacing_standard_new),
                  // getRowItem(sh_lbl_quick_pay_cards, callback: () {
                  //   AmQuickPayCardsScreen().launch(context);
                  // }),
                  // SizedBox(height: spacing_standard_new),
                  // getRowItem(sh_lbl_help_center),
                  // SizedBox(height: spacing_standard_new),
                  // getRowItem("Seed Database (Test)", callback: () async {
                  //   await SeederService().seedProducts();
                  //   toast("Database seeded with 10 random products");
                  // }),
                  SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    // height: double.infinity,
                    child: MaterialButton(
                      padding: EdgeInsets.all(spacing_standard),
                      child: text("Sign Out",
                          fontSize: textSizeNormal,
                          fontFamily: fontMedium,
                          textColor: sh_colorPrimary),
                      textColor: sh_white,
                      shape: RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(40.0),
                          side: BorderSide(color: sh_colorPrimary, width: 1)),
                      color: context.cardColor,
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        AmSignIn().launch(context, isNewTask: true);
                      },
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget getRowItem(String title, {VoidCallback? callback}) {
    return InkWell(
      onTap: callback,
      child: Container(
        decoration:
            BoxDecoration(border: Border.all(color: sh_view_color, width: 1)),
        padding:
            EdgeInsets.fromLTRB(spacing_standard, 0, spacing_control_half, 0),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(title, style: primaryTextStyle())),
            IconButton(
              icon: Icon(Icons.keyboard_arrow_right,
                  color: appStore.isDarkModeOn ? white : sh_textColorPrimary,
                  size: 24),
              onPressed: () {},
            )
          ],
        ),
      ),
    );
  }
}

import '../utils/path_provider.dart';

class LoginUiPage extends StatefulWidget {
  const LoginUiPage({super.key});

  @override
  State<LoginUiPage> createState() => _LoginUiPageState();
}

class _LoginUiPageState extends State<LoginUiPage> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();

  bool otpSent = false;
  bool isSendingOtp = false;
  bool isLoggingIn = false;
  String? otpError;
  String? mobileError;

  Future<void> showOtpNotification(String otp) async {
    print('[DEBUG] showOtpNotification invoked');
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'otp_channel',
          'OTP Notifications',
          channelDescription: 'Show OTP for Login',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    print('[DEBUG] Attempting to show notification');
    await flutterLocalNotificationsPlugin.show(
      0,
      'Your OTP Code',
      'Your login OTP is $otp',
      details,
    );
    print('[DEBUG] Notification requested.');
  }

  void sendOtp() async {
    print('[DEBUG] sendOtp called.');
    String mockOtp = "123456";
    print('[DEBUG] OTP to show in notification: $mockOtp');
    try {
      await showOtpNotification(mockOtp);
      print('[DEBUG] Notification showOtpNotification completed.');
    } catch (e) {
      print('[ERROR] showOtpNotification failed: $e');
    }
    setState(() {
      isSendingOtp = true;
      otpError = null;
    });
    await Future.delayed(Duration(seconds: 1)); // Simulate network
    setState(() {
      otpSent = true;
      isSendingOtp = false;
      print('[DEBUG] OTP sent, state updated.');
    });
  }

  void login() {
    setState(() {
      isLoggingIn = true;
      otpError = null;
    });
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        isLoggingIn = false;
        if (_otpController.text.trim() == "123456") {
          // Mock successful login
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Login Successful')));
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DashboardUiPage()),
          );
        } else {
          otpError = "Invalid OTP, please try again";
        }
      });
    });
  }

  String? validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return "Mobile number required";
    }
    if (!RegExp(r"^[6-9]\d{9}$").hasMatch(value)) {
      return "Enter valid 10 digit mobile number";
    }
    return null;
  }

  String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return "OTP required";
    }
    if (value.length != 6) {
      return "Enter 6 digit OTP";
    }
    return null;
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Login', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    hintText: 'Enter your mobile number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    errorText: mobileError,
                  ),
                  maxLength: 10,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: validateMobile,
                  onChanged: (_) {
                    setState(() {
                      mobileError = null;
                      otpSent = false;
                      _otpController.clear();
                    });
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  enabled: otpSent,
                  decoration: InputDecoration(
                    labelText: 'OTP',
                    hintText: 'Enter OTP',
                    prefixIcon: Icon(Icons.lock_outline),
                    errorText: otpError,
                  ),
                  maxLength: 6,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: otpSent ? validateOtp : (_) => null,
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: otpSent
                              ? colorScheme.secondaryContainer
                              : colorScheme.secondaryContainer,
                        ),
                        onPressed:
                            (isSendingOtp ||
                                !(_mobileController.text.length == 10 &&
                                    validateMobile(_mobileController.text) ==
                                        null))
                            ? null
                            : sendOtp,
                        child: isSendingOtp
                            ? SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(otpSent ? "Resend OTP" : "Send OTP"),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed:
                            otpSent &&
                                (_otpController.text.length == 6) &&
                                !isLoggingIn
                            ? login
                            : null,
                        child: isLoggingIn
                            ? SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text("Login"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

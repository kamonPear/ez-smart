import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/pages/main_dash.dart';
// TODO: นำเข้าหน้า MainScreen ของคุณ (แก้ path ให้ถูกต้อง)
// import 'package:your_project/main_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. เพิ่ม Controller สำหรับดึงข้อความจากช่องกรอกข้อมูล
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // 2. ตัวแปรเช็กสถานะการโหลด (เพื่อแสดงไอคอนหมุนๆ ตอนรอ API)
  bool _isLoading = false;

  // 3. ฟังก์ชันสำหรับล็อกอิน
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // เช็กว่ากรอกข้อมูลครบไหม
    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('กรุณากรอก User ID และ Password ให้ครบถ้วน');
      setState(() { _isLoading = false; });
      return;
    }

    try {
      // ⚠️ ข้อควรระวังเรื่อง IP Address:
      // - ถ้าใช้ Android Emulator ให้ใช้ 'http://10.0.2.2:8080/user/login'
      // - ถ้าเทสต์บนมือถือจริง ต้องใช้ IP ของคอมพิวเตอร์คุณ เช่น 'http://192.168.1.XX:8080/user/login'
      // - ในโค้ดนี้ สมมติว่ารัน Backend ไว้ที่พอร์ต 8080
      final url = Uri.parse('http://10.0.2.2:8080/login');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      // ถ้า API ตอบกลับมาว่า OK (200)
      if (response.statusCode == 200) {
        if (mounted) {
          // เปลี่ยนหน้าไป MainScreen ถาวร
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainScreen(), 
            ),
          );
        }
      } else {
        // ถ้ารหัสผิด หรือหาผู้ใช้ไม่เจอ จะดึงข้อความ error จาก Backend มาแสดง
        final responseData = jsonDecode(response.body);
        _showSnackBar(responseData['error'] ?? 'เข้าสู่ระบบไม่สำเร็จ');
      }
    } catch (e) {
      // กรณีเน็ตหลุด หรือ Backend ยังไม่เปิด
      _showSnackBar('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ฟังก์ชันช่วยแสดงแจ้งเตือน (SnackBar)
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    // ล้างค่าหน่วยความจำเมื่อปิดหน้านี้
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFC7AC77);
    final inputBgColor = const Color(0xFFE9E4D4);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF0F1621),
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minHeight: screenHeight),
          decoration: const BoxDecoration(
            color: Color(0xFF0F1621),
            image: DecorationImage(
              image: AssetImage('assets/images/Login.png'), 
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          child: IntrinsicHeight(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '12:30',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Icon(Icons.signal_cellular_alt, color: Colors.white, size: 18),
                            SizedBox(width: 5),
                            Icon(Icons.wifi, color: Colors.white, size: 18),
                            SizedBox(width: 5),
                            Icon(Icons.battery_full, color: Colors.white, size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _usernameController, // ผูก Controller
                          icon: Icons.person_outline,
                          hintText: 'User ID',
                          bgColor: inputBgColor,
                          primaryColor: primaryColor,
                          label: 'User ID',
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _passwordController, // ผูก Controller
                          icon: Icons.lock_outline,
                          hintText: '•••••••••',
                          bgColor: inputBgColor,
                          primaryColor: primaryColor,
                          label: 'Password',
                          isObscured: true,
                          suffixIcon: Icons.visibility_off_outlined,
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            'หากลืมรหัสผ่าน ให้ติดต่อหาเรา',
                            style: TextStyle(color: primaryColor, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        // ถ้า _isLoading เป็น true จะปิดการกดปุ่มชั่วคราว
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          disabledBackgroundColor: primaryColor.withOpacity(0.5),
                        ),
                        // เปลี่ยนข้อความเป็นไอคอนหมุนๆ ตอนกำลังโหลด
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text(
                                'LOGIN',
                                style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(Icons.star_purple500_outlined, color: primaryColor.withOpacity(0.5), size: 40),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ปรับแก้ Widget ให้รับค่า controller เข้ามาด้วย
  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    required Color bgColor,
    required Color primaryColor,
    required String label,
    bool isObscured = false,
    IconData? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                  ),
                ),
                child: Icon(icon, color: primaryColor, size: 28),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: controller, // เอา Controller มาใส่ตรงนี้
                    obscureText: isObscured,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: const TextStyle(color: Colors.black54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              if (suffixIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(suffixIcon, color: primaryColor, size: 24),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
// ตั้งค่า URL ของ backend ที่ใช้งานทั้งแอป
// กรณีรันบน Android emulator และ backend อยู่บนเครื่องเดียวกัน:
//   const String backendBaseUrl = 'http://10.0.2.2:8080';
// กรณี backend อยู่เครื่องอื่นในเครือข่ายเดียวกัน:
//   const String backendBaseUrl = 'http://<IP ของเครื่อง backend>:8080';
// เช่น 'http://192.168.1.100:8080'
// ⚠️ ชั่วคราว: ชี้กลับไปที่ backend local เพราะ production (Render) ยังไม่ได้
// redeploy โค้ดล่าสุด (ยังไม่มี field food_type ในผลลัพธ์ /api/foods) ต้อง
// เปลี่ยนกลับเป็น URL ของ Render ด้านล่างเมื่อ production redeploy เสร็จแล้ว
const String backendBaseUrl = 'http://10.0.2.2:8080';
// const String backendBaseUrl = 'https://ez-smartfarm-backn.onrender.com';

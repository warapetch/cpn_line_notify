# cpn_line_notify
🔷 Delphi Line Notify Component
🔷 เดลไฟ/เดลฟี่ ไลน์ โนมติฟาย คอมโนเนนท์
เป็นเครื่องมือ ที่ติดต่อ Line Message API ของ Line Notify
ผ่านอินเตอร์เน็ต เพื่อให้ง่ายต่อการใช้งาน
ใช้กับ เดลไฟ 10.3 (10.4 ไม่ได้ทดสอบ) 

post video at 13/09/2563
# Delphi  Line Notify Component
##  Delphi ติดต่อกับ Line Notify คอมโพเนนท์

วิดีโอ
    https://www.youtube.com/watch?v=sogtBs8igJo&ab_channel=WarapetchFreelanceProgramming

<!-- Corresponsing iframe markup copied from youtube embed of the corresponding video -->
<iframe width="560" height="315" src="https://www.youtube.com/watch?v=sogtBs8igJo/0.jpg" 
frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## ต้องมีความรู้พื้นฐาน
- Line Notify , Line Notify Message API
link https://notify-bot.line.me/doc/en/
- Delphi
- Internet , API

## เริ่มอย่างไร
1. ติดตั้งคอมโพเนนท์ wrpLineNotify_D10_33
2. เปิดโปรเจคเดลไฟ  รัน


## note
upload 20/10/2564



    #Delphi #SSL  Secure Sockets Layer (SSL) protocols
    .
    📌 ส่ง Line Notify ไม่ผ่าน 
    ⛔ Error > 'Could not load SSL library.'
    ใน indy > IdSSLIOHandlerSocketOpenSSL
    กำหนด SSLOptions.Method เป็น sslv23
    ** ตรงนี้ ต้องเป็นไปตามที่เซิฟเวอร์ที่เราทำงานด้วยกำหนด
    ..
    📌 ไฟล์ OpenSSL 2 ไฟล์นี้เท่านั้น
    ** Dynamic **
    .
    -- libeay32.dll
    -- ssleay32.dll
    .
    ไฟล์ SSL ต้องเป็นของปี 2562+
    ..
    📌 คำแนะนำของ เดลไฟ / เดลฟี่
    🔷 https://docwiki.embarcadero.com/RADStudio/Sydney/en/OpenSSL
    ..
    📌 ดาวน์ไฟล์ SSL สำหรับเดลไฟ
    🔷 openssl-1.0.2u 21/12/2562
    🔷 https://github.com/IndySockets/OpenSSL-Binaries
    ..
    📌 เวบดาวน์โหลด OpenSSL for Windows 
    ⛔ https://slproweb.com/products/Win32OpenSSL.html
    ..
    ⛔ https://www.filehorse.com/download-openssl-32/download/
    ..
    ติดตามข่าวสาร OpenSSL
    https://www.openssl.org/


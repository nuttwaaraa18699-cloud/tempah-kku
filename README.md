# Tempah.KKU — ระบบดูที่จอดรถว่าง มข.

เว็บแอปนี้เขียนด้วย Claude Design runtime (`support.js` โหลด React/Babel จาก CDN โดยไม่มี build step) เก็บล็อกอิน/ที่จอดโปรด/รายงานปัญหาไว้จริงผ่าน [Supabase](https://supabase.com) ส่วนจำนวนที่จอดว่างยังเป็นข้อมูลจำลอง (random walk) ที่รันฝั่ง client

## 1. สร้างฐานข้อมูล (Supabase, ฟรี)

1. สมัคร/ล็อกอินที่ [supabase.com](https://supabase.com) → **New project** (เลือก region Singapore ใกล้สุด)
2. ไปที่ **SQL Editor** → New query → วางเนื้อหาไฟล์ [`supabase/schema.sql`](supabase/schema.sql) ทั้งหมด → Run
3. ไปที่ **Project Settings → API** → คัดลอก **Project URL** และ **anon public key**
4. เปิดไฟล์ [`config.js`](config.js) แล้วแทนที่ค่า:
   ```js
   window.SUPABASE_URL = 'https://xxxxxxxx.supabase.co';
   window.SUPABASE_ANON_KEY = 'eyJhbGciOi...';
   ```
5. (แนะนำ) **Authentication → URL Configuration** → ใส่โดเมนที่จะ deploy จริง (ขั้นตอนที่ 3) ใน Site URL เพื่อให้ลิงก์ยืนยันอีเมล/รีเซ็ตรหัสผ่านกลับมาที่เว็บถูกที่

anon key เป็นคีย์สาธารณะ ปลอดภัยที่จะใส่ในโค้ด client — สิทธิ์การเข้าถึงจริงถูกจำกัดด้วย Row Level Security ใน `schema.sql`

## 2. ทดสอบในเครื่อง

ต้องรันผ่าน HTTP server (เปิดเป็น `file://` ตรงๆ จะโดน CORS บล็อก):

```powershell
# ตัวอย่างด้วย PowerShell (ไม่ต้องติดตั้งอะไรเพิ่ม)
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://localhost:8787/')
$listener.Start()
# ... (ดูสคริปต์เต็มที่ scratchpad/serve.ps1 ที่ใช้ตอน dev)
```

หรือใช้ VS Code extension "Live Server" / `python -m http.server` ถ้ามี Python

## 3. Deploy ขึ้น host (Cloudflare Pages, ฟรี)

ไม่มี build step — deploy ไฟล์ตรงๆ ได้เลย

1. สร้าง GitHub repo ใหม่ (เช่น `tempah-kku`) แล้ว push โค้ดนี้:
   ```bash
   git remote add origin https://github.com/<your-username>/tempah-kku.git
   git branch -M main
   git push -u origin main
   ```
2. ไปที่ [dash.cloudflare.com](https://dash.cloudflare.com) → **Workers & Pages → Create → Pages → Connect to Git**
3. เลือก repo `tempah-kku`
4. ตั้งค่า build:
   - **Build command**: (เว้นว่าง)
   - **Build output directory**: `/`
5. Deploy — จะได้ URL แบบ `tempah-kku.pages.dev` ฟรี ไม่จำกัด bandwidth

### ทางเลือกอื่น (ฟรีเหมือนกัน)
- **GitHub Pages**: repo Settings → Pages → Deploy from branch `main` / root
- **Netlify**: New site from Git → build command ว่าง → publish directory `/`
- **Vercel**: Import repo → Framework Preset "Other" → Output Directory `/`

## สิ่งที่ยังเป็นข้อมูลจำลอง

- จำนวนที่จอดว่างต่อจุด (`PLACES` ใน `Tempah KKU Light.dc.html`) — อัปเดตแบบสุ่มทุก 3 วินาที ไม่ได้มาจากเซนเซอร์จริง
- ถ้าต้องการเชื่อมข้อมูลจริงในอนาคต (กล้อง/เซนเซอร์นับที่จอด) จะต้องเพิ่มตารางใน Supabase + endpoint ที่รับข้อมูลจากอุปกรณ์ ค่อยทำเป็นเฟสถัดไป

## สิ่งที่ persist จริงแล้ว (ผ่าน Supabase)

- ล็อกอิน/สมัครสมาชิก/ลืมรหัสผ่าน (Supabase Auth)
- ที่จอดโปรด (ตาราง `favorites`)
- รายงานปัญหากล้อง/สถานะ (ตาราง `reports`)
- โหมด guest ("Continue as guest") ยังคงใช้งานได้แบบไม่ persist เหมือนเดิม

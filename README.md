

# ❄️ XSC003 - Roblox Antarctic Expedition Teleport Script

**XSC003** adalah skrip Lua yang dirancang untuk game **Roblox: Ekspedisi Antartika**. Skrip ini dapat dieksekusi menggunakan executor seperti **Arcues Executor** dan menyediakan fungsionalitas teleportasi **otomatis** dan **manual** melalui antarmuka pengguna bergaya **cyberpunk dengan efek glitch dinamis**.

---

## ✨ Fitur Utama

* **🔁 Auto Teleport**
  Teleportasi otomatis ke lokasi-lokasi penting dalam alur ekspedisi:
  *Camp 1 → Camp 2 → Camp 3 → Camp 4 → South Pole*.

* **🧭 Manual Teleport Interaktif**
  Pilih lokasi secara instan melalui dropdown UI yang rapi dan mudah digunakan.

* **⏱️ Pengaturan Waktu Auto Teleport**
  Atur *wait time* di setiap lokasi dan *delay* antar teleport langsung dari UI.

* **📋 Status Log Real-time**
  Menampilkan status skrip, hasil teleportasi, dan error secara langsung di UI.

* **🖥️ Antarmuka Pengguna (UI) Dinamis**

  * **Judul Glitch & RGB:** Berganti antara `ANTARCTIC TELEPORT` dan `ZEDLIST X ZXHELL`.
  * **Border Glitch:** Border UI beranimasi glitch secara acak.
  * **Tombol Interaktif:** Efek pulse saat idle dan highlight saat aktif.
  * **Minimize Mode:** Ubah UI menjadi ikon RGB `Z` kecil untuk menghemat layar.

* **🛡️ Penanganan Error Teleportasi Lanjutan**
  Fitur *anti-clipping*, *CanCollide off* sementara, dan retry otomatis saat teleport gagal.

---

## 🚀 Cara Menggunakan

1. **Dapatkan Executor**
   Gunakan executor Roblox terpercaya (misal: **Arcues Executor**).

2. **Salin Script**
   Salin seluruh isi file `main_teleport_script.lua`.

3. **Tempel & Eksekusi**
   Tempel skrip di executor Anda, lalu eksekusi.

4. **UI Akan Muncul**
   UI teleport akan langsung tampil di layar game Anda.

---

## ⚙️ Menggunakan Fitur Auto Teleport

* Klik tombol besar **`START AUTO TELEPORT`**.
* Skrip akan mulai teleportasi otomatis ke lokasi yang ditentukan.
* Klik ulang untuk **menghentikan** siklus (tombol akan berubah menjadi `STOP AUTO TELEPORT`).
* Sesuaikan:

  * `Wait Time (Auto)` = waktu diam di tiap titik.
  * `Delay Between Points` = jeda antar teleport.
* Klik **`APPLY SETTINGS`** untuk menyimpan pengaturan.

---

## 🕹️ Menggunakan Fitur Manual Teleport

1. Klik tombol **`Select Location...`** di bagian "MANUAL TELEPORT".
2. Pilih lokasi dari daftar dropdown.
3. Klik tombol **`TELEPORT`** untuk langsung berpindah ke lokasi terpilih.

---

## 📑 Memantau Status Log

* Bagian **`STATUS LOG`** akan mencatat:

  * Hasil teleportasi.
  * Status auto-teleport.
  * Error dan peringatan.
* Log diperbarui secara real-time dan dibersihkan otomatis setiap **60 detik**.

---

## 📍 Lokasi Teleportasi

Skrip ini mencakup lokasi-lokasi penting berikut:

* `Camp 1 Main Tent`
* `Camp 1 Checkpoint`
* `Camp 2 Main Tent`
* `Camp 2 Checkpoint`
* `Camp 3 Main Tent`
* `Camp 3 Checkpoint`
* `Camp 4 Main Tent`
* `Camp 4 Checkpoint`
* `South Pole Checkpoint`

---

## ⚠️ Penanganan Error

* **Anti-Clipping:**
  Offset posisi dan penonaktifan *CanCollide* untuk mencegah bug terjebak.

* **Logging Error:**
  Semua error ditampilkan di `STATUS LOG` untuk kemudahan debugging.

* **Retry Otomatis:**
  Teleportasi akan dicoba ulang jika gagal dalam mode otomatis.

---

## 🧾 Disclaimer

Skrip ini dibuat hanya untuk tujuan **hiburan** dalam game Roblox "Ekspedisi Antartika".
Penggunaan skrip pihak ketiga **dapat melanggar Ketentuan Layanan Roblox**.
Gunakan dengan risiko Anda sendiri. Pengembang tidak bertanggung jawab atas konsekuensi penggunaan skrip ini.



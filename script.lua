-- Script KWLSID (Lua). Menu muncul sebagai panel kecil; kalau ditutup (X), script selesai.
-- Mode (root/non-root) dan paket game hanya ditanya sekali; selanjutnya langsung ke menu paket.
-- Ubah lewat "Ganti paket" / "Ganti mode" di menu ID.

-- ---------- mode ----------

local function pilihMode()
  local m = kw.choice("Pilih mode", {"Root", "Non-root (di virtual/clone)"})
  if not m then return nil end
  local mode = (m == 1) and "root" or "nonroot"
  kw.setMode(mode)
  if not kw.access() then
    kw.alert("KWLSID", m == 1 and "Akses root tidak diberikan."
      or "Non-root wajib dijalankan di dalam aplikasi virtual/clone.")
    return nil
  end
  if m == 2 then
    local names = kw.virtuals() or {}
    table.insert(names, 1, "Otomatis")
    local v = kw.choice("Aplikasi virtual", names)
    if not v then return nil end
    kw.setVirtual(v - 1)
    kw.save("virt", v - 1)
  end
  kw.save("mode", mode)
  return mode
end

-- Pakai mode yang tersimpan; kalau aksesnya hilang, tanya ulang.
local function ambilMode()
  local mode = kw.load("mode")
  if mode == "root" or mode == "nonroot" then
    kw.setMode(mode)
    if kw.access() then
      if mode == "nonroot" then
        kw.virtuals()
        kw.setVirtual(tonumber(kw.load("virt") or "0") or 0)
      end
      return mode
    end
    kw.save("mode", "")
  end
  return pilihMode()
end

-- ---------- paket ----------

local function pilihPaket()
  local list = kw.detect() or {}
  if #list == 0 then
    kw.alert("Paket", "Belum ada paket terdeteksi. Buka game sekali, lalu coba lagi.")
    return nil
  end
  local names = {}
  for i, e in ipairs(list) do names[i] = e.label end
  local i = kw.choice("Pilih paket", names)
  if not i then return nil end
  local pkg, err = kw.select(list[i])
  if not pkg then kw.alert("Paket", err) return nil end
  kw.save("pkg", pkg)
  kw.save("label", list[i].label)
  return pkg
end

-- Paket yang tersimpan: root langsung dipakai (tanpa deteksi ulang), non-root dicari lagi lewat deteksi.
local function paketTersimpan(mode)
  local saved = kw.load("pkg")
  if not saved then return nil end
  if mode == "root" then
    return kw.selectPkg(saved)
  end
  local label = kw.load("label")
  for _, e in ipairs(kw.detect() or {}) do
    if e.pkg == saved and (not label or e.label == label) then
      local pkg = kw.select(e)
      if pkg then return pkg end
    end
  end
  return nil
end

-- ---------- ID ----------

local function terapkan(pkg, nilai)
  local st, err = kw.apply(pkg, nilai)
  if st == "done" then kw.toast("ID berhasil diganti.")
  elseif st == "unchanged" then kw.toast("ID sama, tidak ada perubahan.")
  else kw.alert("Gagal", err or "Tidak diketahui.") end
end

local function menuSlot(pkg, cur)
  while true do
    local c = kw.choice("Slot akun", {"Simpan ID sekarang", "Pakai slot", "Hapus slot", "Kembali"})
    if not c or c == 4 then return end
    local semua = kw.slots() or {}
    local mine = {}
    for _, s in ipairs(semua) do if s.pkg == pkg then mine[#mine + 1] = s end end
    if c == 1 then
      local nama = kw.prompt("Nama slot", "kosong = otomatis")
      if nama then
        local _, err = kw.addSlot(pkg, cur, nama, nama == "")
        kw.toast(err or "Slot disimpan.")
      end
    else
      if #mine == 0 then kw.toast("Belum ada slot.")
      else
        local names = {}
        for i, s in ipairs(mine) do names[i] = s.name end
        local i = kw.choice(c == 2 and "Pakai slot" or "Hapus slot", names)
        if i then
          if c == 2 then terapkan(pkg, mine[i].value)
          else kw.deleteSlot(mine[i].id) kw.toast("Slot dihapus.") end
        end
      end
    end
  end
end

-- Mengembalikan "paket" / "mode" kalau pengguna minta ganti, nil kalau ditutup.
local function menuId(pkg)
  while true do
    local cur, err = kw.inspect(pkg)
    if not cur then
      kw.alert("Baca ID", err or "Gagal membaca.")
      return "paket"
    end
    local c = kw.choice("ID: " .. cur, {
      "Ganti acak semua", "Ganti manual", "Pulihkan backup", "Slot akun", "Ganti paket", "Ganti mode"})
    if not c then return nil end
    if c == 1 then
      local v = kw.randomAll(cur)
      if v then terapkan(pkg, v) end
    elseif c == 2 then
      local teks = kw.prompt("ID baru", "tempel ID")
      if teks and teks ~= "" then
        local v, e2 = kw.normalize(cur, teks)
        if v then terapkan(pkg, v) else kw.alert("ID", e2 or "Tidak valid.") end
      end
    elseif c == 3 then
      local st, e3 = kw.restore(pkg)
      if st then kw.toast("Backup dipulihkan.") else kw.alert("Pulihkan", e3 or "Gagal.") end
    elseif c == 4 then
      menuSlot(pkg, cur)
    elseif c == 5 then
      return "paket"
    elseif c == 6 then
      return "mode"
    end
  end
end

-- ---------- alur utama ----------

local function main()
  local mode = ambilMode()
  if not mode then return end
  local pkg = paketTersimpan(mode) or pilihPaket()
  while pkg do
    local r = menuId(pkg)
    if r == "paket" then
      kw.save("pkg", "")
      pkg = pilihPaket()
    elseif r == "mode" then
      kw.save("mode", "")
      kw.save("pkg", "")
      mode = pilihMode()
      if not mode then return end
      pkg = pilihPaket()
    else
      return
    end
  end
end

main()

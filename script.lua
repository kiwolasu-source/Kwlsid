-- Script contoh KWLSID (Lua). Menu muncul sebagai dialog; kalau dibatalkan, script selesai.

local function pilihMode()
  local m = kw.choice("KWLSID", {"Root", "Non-root (di virtual/clone)"})
  if not m then return nil end
  kw.setMode(m == 1 and "root" or "nonroot")
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
  end
  return m
end

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
  return pkg
end

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

local function menuId(pkg)
  while true do
    local cur, err = kw.inspect(pkg)
    if not cur then kw.alert("Baca ID", err or "Gagal membaca.") return end
    local c = kw.choice("ID: " .. cur, {
      "Ganti acak semua", "Ganti manual", "Pulihkan backup", "Slot akun", "Kembali"})
    if not c or c == 5 then return end
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
    end
  end
end

if pilihMode() then
  while true do
    local pkg = pilihPaket()
    if not pkg then break end
    menuId(pkg)
  end
end

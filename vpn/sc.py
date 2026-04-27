# clean.py
with open("/var/lib/libvirt/roms/patched_bios.rom", "rb") as f:
    data = f.read()
    # Ищем начало заголовка NVIDIA (0x55 0xAA)
    offset = data.find(b"\x55\xAA")
    if offset != -1:
        with open("/var/lib/libvirt/roms/patched_bios.rom", "wb") as out:
            out.write(data[offset:])
            print("Готово! Файл очищен.")

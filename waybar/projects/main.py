import libvirt
import random
import string
import datetime
import uuid
import xml.etree.ElementTree as ET
import time
import os

# отключения логов
def libvirt_callback(userdata, err):
    pass
libvirt.registerErrorHandler(f=libvirt_callback, ctx=None)


def vm_spoofer():
    tree = ET.parse("configs/1_default.xml")
    root = tree.getroot()

    # UUID
    new_uuid = str(uuid.uuid4())
    root.find('uuid').text = new_uuid
    root.find(".//sysinfo/system/entry[@name='uuid']").text = new_uuid

    # Disk serial number
    now = datetime.datetime.now()
    year = str(now.year - random.randint(1, 3))[2:]
    month = f"{random.randint(1, 12):X}"
    week = f"{random.randint(1, 52):02d}"

    i = random.choice([1, 1, 2, 2, 3, 3, 4])

    if i == 1:
        # Samsung
        suffix = ''.join(random.choices(string.ascii_uppercase + string.digits, k=11))
        disk_serial = f"S{year}{month}{suffix}"
    if i == 2:
        # Kingston
        suffix = ''.join(random.choices("0123456789ABCDEF", k=6))
        disk_serial = f"50026B{year}{month}{suffix}"
    if i == 3:
        # Western Digital
        suffix = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
        disk_serial = f"WD-W{year}{week}{suffix}"
    if i == 4:
        # NN
        disk_serial = ''.join(random.choices("0123456789", k=15))

    root.find(".//disk/serial").text = disk_serial
    print(disk_serial)

    # MAC address
    # ASUS: 00:1B:FC, 00:E0:18
    # Intel: 00:15:5D,
    # Realtek: 00:E0:4C
    real_ouis = ["00:1B:FC", "00:E0:18", "00:15:5D", "00:E0:4C"]
    prefix = random.choice(real_ouis)
#       <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    suffix = [f"{random.randint(0, 255):02x}" for _ in range(3)]
    mac_address = f"{prefix}:{(suffix[0])}:{(suffix[1])}:{(suffix[2])}".upper()

    root.find(".//interface/mac").set('address', mac_address)



    # Превращаем дерево обратно в строку XML
    xml_data = ET.tostring(root, encoding='unicode')

    return xml_data

vm_spoofer()

def reboot(login):
    # Подключаемся к libvirt
    conn = libvirt.open('qemu:///system')
    if conn is None:
        print("Error: не удалось подключиться к ВМ")
        return

    name = 'win10'
    if os.path.exists(f"configs/{login}.xml"):
        try:
            # Проверяем запущена ли ВМ
            vm = conn.lookupByName(name)
            if vm.isActive():
                print("Info: Перезапуск ВМ...")
                vm.destroy()
                while vm.isActive():
                    time.sleep(1)
                time.sleep(0.3)
        except libvirt.libvirtError:
            pass

        # убираем старый XML
        try:
            vm.undefineFlags(libvirt.VIR_DOMAIN_UNDEFINE_NVRAM)
            time.sleep(0.2)
        except libvirt.libvirtError:
            pass

        # меняем XML
        with open(f"configs/{login}.xml", "r", encoding="utf-8") as f:
            xml_content = f.read()
            
        v = conn.defineXML(xml_content)
        time.sleep(0.2)
        # запуск
        v.create()
        return

    try:
        try:
            # Проверяем запущена ли ВМ
            vm = conn.lookupByName(name)
            if vm.isActive():
                print("Info: Перезапуск ВМ...")
                vm.destroy()
                while vm.isActive():
                    time.sleep(1)
                time.sleep(0.5)
        except libvirt.libvirtError:
            pass

        # убираем старый XML
        try:
            vm.undefineFlags(libvirt.VIR_DOMAIN_UNDEFINE_NVRAM)
            time.sleep(0.1)
        except libvirt.libvirtError:
            pass

        # добовляем новый XML
        xml_data = vm_spoofer()
        new_dom = conn.defineXML(xml_data)
        time.sleep(0.2)
        # Запуск
        new_dom.create()

        with open(f"configs/{login}.xml", "w", encoding="utf-8") as f:
            f.write(xml_data)

    except libvirt.libvirtError as e:
        print(f"Error Libvirt: {e}")
    finally:
        conn.close()


reboot("topifi312")

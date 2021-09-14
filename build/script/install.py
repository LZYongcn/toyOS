import base
import sys
import os

if __name__ == '__main__':
    source_root = sys.argv[1]
    out_root = sys.argv[2]
    kernel_path = sys.argv[3]
    depfile_path = sys.argv[4]

    system_path = os.path.join(out_root, "obj/system")
    boot_path = os.path.join(out_root, "obj/bootLoader/boot.o")
    loader_path = os.path.join(out_root, "obj/bootLoader/loader.o")

    ret = base.execute("dd if={input} of={root}/VM/boot.img count=1 bs=512 conv=notrunc"
                       .format(input=boot_path, root=source_root), shell=True, oneline=False)[1]
    assert ret == 0

    ret = base.execute("hdiutil attach -mountroot {root}/VM/fat12 {root}/VM/boot.img"
                       .format(root=source_root), shell=True, oneline=True)[1]
    assert ret == 0

    ret = base.execute("cp {loader} {root}/VM/fat12/boot/loader.bin"
                       .format(loader=loader_path, root=source_root), shell=True, oneline=False)[1]
    assert ret == 0

    ret = base.execute("cp {loader} {root}/VM/fat12/boot/loader.bin"
                       .format(loader=loader_path, root=source_root), shell=True, oneline=False)[1]
    assert ret == 0

    ret = base.execute("llvm-objcopy -S -R \".eh_frame\" -R \".comment\" -O binary {system} {kernel}"
                       .format(system=system_path, kernel=kernel_path), shell=True, oneline=False)[1]
    assert ret == 0

    ret = base.execute("cp {kernel} {root}/VM/fat12/boot/kernel.bin"
                       .format(kernel=kernel_path, root=source_root), shell=True, oneline=False)[1]
    assert ret == 0

    if not os.path.exists(depfile_path):
        rel_system = os.path.relpath(system_path, out_root)
        rel_boot = os.path.relpath(boot_path, out_root)
        rel_loader = os.path.relpath(loader_path, out_root)
        rel_kernel = os.path.relpath(kernel_path, out_root)
        depfile_content = f"{rel_kernel}: {rel_system} {rel_boot} {rel_loader}"
        depfile = open(depfile_path, "w+")
        depfile.write(depfile_content)
        depfile.close()
from pbxproj import XcodeProject as xproj
import sys
import os
import base

if __name__ == '__main__':
    print(sys.argv)
    proj_path = sys.argv[1]
    output = sys.argv[2]
    depfile = sys.argv[3]
    root_out = sys.argv[4]
    if os.path.exists(proj_path) and proj_path.endswith(".xcodeproj"):
        proj_path = os.path.join(proj_path, "project.pbxproj")
        proj = xproj.load(proj_path)
        proj.add_other_cflags(['-std=c++17'])
        proj.save()

    if not os.path.exists(depfile):
        base.mkdir(os.path.dirname(depfile))
        rel_out = os.path.relpath(output, root_out)
        rel_dep = os.path.relpath(proj_path, root_out)
        dep_content = f"{rel_out}: {rel_dep}"
        dep_file = open(depfile, 'w+')
        dep_file.write(dep_content)
        dep_file.close()

    os.system("touch " + output)
    pass
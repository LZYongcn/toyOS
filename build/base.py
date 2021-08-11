import sys
import os
import shutil
import subprocess


class LineReader:
    io_obj = sys.stdin
    empty_count = 0

    def __init__(self, io_obj):
        self.io_obj = io_obj
        self.empty_count = 0

    def __iter__(self):
        return self

    def __call__(self):
        line = self.io_obj.readline()
        if line == '':
            self.empty_count += 1
        else:
            self.empty_count == 0

        if self.empty_count > 10:
            return StopIteration
        return line


def colorstr(info, color):
    return "\x1b[0;38;5;{color}m{info}\x1b[0m".format(info=info, color=color)


def print_color(info, color):
    print(colorstr(info, color))
    return


def print_red(err):
    print_color(err, 1)
    return


def print_dark_red(info):
    print_color(info, 88)
    return


def print_blue(info):
    print_color(info, 4)
    return


def print_purple(info):
    print_color(info, 5)
    return


def line_handle(line):
    split_list = list(str(line).split('=', 1))
    if len(split_list) == 2:
        striped = map(lambda x: x.strip(), split_list)
        return tuple(striped)
    return tuple(['', ''])


def parse_env(env_str):
    env_lines = list(env_str.strip().splitlines())
    pairs = map(line_handle, env_lines)
    res_dic = dict(pairs)
    return res_dic


def execute(cmd, exit_when_err=True, print2console=True, oneline=False, need_env=False, shell=False):
    str_cmd = cmd
    if type(cmd) == list:
        str_cmd = ' '.join(cmd)
    tag = "*mytag*"
    if need_env or shell:
        cmd = str_cmd
        shell = True
        if need_env:
            cmd = "{cmd} && echo {tag} && env".format(cmd=cmd, tag=tag)
    err = None if print2console else subprocess.PIPE
    process = subprocess.Popen(args=cmd, shell=shell, stderr=err, bufsize=-1, stdout=subprocess.PIPE,
                               universal_newlines=True)
    res_str = ""
    env_str = ""
    out_complete = False

    first_line = True
    if process.stdout:
        reader = LineReader(process.stdout)
        for line in iter(reader, b''):
            if type(line) is not str:
                break
            if out_complete is False:
                if need_env and line.find(tag) != -1:
                    out_complete = True
                else:
                    res_str = res_str + line
                    if print2console:
                        if oneline:
                            if first_line:
                                sys.stdout.write("\n\n\n\x1b[3A\x1b7")
                            else:
                                sys.stdout.write("\x1b8\x1b[J")
                            first_line = False
                        sys.stdout.write(line)
                        sys.stdout.flush()
            else:
                env_str = env_str + line

    process.stdout.close()
    process.wait()
    if process.returncode != 0:
        print_red("command \"{}\" execute failed!!!".format(str_cmd))
        if exit_when_err:
            exit(1)
    return res_str, process.returncode, env_str


def chdir(dir_path):
    os.chdir(dir_path)
    return


def mkdir(dir_path):
    if not os.path.exists(dir_path):
        os.mkdir(dir_path)
    elif os.path.isfile(dir_path):
        raise dir_path + "is a file!!!!"


def copy_all_files(from_dir, to_dir):
    for content in os.listdir(from_dir):
        src_path = os.path.join(from_dir, content)
        dst_path = os.path.join(to_dir, content)
        if os.path.isfile(src_path):
            shutil.copy(src_path, dst_path)
        else:
            shutil.copytree(src_path, dst_path)

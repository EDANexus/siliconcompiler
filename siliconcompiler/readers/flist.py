import os


def __make_path(rel, path):
    return os.path.relpath(path, rel)


def parse(chip, filename):
    package_name = f'flist-{os.path.basename(filename)}'
    package_dir = os.path.dirname(filename)

    chip.register_package_source(
        package_name,
        path=package_dir)
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()

            if not line:
                continue

            if line.startswith("//"):
                continue

            if line.startswith("+incdir+"):
                line = line[8:]
                chip.add('option', 'idir', __make_path(package_dir, line), package=package_name)
            elif line.startswith("+define+"):
                line = line[8:]
                chip.add('option', 'define', line)
            else:
                chip.input(__make_path(package_dir, line), package=package_name)


if __name__ == "__main__":
    from siliconcompiler import Chip
    from siliconcompiler.readers import flist

    chip = Chip('snitch_cluster')
    flist.parse(chip, '/home/pgadfort/tmp/snitch_cluster/files.flist')
    chip.set('option', 'frontend', 'systemverilog')
    chip.load_target("asap7_demo")
    chip.run()
    chip.summary()

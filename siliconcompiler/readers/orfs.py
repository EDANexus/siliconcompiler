import os
import re
import subprocess

from siliconcompiler import Chip


def _core_utilization(chip, setting):
    chip.set('constraint', 'density', setting)


__mapping = {
    "DESIGN_NAME": None,
    "FLOW_VARIANT": None,
    "CORE_UTILIZATION": _core_utilization
}

def parse(flow_home, design_config):
    flow_home = os.path.abspath(flow_home)
    if design_config:
        if not os.path.abspath(design_config):
            design_config = os.path.join(flow_home, design_config)
        design_config = os.path.abspath(design_config)
    mkfile = os.path.join(flow_home, "Makefile")

    cmd = ['make', '-f', mkfile, 'vars']
    if design_config:
        cmd.append(f'DESIGN_CONFIG={design_config}')

    print(" ".join(cmd))
    proc = subprocess.run(cmd,
                            cwd=flow_home,
                            stdout=subprocess.PIPE)
    output = proc.stdout.decode('utf-8')
    if proc.returncode != 0:
        raise RuntimeError('Failed to execute')

    print(output)

    settings = {}
    with open(os.path.join(flow_home, 'vars.sh'), 'r') as f:
        setting_parse = re.compile(r"export\s(\w+)='(.*)'")
        for line in f:
            if not line:
                continue
            match = setting_parse.match(line)
            if not match:
                print(f'Failed to parse: {line}')

            settings[match.group(1)] = match.group(2)

    for vfile in ('vars.sh', 'vars.tcl', 'vars.gdb'):
        os.remove(os.path.join(flow_home, vfile))

    return settings


def validate(settings):
    error = False
    for key in sorted(settings.keys()):
        if key not in __mapping:
            print(f"Unsupported key: {key} = {settings[key]}")
            error = True
    return not error


def convert(flow_home, design_config=None):
    orfs_settings = parse(flow_home=flow_home, design_config=design_config)
    if not validate(orfs_settings):
        pass
        # raise ValueError(f'Design uses unsupported keys')

    chip = Chip(f"{orfs_settings['DESIGN_NAME']}-{orfs_settings['FLOW_VARIANT']}")
    chip.set('option', 'entrypoint', orfs_settings['DESIGN_NAME'])

    for key, setter in __mapping.items():
        if not setter:
            continue

        print(f'Setting: {key}')
        setter(chip, orfs_settings[key])

    return chip


if __name__ == "__main__":
    chip = convert("/home/pgadfort/OpenROAD-flow-scripts/flow")
    chip.write_manifest(f'{chip.design}.json')

import os
import re
import subprocess

def parse(mkfile):
    flow_home = os.path.dirname(mkfile)
    design_config = flow_home + "/designs/nangate45/aes/config.mk"
    proc = subprocess.run(['make', '-f', mkfile, 'vars', f'DESIGN_CONFIG={design_config}'],
                            cwd=flow_home,
                            stdout=subprocess.PIPE)
    output = proc.stdout.decode('utf-8')

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

'''
Lint system verilog
'''
from siliconcompiler.tools import slang
import os
import sys
import pyslang
from siliconcompiler.tools._common import get_tool_task


def setup(chip):
    slang.setup(chip)

    step = chip.get('arg', 'step')
    index = chip.get('arg', 'index')
    tool, task = get_tool_task(chip, step, index)

    chip.set('tool', tool, 'task', task, 'threads', os.cpu_count(),
             clobber=False, step=step, index=index)

    chip.set('tool', tool, 'task', task, 'stdout', 'destination', 'output', step=step, index=index)
    chip.set('tool', tool, 'task', task, 'stdout', 'suffix', 'v', step=step, index=index)

    chip.set('tool', tool, 'task', task, 'output', f'{chip.top()}.v', step=step, index=index)


def __get_files(manager, tree):
    files = set()

    from queue import Queue
    nodes = Queue(maxsize=0)
    nodes.put(tree.root)

    while (not nodes.empty()):
        node = nodes.get()
        files.add(manager.getFileName(node.sourceRange.start))
        files.add(manager.getFileName(node.sourceRange.end))
        for token in node:
            if isinstance(token, pyslang.Token):
                continue
            else:
                nodes.put(token)

    return [os.path.abspath(f) for f in files if os.path.isfile(f)]


def __print_io(io):
    if io.out():
        print(io.out())
    if io.err():
        print(io.err(), file=sys.stderr)
    io.clear()


def run(chip):
    with pyslang.IORedirect() as io:
        driver, exitcode = slang._get_driver(chip, runtime_options)
        __print_io(io)
        if exitcode:
            return exitcode

    with pyslang.IORedirect() as io:
        compilation, ok = slang._compile(chip, driver)
        __print_io(io)

        manager = compilation.sourceManager

        with open(f'outputs/{chip.top()}.v', 'w') as out:
            for tree in compilation.getSyntaxTrees():
                files = __get_files(manager, tree)

                writer = pyslang.SyntaxPrinter(manager)
                writer.setIncludeTrivia(True)
                writer.setIncludeComments(True)
                writer.setSquashNewlines(True)
                for src_file in files:
                    out.write(f'// SC-Source: {src_file}\n')
                out.write(writer.print(tree).str() + '\n')

        __print_io(io)

    if ok:
        return 0
    else:
        return 1


def runtime_options(chip):
    options = slang.runtime_options(chip)

    options.append("--ignore-unknown-modules")

    return options

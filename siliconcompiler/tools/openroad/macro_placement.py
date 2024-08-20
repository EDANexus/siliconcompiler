import os

from siliconcompiler.tools._common import get_tool_task
from siliconcompiler.tools._common.asic import get_mainlib, get_libraries
from siliconcompiler.tools.openroad import setup as setup_tool
from siliconcompiler.tools.openroad import build_pex_corners, get_library_timing_keypaths
from siliconcompiler.tools.openroad import extract_metrics, tool_preprocess
from siliconcompiler.tools.openroad import set_reports, set_pnr_inputs, set_pnr_outputs
from siliconcompiler.tools.openroad import \
    define_ord_params, define_sta_params, define_sdc_params, \
    define_mpl_params, define_gpl_params
from siliconcompiler import NodeStatus


def setup(chip):
    '''
    Macro placement
    '''

    # Generic tool setup.
    setup_tool(chip)

    # Task setup
    step = chip.get('arg', 'step')
    index = chip.get('arg', 'index')
    tool, task = get_tool_task(chip, step, index)

    # Set options
    option = ["-metrics", "reports/metrics.json"]
    # exit automatically in batch mode and not breakpoint
    if not chip.get('option', 'breakpoint', step=step, index=index):
        option.append("-exit")

    chip.set('tool', tool, 'task', task, 'option', option, step=step, index=index, clobber=False)

    chip.set('tool', tool, 'task', task, 'refdir', 'tools/openroad/scripts',
             step=step, index=index, clobber=False, package='siliconcompiler')
    chip.set('tool', tool, 'task', task, 'script', 'apr/floorplan/sc_macro_placement.tcl',
             step=step, index=index, clobber=False)
    chip.set('tool', tool, 'task', task, 'threads', os.cpu_count(),
             step=step, index=index, clobber=False)

    if chip.get('option', 'nodisplay'):
        # Tells QT to use the offscreen platform if nodisplay is used
        chip.set('tool', tool, 'task', task, 'env', 'QT_QPA_PLATFORM', 'offscreen',
                 step=step, index=index)

    pdkname = chip.get('option', 'pdk')
    stackup = chip.get('option', 'stackup')

    targetlibs = get_libraries(chip, 'logic')
    macrolibs = get_libraries(chip, 'macro')
    mainlib = get_mainlib(chip)
    libtype = chip.get('library', mainlib, 'asic', 'libarch', step=step, index=index)
    if stackup and targetlibs:
        # Note: only one footprint supported in mainlib
        chip.add('tool', tool, 'task', task, 'require',
                 ",".join(['asic', 'logiclib']),
                 step=step, index=index)
        chip.add('tool', tool, 'task', task, 'require',
                 ",".join(['option', 'stackup']),
                 step=step, index=index)
        chip.add('tool', tool, 'task', task, 'require',
                 ",".join(['library', mainlib, 'asic', 'site', libtype]),
                 step=step, index=index)
        chip.add('tool', tool, 'task', task, 'require',
                 ",".join(['pdk', pdkname, 'aprtech', 'openroad', stackup, libtype, 'lef']),
                 step=step, index=index)

        for lib in targetlibs:
            for timing_key in get_library_timing_keypaths(chip, lib).values():
                chip.add('tool', tool, 'task', task, 'require', ",".join(timing_key),
                         step=step, index=index)
            chip.add('tool', tool, 'task', task, 'require',
                     ",".join(['library', lib, 'output', stackup, 'lef']),
                     step=step, index=index)
        for lib in macrolibs:
            for timing_key in get_library_timing_keypaths(chip, lib).values():
                if chip.valid(*timing_key):
                    chip.add('tool', tool, 'task', task, 'require', ",".join(timing_key),
                             step=step, index=index)
            chip.add('tool', tool, 'task', task, 'require',
                     ",".join(['library', lib, 'output', stackup, 'lef']),
                     step=step, index=index)
    else:
        chip.error('Stackup and logiclib parameters required for OpenROAD.')

    for key in (['pdk', pdkname, 'var', 'openroad', 'rclayer_signal', stackup],
                ['pdk', pdkname, 'var', 'openroad', 'rclayer_clock', stackup]):
        chip.add('tool', tool, 'task', task, 'require',
                 ",".join(key),
                 step=step, index=index)

    set_pnr_inputs(chip)
    set_pnr_outputs(chip)

    # set default values for openroad
    define_ord_params(chip)
    define_sta_params(chip)
    define_sdc_params(chip)
    define_mpl_params(chip)
    define_gpl_params(chip)

    set_reports(chip, [
        'setup',
        'unconstrained',
        'power'
    ])


def pre_process(chip):
    step = chip.get('arg', 'step')
    index = chip.get('arg', 'index')
    input_nodes = chip.get('record', 'inputnode', step=step, index=index)
    if all([chip.get('metric', 'macros', step=in_step, index=in_index) == 0 for in_step, in_index in input_nodes]):
        chip.set('record', 'status', NodeStatus.SKIPPED, step=step, index=index)
        chip.logger.warning(f'{step}{index} will be skipped since are no macros to place.')

    tool_preprocess(chip)
    build_pex_corners(chip)


def post_process(chip):
    extract_metrics(chip)

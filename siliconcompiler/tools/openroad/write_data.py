import os

from siliconcompiler.tools._common import get_tool_task
from siliconcompiler.tools._common.asic import get_mainlib, get_libraries, set_tool_task_var
from siliconcompiler.tools.openroad import setup as setup_tool
from siliconcompiler.tools.openroad import build_pex_corners, get_library_timing_keypaths
from siliconcompiler.tools.openroad import extract_metrics, tool_preprocess
from siliconcompiler.tools.openroad import set_reports, set_pnr_inputs, set_pnr_outputs
from siliconcompiler.tools.openroad import \
    define_ord_params, define_sta_params, define_sdc_params, \
    define_pex_params, define_psm_params
from siliconcompiler import NodeStatus


def setup(chip):
    '''
    Perform fill metal insertion
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
    chip.set('tool', tool, 'task', task, 'script', 'apr/sc_write_data.tcl',
             step=step, index=index, clobber=False)
    # Set thread count to 1 while issue related to write_timing_model segfaulting
    # when multiple threads are on is resolved.
    chip.set('tool', tool, 'task', task, 'threads', 1,
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
    define_pex_params(chip)
    define_psm_params(chip)

    design = chip.top()
    # Determine if exporting the cdl
    set_tool_task_var(chip, param_key='write_cdl',
                      default_value='false',
                      schelp='true/false, when true enables writing the CDL file for the design')
    do_cdl = chip.get('tool', tool, 'task', task, 'var', 'write_cdl',
                      step=step, index=index)[0] == 'true'

    if do_cdl:
        chip.add('tool', tool, 'task', task, 'output', design + '.cdl', step=step, index=index)
        for lib in targetlibs + macrolibs:
            chip.add('tool', tool, 'task', task, 'require',
                     ",".join(['library', lib, 'output', stackup, 'cdl']),
                     step=step, index=index)

    set_tool_task_var(chip, param_key='write_spef',
                      default_value='true',
                      schelp='true/false, when true enables writing the SPEF file for the design')
    do_spef = chip.get('tool', tool, 'task', task, 'var', 'write_spef',
                       step=step, index=index)[0] == 'true'
    set_tool_task_var(chip, param_key='use_spef',
                      default_value=do_spef,
                      schelp='true/false, when true enables reading in SPEF files.')

    if do_spef:
        # Require openrcx pex models
        for corner in chip.get('tool', tool, 'task', task, 'var', 'pex_corners',
                               step=step, index=index):
            chip.add('tool', tool, 'task', task, 'require',
                     ",".join(['pdk', pdkname, 'pexmodel', 'openroad-openrcx', stackup, corner]),
                     step=step, index=index)

        # Add outputs SPEF in the format {design}.{pexcorner}.spef
        for corner in chip.get('tool', tool, 'task', task, 'var', 'pex_corners',
                               step=step, index=index):
            chip.add('tool', tool, 'task', task, 'output', design + '.' + corner + '.spef',
                     step=step, index=index)

    # Add outputs LEF
    chip.add('tool', tool, 'task', task, 'output', design + '.lef', step=step, index=index)

    set_tool_task_var(chip, param_key='write_liberty',
                      default_value='true',
                      schelp='true/false, when true enables writing the liberty '
                             'timing model for the design')
    do_liberty = chip.get('tool', tool, 'task', task, 'var', 'write_liberty',
                          step=step, index=index)[0] == 'true'

    if do_liberty:
        # Add outputs liberty model in the format {design}.{libcorner}.lib
        for corner in chip.getkeys('constraint', 'timing'):
            chip.add('tool', tool, 'task', task, 'output', design + '.' + corner + '.lib',
                     step=step, index=index)

    set_tool_task_var(chip, param_key='write_sdf',
                      default_value='true',
                      schelp='true/false, when true enables writing the SDF timing model '
                             'for the design')
    do_sdf = chip.get('tool', tool, 'task', task, 'var', 'write_sdf',
                      step=step, index=index)[0] == 'true'
    if do_sdf:
        # Add outputs liberty model in the format {design}.{libcorner}.sdf
        for corner in chip.getkeys('constraint', 'timing'):
            chip.add('tool', tool, 'task', task, 'output', design + '.' + corner + '.sdf',
                     step=step, index=index)

    set_reports(chip, [
        'setup',
        'unconstrained',
        'power'
    ])


def pre_process(chip):
    tool_preprocess(chip)
    build_pex_corners(chip)


def post_process(chip):
    extract_metrics(chip)

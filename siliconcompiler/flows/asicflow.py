import siliconcompiler

from siliconcompiler.flows._common import setup_multiple_frontends
from siliconcompiler.flows._common import _make_docs

from siliconcompiler.tools.yosys import syn_asic
from siliconcompiler.tools.openroad import init_floorplan
from siliconcompiler.tools.openroad import macro_placement
from siliconcompiler.tools.openroad import endcap_tapcell_insertion
from siliconcompiler.tools.openroad import power_grid
from siliconcompiler.tools.openroad import io_pin_placement
from siliconcompiler.tools.openroad import global_placement
from siliconcompiler.tools.openroad import repair_design
from siliconcompiler.tools.openroad import detailed_placement
from siliconcompiler.tools.openroad import clock_tree_synthesis
from siliconcompiler.tools.openroad import repair_timing
from siliconcompiler.tools.openroad import fillercell_insertion
from siliconcompiler.tools.openroad import global_route
from siliconcompiler.tools.openroad import antenna_repair
from siliconcompiler.tools.openroad import detailed_route
from siliconcompiler.tools.openroad import fillmetal_insertion
from siliconcompiler.tools.openroad import write_data
from siliconcompiler.tools.klayout import export as klayout_export

from siliconcompiler.tools.builtin import minimum


############################################################################
# DOCS
############################################################################
def make_docs(chip):
    n = 3
    _make_docs(chip)
    return setup(chip, syn_np=n, floorplan_np=n, physyn_np=n, place_np=n, cts_np=n, route_np=n)


###########################################################################
# Flowgraph Setup
############################################################################
def setup(chip,
          flowname='asicflow',
          syn_np=1,
          floorplan_np=1,
          physyn_np=1,
          place_np=1,
          cts_np=1,
          route_np=1):
    '''
    A configurable ASIC compilation flow.

    The 'asicflow' includes the stages below. The steps syn, floorplan,
    physyn, place, cts, route, and dfm have minimization associated
    with them. To view the flowgraph, see the .png file.

    * **import**: Sources are collected and packaged for compilation
    * **syn**: Translates RTL to netlist using Yosys
    * **floorplan**: Floorplanning
    * **physyn**: Physical Synthesis
    * **place**: Global and detailed placement
    * **cts**: Clock tree synthesis
    * **route**: Global and detailed routing
    * **dfm**: Metal fill, atenna fixes and any other post routing steps
    * **export**: Export design from APR tool and merge with library GDS
    * **sta**: Static timing analysis (signoff)
    * **lvs**: Layout versus schematic check (signoff)
    * **drc**: Design rule check (signoff)

    The syn, physyn, place, cts, route steps supports per process
    options that can be set up by setting '<step>_np'
    arg to a value > 1, as detailed below:

    * syn_np : Number of parallel synthesis jobs to launch
    * floorplan_np : Number of parallel floorplan jobs to launch
    * physyn_np : Number of parallel physical synthesis jobs to launch
    * place_np : Number of parallel place jobs to launch
    * cts_np : Number of parallel clock tree synthesis jobs to launch
    * route_np : Number of parallel routing jobs to launch
    '''

    flow = siliconcompiler.Flow(chip, flowname)

    # Linear flow, up until branch to run parallel verification steps.
    longpipe = [
        'syn',
        'synmin',
        'floorplan.init',
        'floorplan.macro_placement',
        'floorplan.tapcell',
        'floorplan.power_grid',
        'floorplan.io_pin_placement',
        'floorplanmin',
        'place.global_placement',
        'place.repair_design',
        'place.detailed_placement',
        'placemin',
        'cts.clock_tree_synthesis',
        'cts.repair_timing',
        'cts.fillcell',
        'ctsmin',
        'route.global_route',
        'route.antenna_repair',
        'route.detailed_route',
        'routemin',
        'dfm.metal_fill'
    ]

    # step --> task
    tasks = {
        'syn': syn_asic,
        'synmin': minimum,
        'floorplan.init': init_floorplan,
        'floorplan.macro_placement': macro_placement,
        'floorplan.tapcell': endcap_tapcell_insertion,
        'floorplan.power_grid': power_grid,
        'floorplan.io_pin_placement': io_pin_placement,
        'floorplanmin': minimum,
        'place.global_placement': global_placement,
        'place.repair_design': repair_design,
        'place.detailed_placement': detailed_placement,
        'placemin': minimum,
        'cts.clock_tree_synthesis': clock_tree_synthesis,
        'cts.repair_timing': repair_timing,
        'cts.fillcell': fillercell_insertion,
        'ctsmin': minimum,
        'route.global_route': global_route,
        'route.antenna_repair': antenna_repair,
        'route.detailed_route': detailed_route,
        'routemin': minimum,
        'dfm.metal_fill': fillmetal_insertion
    }

    np = {
        "syn": syn_np,
        "floorplan": floorplan_np,
        "physyn": physyn_np,
        "place": place_np,
        "cts": cts_np,
        "route": route_np
    }

    prevstep = None
    # Remove built in steps where appropriate
    flowpipe = []
    for step in longpipe:
        task = tasks[step]
        if task == minimum:
            np_step = prevstep.split('.')[0]
            if np_step in np and np[np_step] > 1:
                flowpipe.append(step)
        else:
            flowpipe.append(step)
        prevstep = step

    flowtasks = []
    for step in flowpipe:
        flowtasks.append((step, tasks[step]))

    # Programmatically build linear portion of flowgraph and fanin/fanout args
    prevstep = setup_multiple_frontends(chip, flow)
    for step, task in flowtasks:
        fanout = 1
        np_step = step.split('.')[0]
        if np_step in np:
            fanout = np[np_step]

        # create nodes
        for index in range(fanout):
            # nodes
            flow.node(flowname, step, task, index=index)

        # create edges
        for index in range(fanout):
            # edges
            fanin = 1
            np_prestep = prevstep.split('.')[0]
            if np_prestep in np:
                fanin = np[np_prestep]
            if task == minimum:
                for i in range(fanin):
                    flow.edge(flowname, prevstep, step, tail_index=i)
            elif prevstep:
                if fanin == fanout:
                    flow.edge(flowname, prevstep, step, tail_index=index, head_index=index)
                else:
                    flow.edge(flowname, prevstep, step, head_index=index)

            # metrics
            goal_metrics = ()
            weight_metrics = ()
            if task in (syn_asic, ):
                goal_metrics = ('errors',)
                weight_metrics = ()
            # elif task in (floorplan, physyn, place, cts, route, dfm):
            #     goal_metrics = ('errors', 'setupwns', 'setuptns')
            #     weight_metrics = ('cellarea', 'peakpower', 'leakagepower')

            for metric in goal_metrics:
                flow.set('flowgraph', flowname, step, str(index), 'goal', metric, 0)
            for metric in weight_metrics:
                flow.set('flowgraph', flowname, step, str(index), 'weight', metric, 1.0)
        prevstep = step

    # add write information steps
    flow.node(flowname, 'write_gds', klayout_export)
    flow.edge(flowname, prevstep, 'write_gds')
    flow.node(flowname, 'write_data', write_data)
    flow.edge(flowname, prevstep, 'write_data')

    return flow


##################################################
if __name__ == "__main__":
    chip = siliconcompiler.Chip('design')
    chip.set('input', 'constraint', 'sdc', 'test')
    flow = make_docs(chip)
    chip.use(flow)
    chip.write_flowgraph(f"{flow.top()}.png", flow=flow.top(), background="white", show_io=True)

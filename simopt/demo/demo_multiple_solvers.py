import sys
import os.path as o
import os
sys.path.append(o.abspath(o.join(o.dirname(sys.modules[__name__].__file__), "..")))

from wrapper_base import MetaExperiment


solvers = ["RNDSRCH10", "RNDSRCH100"]
problems = ["CNTNEWS-1", "FACSIZE-2","MM1-1","SSCONT-1","RMITD-1"]
myMetaExperiment = MetaExperiment(solver_names=solvers, problem_names=problems, fixed_factors_filename="all_factors")
print("now here")
#myMetaExperiment.post_replicate(n_postreps=200, n_postreps_init_opt=200, crn_across_budget=True, crn_across_macroreps=False)
myMetaExperiment.plot_solvability_profiles(plot_CIs=True, solve_tol=0.2, beta=0.5, ref_solver="RNDSRCH100")
myMetaExperiment.plot_area_scatterplot(plot_CIs=True, all_in_one=True)
#myMetaExperiment.plot_progress_curves(plot_type="quantile", beta=0.90, normalize=True)
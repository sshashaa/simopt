#import sys
#import os.path as o
#import os
#sys.path.append(o.abspath(o.join(o.dirname(sys.modules[__name__].__file__), "..")))
# os.chdir('../')

from wrapper_base import Experiment, read_experiment_results ## imporrting took time

solver_name = "RNDSRCH" # random search solver
problem_name = "RMITD-1"
#problem_name = "SSCONT-1"

sample_size = 100
budget = 5000
budgets = [1000,2000,3000,4000,5000,6000,7000,8000,9000,10000]


file_name_path = "experiments/outputs/" + solver_name + "_on_" + problem_name + "_s"+str(sample_size)+"_b"+str(budget)+".pickle"
myexperiment = Experiment(solver_name, problem_name, 
                          solver_fixed_factors={"sample_size": sample_size},
                          problem_fixed_factors={"budget": budget},
                          file_name_path=file_name_path)
#print(myexperiment.problem.check_problem_factor("initial_solution"))
myexperiment.run(n_macroreps=10)
myexperiment.post_replicate(n_postreps=200, n_postreps_init_opt=200, crn_across_budget=True, crn_across_macroreps=False)

# #print("Here")

#myexperiment = read_experiment_results(file_name_path)

# #print("Now here.")
# myexperiment.plot_progress_curves(plot_type="all", normalize=False)
myexperiment.plot_progress_curves(plot_type="all", normalize=True)
 #print("Finally here.")
myexperiment.plot_progress_curves(plot_type="mean", normalize=True)
myexperiment.plot_progress_curves(plot_type="quantile", normalize=True)
myexperiment.plot_progress_curves(plot_type="quantile", beta=0.9, normalize=True)

myexperiment.plot_solvability_curves(solve_tols=[0.2])
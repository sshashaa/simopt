#import sys
#import os.path as o
#import os
#sys.path.append(o.abspath(o.join(o.dirname(sys.modules[__name__].__file__), "..")))
# os.chdir('../')

# from oracles.mm1queue import MM1Queue
from data_farming_base import DesignPoint, DataFarmingExperiment, DataFarmingMetaExperiment
from csv import DictReader


# factor_headers = ["purchase_price", "sales_price", "salvage_price", "order_quantity"]
# myexperiment = DataFarmingExperiment(oracle_name="CNTNEWS", factor_settings_filename="oracle_factor_settings", factor_headers=factor_headers, design_filename=None, oracle_fixed_factors={})
# myexperiment.run(n_reps=10, crn_across_design_pts=False)
# myexperiment.print_to_csv(csv_filename="cntnews_data_farming_output")

solver_factor_headers = ["sample_size"]
#oracle_factor_headers = ["cost","gamma_shape","gamma_scale","initial_inventory"]

for p in ["CNTNEWS-1", "FACSIZE-2","MM1-1","SSCONT-1"]:
    myMetaExperiment = DataFarmingMetaExperiment(solver_name="RNDSRCH",
                                             problem_name=p,
                                             solver_factor_headers=solver_factor_headers,
                                             solver_factor_settings_filename="", # solver_factor_settings",
                                             design_filename="random_search_design",
                                             solver_fixed_factors={},
                                             problem_fixed_factors={},
                                             oracle_fixed_factors={})
    myMetaExperiment.run(n_macroreps=10)
    myMetaExperiment.post_replicate(n_postreps=200, n_postreps_init_opt=200, crn_across_budget=True, crn_across_macroreps=False)
#
#myMetaExperiment.plot_solvability_profiles(solve_tol=0.2, beta=0.5, ref_solver="RNDSRCH10")
##myMetaExperiment.plot_area_scatterplot(plot_CIs=False, all_in_one=False)
#myMetaExperiment.plot_progress_curves(plot_type="quantile", beta=0.90, normalize=True)

#myMetaExperiment = DataFarmingMetaExperiment(solver_name="RNDSRCH",
#                                             problem_name="FACSIZE-2",
#                                             oracle_factor_headers=oracle_factor_headers,
#                                             oracle_factor_settings_filename="", # solver_factor_settings",
#                                             design_filename="RMITDdesign",
#                                             solver_fixed_factors={},
#                                             problem_fixed_factors={},
#                                             oracle_fixed_factors={})



# myMetaExperiment.calculate_statistics() # solve_tols=[0.10], beta=0.50)
# myMetaExperiment.print_to_csv(csv_filename="meta_raw_results")

print("I ran this.")


# SCRATCH
# --------------------------------
# from csv import DictReader
# # open file in read mode
# with open('example_design_matrix.csv', 'r') as read_obj:
#     # pass the file object to DictReader() to get the DictReader object
#     csv_dict_reader = DictReader(read_obj)
#     # iterate over each line as a ordered dictionary
#     for row in csv_dict_reader:
#         # row variable is a dictionary that represents a row in csv
#         print(row)
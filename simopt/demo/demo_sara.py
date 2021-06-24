#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jun 22 10:49:08 2021

@author: sarashashaani
"""

import numpy as np
import sys
sys.path.append('/Users/sarashashaani/Documents/GitHub/simopt/simopt/')
from rng.mrg32k3a import MRG32k3a
from wrapper_base import Experiment, read_experiment_results, MetaExperiment
from data_farming_base import DesignPoint, DataFarmingExperiment, DataFarmingMetaExperiment


solver_name = "RNDSRCH" # random search solver
problem_name = "RMITD-1"

#sample_size = 100
budget = 5000

sample_sizes = [10,50,100] 
budgets = [1000,2000,3000,4000,5000,6000,7000,8000,9000,10000]
initial_solutions = [(100, 50, 30),(100, 150, 30),(100, 100, 30),(100, 200, 30),
                     (50, 50, 30),(50, 150, 30),(50, 100, 30),(50, 200, 30),
                     (150, 50, 30),(150, 150, 30),(150, 100, 30),(150, 200, 30),
                     (200, 50, 30),(200, 150, 30),(200, 100, 30),(200, 200, 30),
                     (100, 50, 50),(100, 150, 50),(100, 100, 50),(100, 200, 50),
                     (50, 50, 50),(50, 150, 50),(50, 100, 50),(50, 200, 50),
                     (150, 50, 50),(150, 150, 50),(150, 100, 50),(150, 200, 50),
                     (200, 50, 50),(200, 150, 50),(200, 100, 50),(200, 200, 50),
                     (100, 50, 10),(100, 150, 10),(100, 100, 10),(100, 200, 10),
                     (50, 50, 10),(50, 150, 10),(50, 100, 10),(50, 200, 10),
                     (150, 50, 10),(150, 150, 10),(150, 100, 10),(150, 200, 10),
                     (200, 50, 10),(200, 150, 10),(200, 100, 10),(200, 200, 10)]

sample_sizes = [50]
for i,j in enumerate(initial_solutions):
    for s in sample_sizes:
        file_name_path = "experiments/outputs/" + solver_name + str(s) + "_b" + str(budget) + "_on_" +  problem_name + "_i"+str(i)+".pickle"
        myexperiment = Experiment(solver_name, problem_name, 
                                  solver_fixed_factors={"sample_size": s,"budget": budget},
                                  problem_fixed_factors={"initial_solution": j},
                                  file_name_path=file_name_path)
        print("running experiment with initial solution "+ str(j)) #str(myexperiment.problem.check_problem_factor("initial_solution")))
        myexperiment.run(n_macroreps=10)
        myexperiment.post_replicate(n_postreps=200, n_postreps_init_opt=200, crn_across_budget=True, crn_across_macroreps=False)

solvers = ["RNDSRCH"+str(s)+"_b"+str(budget) for s in sample_sizes]
#problems = ["CNTNEWS-1", "FACSIZE-2","MM1-1","SSCONT-1","RMITD-1"]
problems = ["RMITD-1_i"+str(i) for i in range(len(initial_solutions))]
myMetaExperiment = MetaExperiment(solver_names=solvers, problem_names=problems, fixed_factors_filename="all_factors")
print("now here")
#myMetaExperiment.post_replicate(n_postreps=200, n_postreps_init_opt=200, crn_across_budget=True, crn_across_macroreps=False)
myMetaExperiment.plot_solvability_profiles(solve_tol=0.2, beta=0.5, ref_solver="RNDSRCH100"+"_b"+str(budget))
myMetaExperiment.plot_area_scatterplot(plot_CIs=False, all_in_one=True)
#

## new experiment with 81 problems but the optimal solution changes
costs = [75.0,80.0,85.0]
gamma_scales = [0.5,1.0,2.0]
gamma_shapes = [.5,1.0,2.0]
initial_inventories = [50,100,200]


for c in costs:
    for gsc in gamma_scales:
        for gsh in gamma_shapes:
            for ii in initial_inventories:
                file_name_path = "experiments/outputs/" + solver_name + str(s) + "_b" + str(budget) + "_on_" + \
                problem_name + "_c"+str(c)+"-gsc"+str(gsc)+"-gsh"+str(gsh)+"-ii"+str(ii)+".pickle"
                myexperiment = Experiment(solver_name, problem_name, 
                                          solver_fixed_factors={"sample_size": s,"budget": budget},
#                                          problem_fixed_factors={"initial_solution": j},
                                          problem_fixed_factors={"cost": c,"gamma_scale":gsc,"gamma_shape":gsh,"initial_inventory":ii},
                                          file_name_path=file_name_path)
                print("running experiment with initial solution "+ str(j)) #str(myexperiment.problem.check_problem_factor("initial_solution")))
                myexperiment.run(n_macroreps=10)
                myexperiment.post_replicate(n_postreps=200, n_postreps_init_opt=200, crn_across_budget=True, crn_across_macroreps=False)

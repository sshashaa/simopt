import numpy as np
import sys
import os.path as o
import os
sys.path.append('/Users/sarashashaani/Documents/GitHub/simopt/simopt/')
#sys.path.append(o.abspath(o.join(o.dirname(sys.modules[__name__].__file__), "..")))
#sys.path.append(o.abspath(o.join(o.dirname(o.abspath("__file__")), "..")))¡

import rng
from rng.mrg32k3a import MRG32k3a
# from oracles.cntnv import CntNVMaxProfit
# from oracles.mm1queue import MM1MinMeanSojournTime
# from oracles.facilitysizing import FacilitySizingTotalCost
# from oracles.rmitd import RMITDMaxRevenue
from oracles.sscont import SSContMinCost
from base import Solution


myproblem = SSContMinCost()

x = (7, 50)
mysolution = Solution(x, myproblem)

# Create and attach rngs to solution
rng_list = [MRG32k3a(s_ss_sss_index=[0, ss, 0]) for ss in range(myproblem.oracle.n_rngs)]
# print(rng_list)
mysolution.attach_rngs(rng_list, copy=False)
# print(mysolution.rng_list)

# Test simulate()
n_reps = 20
myproblem.simulate(mysolution, m=n_reps)
print('For ' + str(n_reps) + ' replications:')
#print('The individual objective estimates are {}'.format(mysolution.objectives[:10]))
print('The mean objective is {}'.format(mysolution.objectives_mean))
#print('The stochastic constraint estimates are {}'.format(mysolution.stoch_constraints[:10]))
#print('The individual gradient estimates are {}'.format(mysolution.objectives_gradients[:10]))

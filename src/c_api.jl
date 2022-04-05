# https://www.math.uwaterloo.ca/tsp/concorde/DOC/tsp.html#CCtsp_solve_sparse

# CCtsp_solve_sparse

# File:
# TSP/tsp_call.c
# Header:
# tsp.h
# Prototype:
# int CCtsp_solve_sparse (int ncount, int ecount, int *elist,
#     int *elen, int *in_tour, int *out_tour, double *in_val,
#     double *optval, int *success, int *foundtour, char *name,
#     double *timebound, int *hit_timebound, int silent,
#     CCrandstate *rstate)
# Description:
# SOLVES the TSP over the graph specfied in the edgelist.
#  -elist is an array giving the ends of the edges (in pairs)
#  -elen is an array giving the weights of the edges.
#  -in_tour gives a starting tour in node node node format (it can
#   be NULL)
#  -out_tour will return the optimal tour (it can be NULL, if it is
#   not NULL then it should point to an array of length at least
#   ncount.
#  -in_val can be used to specify an initial upperbound (it can be
#   NULL)
#  -optval will return the value of the optimal tour.
#  -success will be set to 1 if the run finished normally, and set to
#   if the search was terminated early (by hitting some predefined
#   limit)
#  -foundtour will be set to 1 if a tour has been found (if success
#   is 0, then it may not be the optimal tour)
#  -name specifes a char string that will be used to name various
#   files that are written during the branch and bound search (if it
#   is NULL, then "noname" will be used - this will cause problems
#   in a multithreaded program, so specify a distinct name in that
#   case).
#  -silent will suppress most output if set to a nonzero value.



# CCtsp_solve_dat

# File:
# TSP/tsp_call.c
# Header:
# tsp.h
# Prototype:
# int CCtsp_solve_dat (int ncount, CCdatagroup *indat, int *in_tour,
#     int *out_tour, double *in_val, double *optval, int *success,
#     int *foundtour, char *name, double *timebound, int *hit_timebound,
#     int silent, CCrandstate *rstate)
# Description:
# SOLVES the TSP over the graph specified in the datagroup.
# LIKE CCtsp_solve_sparse.


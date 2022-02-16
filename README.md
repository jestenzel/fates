# Branch Notes
------------------------------
This branch adds mortality tolerance parameters and a new source of mortality (heat). Temperature based mortality   
tolerance is set based on whether a tree has "hardened"  yet, which is set by dbh.  At dry sites, early-run (months)  
soil water was causing undesired mortality. Hydraulic failure mort was therefore hardcoded to not occur until after  
DOY 182 (July 1) of the  first simulation year. A separate parameter was introduced to differentiate mortality CWD  
class partitioning from branch turnover- related CWD class partitioning.           

Added parameters /definition changes:   

-[**placeholder**]  
-**fates_mort_heat_tol** (pft) :maximum temperature tolerance, post-seedling; degress C.  
-**fates_mort_heat_tol_seedling** (pft): maximum temperature tolerance, seedling; degrees C  
-**fates_freezetol_seedling** (pft): minimum temperature tolerance, seedling  
-(definition change) **fates_mort_freezetol** (pft): minimum temperature tolerance, post-seedling; degrees C  
-(definition change) **fates_mort_scalar_hydrfailure** (pft): max mortality rate from hydraulic failure. **This value will be 0 before model day 182.**        
-**fates_mort_hard_dbh** (pft): minimum dbh for non-seedling temperature mortality (i.e. hardened plant)  
-**fates_mort_cstarvetol** (pft): threshold storage c : leaf c fraction for start of cstarvation mortality; 1/leafC.   
-**fates_CWD_turnover_frac** (NCWD): fraction of non-mortality turnover woody (bdead+bsw) biomass destined for CWD pool  
-(definition change) **fates_CWD_frac** (NCWD): fraction of mortality woody (bdead+bsw) biomass destined for CWD pool  


# FATES
------------------------------
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.3825473.svg)](https://doi.org/10.5281/zenodo.3825473)

This repository holds the Functionally Assembled Terrestrial Ecosystem Simulator (FATES).  FATES is a numerical terrestrial ecosystem model. Its development and support is primarily supported by the Department of Energy's Office of Science, through the Next Generation Ecosystem Experiment - Tropics ([NGEE-T](https://ngee-tropics.lbl.gov/)) project.

For more information on the FATES model, see our [wiki](https://github.com/NGEET/fates/wiki) and [technical documentation](https://fates-docs.readthedocs.io/en/latest/index.html).


## Important Guides:
------------------------------

[How to Contribute](https://github.com/NGEET/fates/blob/master/CONTRIBUTING.md)

[List of Unsupported or Broken Features](https://github.com/NGEET/fates/wiki/Current-Unsupported-or-Broken-Features)

[Code of Conduct](https://github.com/NGEET/fates/blob/master/CODE_OF_CONDUCT.md)


## Important Note:
------------------------------

**Most users should not need to directly clone this repository.  FATES needs to be run through a host model, and all supported host-models are in charge of cloning and loading the fates software.**

FATES has support to be run via the Energy Exascale Earth System Model (E3SM), the Community Earth System Model (CESM), or its land component, the Community Terrestrial Systems Model (CTSM).

https://github.com/E3SM-Project/E3SM

https://github.com/ESCOMP/cesm
https://github.com/ESCOMP/ctsm


## Important Note About Host-Models and Compatible Branches:
------------------------------------------------------------

The FATES and E3SM teams maintain compatability of the NGEET/FATES master branch with the **E3SM master** branch. When changes to the FATES API force compatability updates with E3SM, there may be some modest lag time.

The FATES team maintains compatability of the NGEET/FATES master branch with the **CTSM fates_next_api** branch.  Since the FATES team uses this branch for its internal testing, this compatability is tightly (immediately) maintained and these two should always be in sync.  However, CTSM master may become out of sync with FATES master for large periods (months) of time.





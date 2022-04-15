# **Disturbance_1**

See branch_readme.txt for branch modifications.

Changes:
- Mortality dynamics
- Snags ! Biomass turnover. 
- Harvest slash combustion
- Harvest seedling planting

Disturbance_1 branch changes: 

Summary:

(Temperature-based mortality)
- heat mortality added (like freeze mortality)
- Temperature-based mortalities now based on daily min/max temperature INSTEAD of mean temperature. 
- Seedling temperature tolerances set by separate parameters to represent seedling vs hardened stems.

(Fuels)
- New parameter for live -> CWD destination fraction from branch turnover. Previously, fractions from mortality and turnover were the same and were, by default, dominated by 1000 hr fuels. 
-SNAGS !!!! Dying tree biomass that is not combusted or exported now enters snag pools (no decomposition). Snag fall rate to litter/cwd pools is dictated by a new parameter. Snag leaves, twigs, and small branches can combust during fire given that average patch scorch height is greater than [X] m. 

(c-starvation)
-Parameter added for c-starvation storage tolerance. The fraction of target storage at which mortality begins can now be set. 

(Management)
- CTSM harvest layers from landuse timeseries can now be used to prescribe “regeneration harvest” events (i.e. harvest AND planting). A new parameter has been added to prescribe planted seedling mass by PFT. PFTs can be planted on a site where they were not present at run start. The natural seedbank is sent to the soil decay pool.
-Parameters added for the proportion of live harvested and existing dead mass within harvest-disturbed areas that get combusted as slash during harvest events.  Previously, mass EXCEPT for exported bole fractions was added to litter/cwd pools. 


Added / Changed-usage parameters:
(+) 12
(Δ) 3

Mortality:
+ fates_mort_heat_tol (pft) :maximum temperature tolerance, post-seedling; degress C.
+ fates_mort_heat_tol_seedling (pft): maximum temperature tolerance, seedling; degrees C
+fates_mort_scalar_heatstress (pft) : maximum mortality rate from heat stress; 1/yr.
+ fates_freezetol_seedling (pft): minimum temperature tolerance, seedling
Δ  (definition change) fates_mort_freezetol (pft): minimum temperature tolerance, post-seedling; degrees C
+fates_temp_delay : Days since run start required for turning temperature-based mortality (heat,freeze) “on”. 
 Δ  (definition change) fates_mort_scalar_hydrfailure (pft): (max mortality rate from hydraulic failure). This value will be 0 before model day 182 due to early run hydraulic mortality that was resulting from soil moisture spinup.
+ fates_mort_hard_dbh (pft): minimum dbh for non-seedling temperature mortality (i.e. hardened plant)
+ fates_mort_cstarvetol (pft): threshold storage c : leaf c fraction for start of cstarvation mortality; 1/leafC. 
+ fates_bmort_stress_multiplier(pft): maximum multiplier for bmort rate, scaled by C-storage fraction of target

Fuels:
+ fates_CWD_turnover_frac (NCWD): fraction of non-mortality turnover woody (bdead+bsw) biomass destined for CWD pool
Δ (definition change) fates_CWD_frac (NCWD): fraction of mortality woody (bdead+bsw) biomass destined for CWD pool
+ fates_ag_dead_fallrate(fates_litterclass) Snag fall. Maximum rate of dead woody & leaf transfer from snag class into non-decomposing litter class; yr-1. NOTE: 
+ fates_dead_slash_burn(fates_litterclass) fraction of litter & snag mass combusted within logging-event disturbed area. Except where noted, litter and snag pools of the same size class are combusted at the same rates. NOTE: The grass value (fates_live_slash_burn[6]) applies to ground-litter dead leaves, and is meant to represent incidental combustion of litter only under slash piles (vs collection and piling of woody debris and any attached leaves on dead trees). The dead leaf value (fates_live_slash_burn[5]) applies to dead snag leaves BUT NOT litter leaves. 
+ fates_live_slash_burn(fates_litterclass) fraction of tree mass destined for litter combusted within logging-event disturbed area. NOTE: The grass value (fates_live_slash_burn[6]) does not apply here. 
+ fates_snag_burn_switch :  1 (on) or 0 (off). On means that snag biomass can burn during wildfire. Currently, if patch-average scorch height is over a hardcoded height (currently, 5m), dead leaf, twig, and small branch snag pools can combust (“torch”) according to the equivalend ground litter/cwd rates calculated for the timestep based on fuel size moisture. Large branches and boles do not combust (100 and 1000 hr-equivalent standing). 

Planting:
+ fates_seed_planted (pft): Supplemental external seedling planting source term (non-mass conserving); KgC/m2/event. [NOTE: Only intended to be used with single-date planting events!!!! These events can be prescribed through using: 1) (FATES harvest on via namelist) FATES event code for specific date. 2) (FATES and HLM harvest on via namelist) FATES event code for DOY and HLM inputs for areal fraction per year = DOY + YEAR. 


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





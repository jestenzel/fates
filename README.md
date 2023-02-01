
![FATES_logo](.github/images/logo_fates_small.png)
# **Disturbance_1**


Changes:
- Mortality dynamics
- Snags ! Biomass turnover.
- Harvest slash combustion
- Harvest seedling planting
- Root depth increases by DBH => water access differs for sm trees

Disturbance_1 branch changes:

Summary:

(Root depth & water use)
- Root depth & water access can scale by tree size! FATES hydro root min/max depth/dbh paramneters (x5) can now be used to set PFT root depth by DBH in coordination with fnrt_prof root profile shape parameters.  BTRAN resulting from new root profiles is calculated by cohort, NOT by pft x site.
- New parameter changes stomatal sensititivy to increasing soil matric potential by allowing plant BTRAN downreg to be a) linear with increasing SMP (isohydric); or b) exponential increase in (1-BTRAN) (anisohydric)

(Fuels)
- New parameter for live -> CWD destination fraction from branch turnover. Previously, fractions from mortality and turnover were the same and were, by default, dominated by 1000 hr fuels.
- SNAGS !!!! Dying tree biomass that is not combusted or exported now enters snag pools (no decomposition). Snag fall rate to litter/cwd pools is dictated by a new parameter. Snag leaves, twigs, and small branches can combust during fire given that average patch scorch height is greater than [X] m.

(c-starvation)
- Parameter added for c-starvation storage tolerance. The fraction of target storage at which mortality begins can now be set. Background mortality can now be scaled by by a stress multiplier to represent a stress interaction w/  undefined mortality agent (e.g. insects/pathogens).

(Management)
- CTSM harvest layers from landuse timeseries can now be used to prescribe “regeneration harvest” events (i.e. harvest AND planting). A new parameter has been added to prescribe planted seedling mass by PFT. PFTs can be planted on a site where they were not present at run start. The natural seedbank is sent to the soil decay pool.
- Parameters added for the proportion of live harvested and existing dead mass within harvest-disturbed areas that get combusted as slash during harvest events.  Previously, mass EXCEPT for exported bole fractions was added to litter/cwd pools.

(Misc Fixes)
- Hydraulic failure mortality is now delayed until the first yr July 1st, as early run hydr mortality was occuring before soil moisture was spun up.
- New parameter to delay temperature-based mortality so that the initial cohorts are not murdered due to a Jan 1 model start and no chance to grow/harden.

(Optional Temperature-based mortality)
- Temperature-based mortalities now based on daily min/max temperature INSTEAD of mean temperature.
- Seedling temperature tolerances set by separate parameters to represent seedling vs hardened stems.
- heat mortality added (like freeze mortality)

Added / Changed-usage parameters:
(+) 13
(Δ) 9

Water use/access:
Δ (definition change) zroot_k: Now applies outside of FATES Hydro
Δ (definition change) zroot_max_dbh: Now applies outside of FATES Hydro
Δ (definition change) zroot_max_z: Now applies outside of FATES Hydro
Δ (definition change) zroot_min_dbh: Now applies outside of FATES Hydro
Δ (definition change) zroot_min_z: Now applies outside of FATES Hydro
+ fates_smp_coeff : Lower (non-zero) = linear BTRAN ~ SMP. Higher = anisohydric, BTRAN increasing rapidly only @ extreme soil matric potentials.

Mortality:
+ fates_mort_heat_tol (pft) :maximum temperature tolerance, post-seedling; degress C.
+ fates_mort_heat_tol_seedling (pft): maximum temperature tolerance, seedling; degrees C
+ fates_mort_scalar_heatstress (pft) : maximum mortality rate from heat stress; 1/yr.
+ fates_freezetol_seedling (pft): minimum temperature tolerance, seedling
Δ  (definition change) fates_mort_freezetol (pft): minimum temperature tolerance, post-seedling; degrees C
+ fates_temp_delay : Days since run start required for turning temperature-based mortality (heat,freeze) “on”.
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

For more information on the FATES model, see our [User's Guide](https://fates-users-guide.readthedocs.io/en/latest/) and [technical documentation](https://fates-docs.readthedocs.io/en/latest/index.html).  

Please submit any questions you may have to the [FATES Github Discussions board](https://github.com/NGEET/fates/discussions).

To receive email updates about forthcoming release tags, regular meeting notifications, and other important announcements, please join the [FATES Google group](https://groups.google.com/g/fates_model).

## Important Guides:
------------------------------

[User's Guide](https://fates-users-guide.readthedocs.io/en/latest/)

[How to Contribute](https://github.com/NGEET/fates/blob/master/CONTRIBUTING.md)

[Table of FATES and Host Land Model API compatability](https://fates-users-guide.readthedocs.io/en/latest/user/Table-of-FATES-API-and-HLM-STATUS.html)

[List of Unsupported or Broken Features](https://fates-users-guide.readthedocs.io/en/latest/user/Current-Unsupported-or-Broken-Features.html)

[Code of Conduct](https://github.com/NGEET/fates/blob/master/CODE_OF_CONDUCT.md)

## Important Note:
------------------------------

**Most users should not need to directly clone this repository.  FATES needs to be run through a host model, and all supported host-models are in charge of cloning and loading the fates software.**

FATES has support to be run via the Energy Exascale Earth System Model (E3SM), the Community Earth System Model (CESM), or its land component, the Community Terrestrial Systems Model (CTSM).

https://github.com/E3SM-Project/E3SM

https://github.com/ESCOMP/cesm

The FATES, E3SM and CTSM teams maintain compatability of the NGEET/FATES master branch with the E3SM master and CTSM master branches respectively. There may be some modest lag time in which the latest commit on the FATES master branch is available to these host land models (HLM) by default.  This is typically correlated with FATES development updates forcing necessary changes to the FATES API.  See the table of [FATES API/HLM compatibility](https://fates-users-guide.readthedocs.io/en/latest/user/Table-of-FATES-API-and-HLM-STATUS.html) for information on which fates tag corresponds to which HLM tag or commit.  

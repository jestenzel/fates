module EDBtranMod

  !-------------------------------------------------------------------------------------
  ! Description:
  !
  ! ------------------------------------------------------------------------------------

  use EDPftvarcon       , only : EDPftvarcon_inst
  use FatesConstantsMod , only : tfrz => t_water_freeze_k_1atm
  use FatesConstantsMod , only : itrue,ifalse,nearzero
  use EDTypesMod        , only : ed_site_type,       &
       ed_patch_type,      &
       ed_cohort_type,     &
       maxpft
  use shr_kind_mod      , only : r8 => shr_kind_r8
  use FatesInterfaceTypesMod , only : bc_in_type, &
       bc_out_type, &
       numpft
  use FatesInterfaceTypesMod , only : hlm_use_planthydro
  use FatesGlobals      , only : fates_log
  use FatesAllometryMod , only : set_root_fraction, set_root_fraction_dbh ![JStenzel]

  !
  implicit none
  private

  public :: btran_ed
  public :: get_active_suction_layers
  public :: check_layer_water

contains

  ! ====================================================================================

  logical function check_layer_water(h2o_liq_vol, tempk)

    implicit none
    ! Arguments
    real(r8),intent(in) :: h2o_liq_vol
    real(r8),intent(in) :: tempk

    check_layer_water = .false.

    if ( h2o_liq_vol .gt. 0._r8 ) then
       if ( tempk .gt. tfrz-2._r8) then
          check_layer_water = .true.
       end if
    end if
    return
  end function check_layer_water

  ! =====================================================================================

  subroutine get_active_suction_layers(nsites, sites, bc_in, bc_out)

    ! Arguments

    integer,intent(in)                      :: nsites
    type(ed_site_type),intent(inout),target :: sites(nsites)
    type(bc_in_type),intent(in)             :: bc_in(nsites)
    type(bc_out_type),intent(inout)         :: bc_out(nsites)

    ! !LOCAL VARIABLES:
    integer  :: s                 ! site
    integer  :: j                 ! soil layer
    !------------------------------------------------------------------------------

    do s = 1,nsites
       if (bc_in(s)%filter_btran) then
          do j = 1,bc_in(s)%nlevsoil
             bc_out(s)%active_suction_sl(j) = check_layer_water( bc_in(s)%h2o_liqvol_sl(j),bc_in(s)%tempk_sl(j) )
          end do
       else
          bc_out(s)%active_suction_sl(:) = .false.
       end if
    end do

  end subroutine get_active_suction_layers

  ! =====================================================================================

  subroutine btran_ed( nsites, sites, bc_in, bc_out)

    use FatesPlantHydraulicsMod, only : BTranForHLMDiagnosticsFromCohortHydr


    ! ---------------------------------------------------------------------------------
    ! Calculate the transpiration wetness function (BTRAN) and the root uptake
    ! distribution (ROOTR).
    ! Boundary conditions in: bc_in(s)%eff_porosity_sl(j)    unfrozen porosity
    !                         bc_in(s)%watsat_sl(j)          porosity
    !                         bc_in(s)%active_uptake_sl(j)   frozen/not frozen
    !                         bc_in(s)%smp_sl(j)             suction
    ! Boundary conditions out: bc_out(s)%rootr_pasl          root uptake distribution
    !                          bc_out(s)%btran_pa            wetness factor
    ! ---------------------------------------------------------------------------------

    ! Arguments

    integer,intent(in)                      :: nsites
    type(ed_site_type),intent(inout),target :: sites(nsites)
    type(bc_in_type),intent(in)             :: bc_in(nsites)
    type(bc_out_type),intent(inout)         :: bc_out(nsites)


    !
    ! !LOCAL VARIABLES:
    type(ed_patch_type),pointer             :: cpatch ! Current Patch Pointer
    type(ed_cohort_type),pointer            :: ccohort ! Current cohort pointer
    integer  :: s                 ! site
    integer  :: j                 ! soil layer
    integer  :: ifp               ! patch vector index for the site
    integer  :: ft                ! [old: plant functional type index] [JStenzel redifine] current cohort pft
    real(r8) :: smp_node          ! matrix potential
    real(r8) :: rresis            ! suction limitation to transpiration independent
    ! of root density
    real(r8) :: pftgs(maxpft)     ! pft weighted stomatal conductance m/s
    real(r8) :: temprootr
    real(r8) :: sum_pftgs         ! sum of weighted conductances (for normalization)
    real(r8), allocatable :: root_resis(:,:)  ! [JStenzel def change]  patch (pft x layer) sum from cohorts:  fractional btran scaled by cohort canopy area
    real(r8), allocatable :: extract_pf(:,:)  ! [JStenzel] root extraction (sum of cohort root fraction x weighted stomatal conductance )
    real(r8), allocatable :: cohort_resis(:)  ![JStenzel added] cohort x layer  resistance
    real(r8) :: resis_sum(maxpft) ![JStenzel] patch (pft ) sum from cohorts:  fractional btran scaled by cohort canopy area
    real(r8) :: grav_potential    ![Penalty for large trees] default will be 0.01 MPa m-1
    !------------------------------------------------------------------------------

    associate(                                 &
         smpsc     => EDPftvarcon_inst%smpsc          , &  ! INTERF-TODO: THESE SHOULD BE FATES PARAMETERS
         smpso     => EDPftvarcon_inst%smpso          , &  ! INTERF-TODO: THESE SHOULD BE FATES PARAMETERS
         smp_coeff  => EDPftvarcon_inst%smp_coeff  &   ![JStenzel added]
         )

    do s = 1,nsites

       allocate(root_resis(numpft,bc_in(s)%nlevsoil))
       allocate(extract_pf(numpft,bc_in(s)%nlevsoil)) ! [JStenzel add]
       allocate(cohort_resis(bc_in(s)%nlevsoil)) ! [JStenzel add]

       bc_out(s)%rootr_pasl(:,:) = 0._r8

       ifp = 0


       cpatch => sites(s)%oldest_patch
       do while (associated(cpatch))
          if(cpatch%nocomp_pft_label.ne.0)then ! only for veg patches
             ifp=ifp+1

             root_resis(:,:) = 0._r8  !!! [Jstenzel?]
             extract_pf(:,:) = 0._r8  !!! [Jstenzel?]
             resis_sum(1:maxpft) = 0._r8 ! [JStenzel]
             pftgs(1:maxpft) = 0._r8 !!!! [JStenzel moved] is there any reason that this can't be here?

             ! THIS SHOULD REALLY BE A COHORT LOOP ONCE WE HAVE rootfr_ft FOR COHORTS (RGK)

             !!!!do ft = 1,numpft
                !!!! JStenzel start cohort loop.

                ccohort => cpatch%tallest
                do while (associated(ccohort))    ![JStenzel] start cohort loop
                   ft = ccohort%pft

                     call set_root_fraction_dbh(sites(s)%rootfrac_scr, ft, sites(s)%zi_soil, & ![JStenzel new subroutine]
                          bc_in(s)%max_rooting_depth_index_col, ccohort%dbh )
                     !call set_root_fraction(sites(s)%rootfrac_scr, ft, sites(s)%zi_soil, & !
                     !    bc_in(s)%max_rooting_depth_index_col)

                   ccohort%btran_coh= 0.0_r8
                   cpatch%btran_ft(ft) = 0.0_r8
                   grav_potential = smp_coeff(ft) * ccohort%hite      ![JStenzel] ht (m) * grav potential (MPa m-1)
                   do j = 1,bc_in(s)%nlevsoil

                      ! Calculations are only relevant where liquid water exists
                      ! see clm_fates%wrap_btran for calculation with CLM/ALM

                      if ( check_layer_water(bc_in(s)%h2o_liqvol_sl(j),bc_in(s)%tempk_sl(j)) )  then

                         smp_node = max( ( smpsc(ft) + grav_potential ), bc_in(s)%smp_sl(j))     ![JStenzel]

                         !rresis  = min( (bc_in(s)%eff_porosity_sl(j)/bc_in(s)%watsat_sl(j))*      &
                           !   (smp_node - smpsc(ft)) / (smpso(ft) - smpsc(ft)), 1._r8)

                         ![JStenzel add] Exponential model of btran x smp. Added to represent
                         ! varying degrees of non-fatal hydraulic dysfunction across spp or any other
                         ! non-linear behavior affecting stomatal sensitivity to smp. Previously,
                         ! variations in stomatal slope were impacting water use efficiency, but
                         ! not the duration of the water uptake period during the growing season and therefore
                         ! not the duration of the c-store depletion period during drough. A pft that had a higher
                         ! WUE used similar amounts of water as a low WUE pft
                         ! due to the linear negative feedback between water use and btran. With this modification
                         ! 2 pfts can face different BTRAN values at the same SMP conditions, and
                         ! therefore different durations of cstarvation based degree of isohydry and
                         ! resulting pre-drought water use. Relative to a hypothetical anisohydric spp
                         ! This new scheme allows a pft to have both have higher stomatal conductance
                         ! at low water stress and lower stomatal conductance as stress increases.
                         rresis  = min( (bc_in(s)%eff_porosity_sl(j)/bc_in(s)%watsat_sl(j))*       &    ![JStenzel] Add limitation based on tree height.
                         (smp_node - (smpsc(ft) + grav_potential ) ) / (smpso(ft) - smpsc(ft)), 1._r8)

                         cohort_resis(j) = sites(s)%rootfrac_scr(j) * rresis    ! [JStenzel] This root fraction is now dependent on pft AND dbh
                         root_resis(ft,j) = root_resis(ft,j) + cohort_resis(j) * &    ![JStenzel] patch (pft x layer) sum from cohorts:  fractional btran scaled by cohort canopy area
                              ccohort%c_area
                         resis_sum(ft) = resis_sum(ft) + cohort_resis(j) * &  ![JStenzel] patch (pft) sum from cohorts
                              ccohort%c_area
                        ! root_resis(ft) = root_resis(ft,j) + sites(s)%rootfrac_scr(j)*rresis

                         ! root water uptake is not linearly proportional to root density,
                         ! to allow proper deep root funciton. Replace with equations from SPA/Newman. FIX(RF,032414)

                      else
                         cohort_resis(j) = 0._r8
                         root_resis(ft,j) = 0._r8
                      end if

                      ccohort%btran_coh = ccohort%btran_coh +  cohort_resis(j)  ![JStenzel]


                   end do !j

                   ![JStenzel partial] Was thinking about calculating btran_ft here, but I'd need to
                   !weigh by cohort g_sb_laweight and then later divide by that total. However
                   ! if conductance = 0 (not sure why?), post-calc btran would be forced to zero also.
                   !cpatch%btran_ft(ft) = cpatch%btran_ft(ft)

                   ! Normalize root resistances to get layer contribution to ET
                   do j = 1,bc_in(s)%nlevsoil
                      if (ccohort%btran_coh  >  nearzero) then
                         cohort_resis(j) = cohort_resis(j)/ccohort%btran_coh
                      else
                         cohort_resis(j) = 0._r8
                      end if
                      !![Jstenzel added] Calculate patch H2O extraction contribution resulting from
                      ! cohort conductance x root layer distribution for extraction calcs below.
                      extract_pf(ft,j) = extract_pf(ft,j) + cohort_resis(j) * ccohort%g_sb_laweight   ! [m/s] * [m2]
                   end do


                   pftgs(ft) = pftgs(ft) + ccohort%g_sb_laweight

                   ccohort => ccohort%shorter ![JStenzel]
                end do ![JStenzel] !Cohort

             !!!!end do !PFT  [JStenzel remove pft loop]

             ! PFT-averaged point level root fraction for extraction purposese.
             ! The cohort's conductance g_sb_laweighted, contains a weighting factor
             ! based on the cohort's leaf area. units: [m/s] * [m2]


            ! ccohort => cpatch%tallest
            ! do while(associated(ccohort))
                !pftgs(ccohort%pft) = pftgs(ccohort%pft) + ccohort%g_sb_laweight
               ! ccohort => ccohort%shorter
             !enddo

             ! Process the boundary output, this is necessary for calculating the soil-moisture
             ! sink term across the different layers in driver/host.  Photosynthesis will
             ! pass the host a total transpiration for the patch.  This needs rootr to be
             ! distributed over the soil layers.
             sum_pftgs = sum(pftgs(1:numpft))

             ![JStenzel added] Even though btran is now a cohort variable, we still need to normalize
             !a pft-level root_resis for when sum Gc = 0 and thus there are no weighted Gc
             !contributions to use.
             do j= 1, bc_in(s)%nlevsoil
                do ft = 1,numpft
                   if( resis_sum(ft) > 0._r8 ) then
                      root_resis(ft,j) = root_resis(ft,j) / resis_sum(ft)
                   end if
                end do
             end do

             do j = 1, bc_in(s)%nlevsoil
                bc_out(s)%rootr_pasl(ifp,j) = 0._r8
                do ft = 1,numpft

                   if( sum_pftgs > 0._r8)then !prevent problem with the first timestep - might fail
                      !bit-retart test as a result? FIX(RF,032414)
                      bc_out(s)%rootr_pasl(ifp,j) = bc_out(s)%rootr_pasl(ifp,j) + &
                           !root_resis(ft,j) * pftgs(ft)/sum_pftgs
                           extract_pf(ft,j) / sum_pftgs  ![JStenzel]

                   else

                      bc_out(s)%rootr_pasl(ifp,j) = bc_out(s)%rootr_pasl(ifp,j) + &
                           root_resis(ft,j) * 1._r8/real(numpft,r8)
                   end if
                enddo
             enddo

             ! Calculate the BTRAN that is passed back to the HLM
             ! used only for diagnostics. If plant hydraulics is turned off
             ! we are using the patchxpft level btran calculation

            ! if(hlm_use_planthydro.eq.ifalse) then
                !weight patch level output BTRAN for the
            !    bc_out(s)%btran_pa(ifp) = 0.0_r8
            !    do ft = 1,numpft
            !       if( sum_pftgs > 0._r8)then !prevent problem with the first timestep - might fail
            !          !bit-retart test as a result? FIX(RF,032414)
            !          bc_out(s)%btran_pa(ifp)   = bc_out(s)%btran_pa(ifp) + cpatch%btran_ft(ft)  * pftgs(ft)/sum_pftgs
            !       else
            !          bc_out(s)%btran_pa(ifp)   = bc_out(s)%btran_pa(ifp) + cpatch%btran_ft(ft) * 1./numpft
            !       end if
            !    enddo
            ! end if

!!!! [JStenzel added start]
             if(hlm_use_planthydro.eq.ifalse) then
                !weight patch level output BTRAN for the
                bc_out(s)%btran_pa(ifp) = 0.0_r8
                ccohort => cpatch%tallest
                do while (associated(ccohort))

                   if( sum_pftgs > 0._r8)then !prevent problem with the first timestep - might fail
                      !bit-retart test as a result? FIX(RF,032414)
                      bc_out(s)%btran_pa(ifp)   = bc_out(s)%btran_pa(ifp) + ccohort%btran_coh  * ccohort%g_sb_laweight/sum_pftgs
                   else
                      bc_out(s)%btran_pa(ifp)   = bc_out(s)%btran_pa(ifp) + ccohort%btran_coh * 1./cpatch%countcohorts
                   end if

                   ccohort => ccohort%shorter

                end do ! cohort
             end if
!!! [JStenzel end]

             temprootr = sum(bc_out(s)%rootr_pasl(ifp,1:bc_in(s)%nlevsoil))

             if(abs(1.0_r8-temprootr) > 1.0e-10_r8 .and. temprootr > 1.0e-10_r8)then
                !write(fates_log(),*) 'error with rootr in canopy fluxes',temprootr,sum_pftgs
                do j = 1,bc_in(s)%nlevsoil
                   bc_out(s)%rootr_pasl(ifp,j) = bc_out(s)%rootr_pasl(ifp,j)/temprootr
                enddo
             end if
          endif ! not bare ground
          cpatch => cpatch%younger
       end do

       deallocate(root_resis)
       deallocate(extract_pf) ![JStenzel]
       deallocate(cohort_resis) ![JStenzel]

    end do

    if(hlm_use_planthydro.eq.itrue) then
       call BTranForHLMDiagnosticsFromCohortHydr(nsites,sites,bc_out)
    end if

  end associate

end subroutine btran_ed


end module EDBtranMod

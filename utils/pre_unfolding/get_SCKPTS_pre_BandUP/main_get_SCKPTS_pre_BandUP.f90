!    Copyright (C) 2013, 2014 Paulo V. C. Medeiros
!
!    This file is part of BandUP: Band Unfolding code for Plane-wave based calculations.
!
!    BandUP is free software: you can redistribute it and/or modify
!    it under the terms of the GNU General Public License as published by
!    the Free Software Foundation, either version 3 of the License, or
!    (at your option) any later version.
!
!    BandUP is distributed in the hope that it will be useful,
!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!    GNU General Public License for more details.
!
!    You should have received a copy of the GNU General Public License
!    along with BandUP.  If not, see <http://www.gnu.org/licenses/>.
program get_wavefunc_SCKPTS_needed_for_EBS
use general_io
use io_routines
use read_vasp_files
use write_vasp_files
use math
use band_unfolding
implicit none
character(len=127) :: input_file_prim_cell, input_file_supercell, input_file_pc_kpts, &
                      outpt_file_SC_kpts
real(kind=dp), dimension(:,:), allocatable :: k_starts, k_ends
type(crystal_3D), allocatable :: crystal_pc, crystal_SC
real(kind=dp), dimension(1:3,1:3) :: matrix_M
real(kind=dp), dimension(1:3) :: point
integer :: n_irr_unfolding_SCKPTS,ikpt,i,ios,n_selec_pcbz_dirs,idir, &
           n_decimals, total_size_float_format, icoord
type(vec3d), dimension(:), allocatable :: irr_unfolding_SCKPTS, irr_unfolding_SCKPTS_frac_coords, &
                                          aux_irr_unfolding_SCKPTS, aux_irr_unfolding_SCKPTS_frac_coords
character(len=254) :: file_line
character(len=127) :: str_n_decimals, str_total_size_float_format, float_format
! Variables for the symmetry analysis
integer, dimension(:), allocatable :: n_pckpts_dirs,n_dirs_for_EBS_along_pcbz_dir, &
                                      neqv_dirs_pcbz, neqv_dirs_SCBZ, ncompl_dirs, n_irr_compl_dirs
type(irr_bz_directions), dimension(:), allocatable :: dirs_req_for_symmavgd_EBS_along_pcbz_dir
type(vec3d), dimension(:), allocatable :: considered_kpts_list
type(selected_pcbz_directions) :: pckpts_to_be_checked
type(geom_unfolding_relations_for_each_SCKPT) :: GUR !! Geometric Unfolding Relations
integer :: i_req_dir, ikpt2, i_irr_kpt, aux_n_irr_unfolding_SCKPTS
logical :: get_all_kpts_needed_for_EBS_averaging,stop_if_not_commensurate,are_commens, &
           stop_if_GUR_fails, pc_is_prim_cell, write_attempted_pc_corresp_to_input_pc, &
           SC_is_prim_cell, write_attempted_pc_corresp_to_SC, print_GUR
type(crystal_3D), allocatable :: crystal_SC_reduced_to_prim_cell, crystal_pc_reduced_to_prim_cell
!!!**********************************************************************************************

    stop_if_not_commensurate = .FALSE.
    stop_if_GUR_fails = .TRUE.
    get_all_kpts_needed_for_EBS_averaging = .TRUE.
    write_attempted_pc_corresp_to_input_pc = .TRUE.
    print_GUR = .FALSE.
    write_attempted_pc_corresp_to_SC = .TRUE.
    input_file_prim_cell = 'prim_cell_lattice.in'
    input_file_supercell = 'supercell_lattice.in'
    input_file_pc_kpts = 'KPOINTS_prim_cell.in'
    outpt_file_SC_kpts = 'KPOINTS_supercell.out'

    call print_welcome_messages(package_version)
    write(*,'(A)')'               Pre-processing utility "get_SCKPTS_pre_BandUP"'
    write(*,'(A)')'   >>> Getting the SC-KPTS you will need for your plane-wave calculation <<<'
    write(*,*)
    call get_crystal_from_file(crystal_pc,input_file=input_file_prim_cell, &
                               stop_if_file_not_found=.TRUE.)
    call get_crystal_from_file(crystal_SC,input_file=input_file_supercell, &
                               stop_if_file_not_found=.TRUE.)
    ! Checking if the SC and PC are commensurate
    call check_if_pc_and_SC_are_commensurate(commensurate=are_commens, M=matrix_M, &
                                             b_matrix_pc=crystal_pc%rec_latt_vecs, &
                                             B_matrix_SC=crystal_SC%rec_latt_vecs, &
                                             tol=default_tol_for_int_commens_test)
    if(are_commens)then
        call print_message_commens_test(commensurate=are_commens,M=matrix_M, &
                                        stop_if_not_commens=stop_if_not_commensurate)
    else
        if(stop_if_not_commensurate)then
            call print_message_commens_test(commensurate=are_commens,M=matrix_M, &
                                            stop_if_not_commens=stop_if_not_commensurate)
            stop
        endif
    endif
    !! Reading selected pckpts from the input file
    call read_pckpts_selected_by_user(k_starts=k_starts, k_ends=k_ends, &
                                      ndirs=n_selec_pcbz_dirs, n_kpts_dirs=n_pckpts_dirs, &
                                      input_file=input_file_pc_kpts, &
                                      b_matrix_pc=crystal_pc%rec_latt_vecs)
    call get_all_irr_dirs_req_for_symmavgd_EBS(dirs_req_for_symmavgd_EBS_along_pcbz_dir, &
                                               n_dirs_for_EBS_along_pcbz_dir, &
                                               neqv_dirs_pcbz, neqv_dirs_SCBZ, &
                                               ncompl_dirs, n_irr_compl_dirs,&
                                               crystal_pc_reduced_to_prim_cell, &
                                               pc_is_prim_cell, &
                                               crystal_SC_reduced_to_prim_cell, &
                                               SC_is_prim_cell, &
                                               crystal_pc=crystal_pc, crystal_SC=crystal_SC, &
                                               k_starts=k_starts(:,:),k_ends=k_ends(:,:))
    call write_attempted_pc_assoc_with_input_unit_cell_and_SC(crystal_pc_reduced_to_prim_cell, &
                                                                    crystal_SC_reduced_to_prim_cell, &
                                                                    pc_is_prim_cell,SC_is_prim_cell, &
                                                                    write_attempted_pc_corresp_to_input_pc, &
                                                                    write_attempted_pc_corresp_to_SC)
    call print_symm_analysis_for_selected_pcbz_dirs(dirs_req_for_symmavgd_EBS_along_pcbz_dir, &
                                                    neqv_dirs_pcbz, neqv_dirs_SCBZ, ncompl_dirs, &
                                                    n_irr_compl_dirs)

    ! List of all considered pc-kpts, including the ones chosen by the user and
    ! the ones obtained by symmetry for the complementary directions
    call define_pckpts_to_be_checked(pckpts_to_be_checked, &
                                     dirs_req_for_symmavgd_EBS_along_pcbz_dir,n_pckpts_dirs(:))
    allocate(considered_kpts_list(1:dot_product(n_pckpts_dirs(:), &
                                                n_dirs_for_EBS_along_pcbz_dir(:))))
    ikpt = 0
    do idir=1,n_selec_pcbz_dirs
        do i_req_dir=1,n_dirs_for_EBS_along_pcbz_dir(idir)
            do ikpt2=1, n_pckpts_dirs(idir)
                ikpt = ikpt + 1
                considered_kpts_list(ikpt)%coord(:) = &
                    pckpts_to_be_checked%selec_pcbz_dir(idir)%needed_dir(i_req_dir)%pckpt(ikpt2)%coords(:)
            enddo
        enddo
    enddo
    !! Getting the smallest possible number of SCBZ KPTS for the calculation of the
    !! EBS along the selected direction(s) of the pcbz
    write(*,'(A)')'Getting the needed SCBZ-Kpoints...'
    call get_irr_kpts(n_irr_kpts=aux_n_irr_unfolding_SCKPTS,irr_kpts_list=aux_irr_unfolding_SCKPTS, &
                      irr_kpts_list_frac_coords=aux_irr_unfolding_SCKPTS_frac_coords, &
                      kpts_list=considered_kpts_list,crystal=crystal_SC,reduce_to_bz=.TRUE.)
    call get_geom_unfolding_relations(GUR,aux_irr_unfolding_SCKPTS,pckpts_to_be_checked,crystal_SC)
    
    n_irr_unfolding_SCKPTS = count(GUR%SCKPT_used_for_unfolding(:))
    allocate(irr_unfolding_SCKPTS(1:n_irr_unfolding_SCKPTS), &
             irr_unfolding_SCKPTS_frac_coords(1:n_irr_unfolding_SCKPTS))
    i_irr_kpt = 0
    do ikpt=1,size(GUR%SCKPT_used_for_unfolding(:))
        if(GUR%SCKPT_used_for_unfolding(ikpt))then
            i_irr_kpt = i_irr_kpt + 1
            irr_unfolding_SCKPTS(i_irr_kpt) = aux_irr_unfolding_SCKPTS(ikpt)
            irr_unfolding_SCKPTS_frac_coords(i_irr_kpt) = aux_irr_unfolding_SCKPTS_frac_coords(ikpt)
        endif
    enddo

    call get_geom_unfolding_relations(GUR,irr_unfolding_SCKPTS,pckpts_to_be_checked,crystal_SC)
    call print_message_success_determining_GUR(GUR, stop_if_GUR_fails, is_main_code=.FALSE.) 
    if((GUR%n_pckpts /= GUR%n_folding_pckpts) .and. stop_if_GUR_fails) stop

    n_irr_unfolding_SCKPTS = count(GUR%SCKPT_used_for_unfolding(:))
    if(count(.not. GUR%SCKPT_used_for_unfolding) > 0)then
        write(*,'(A,I0,A)')'WARNING: There seems to be more SC-KPTS than the necessarry (', &
                           count(.not. GUR%SCKPT_used_for_unfolding),' too many).'
    endif

    if(print_GUR)then 
        call print_geom_unfolding_relations(GUR,irr_unfolding_SCKPTS, &
                                            crystal_pc%rec_latt_vecs, &
                                            crystal_SC%rec_latt_vecs)
    endif

    write(*,'(A,I0,A)')'A total of ',n_irr_unfolding_SCKPTS, &
                       " SCBZ-Kpoints will be needed to obtain a symmetry-averaged EBS along the selected direction(s) of the reference pcbz."
    write(*,"(3A)")'>>> The SCBZ-Kpoints you will need to run your plane-wave calculation have been stored in the file "',trim(adjustl(outpt_file_SC_kpts)),'".'
    if(any(ncompl_dirs > 0))then
        write(*,"(6(A,/),A)")"====================================================================================================", &
                             "NOTICE:                                                                                             ", &
                             "       We have considered more pcbz directions than what you asked for. We did this because the SC", &
                             "       and the pc belong to different symmetry groups, and, therefore, some pcbz k-points that  ", &
                             "       are equivalent by symmetry operations of the pc might not be equivalent by symmetry ops. of", & 
                             "       the SC. Don't worry, though: Only irreducible complementary directions have been kept.    ", &
                             "===================================================================================================="
    endif
    !!! Writing results to the output file
    n_decimals = nint(abs((log10(default_symprec))))
    total_size_float_format = 3 + n_decimals ! The numbers will be between -1 and 1
    write(str_n_decimals,'(I0)') n_decimals
    write(str_total_size_float_format,'(I0)') total_size_float_format
    float_format = 'f' // trim(adjustl(str_total_size_float_format)) // '.' // trim(adjustl(str_n_decimals))
    open(unit=03, file=outpt_file_SC_kpts)
        open(unit=04, file=input_file_pc_kpts)
            read(04,'(A)')file_line
            write(03,'(A)')trim(adjustl(file_line))//' (this is exactly the header of the input kpts file) ' // trim(adjustl(file_header_BandUP_short))
        close(04)
        write(03,'(I0)')n_irr_unfolding_SCKPTS
        write(03,'(A)')'Reciprocal (fractional) coords. w.r.t. the SCRL vectors:' 
        do ikpt=1, n_irr_unfolding_SCKPTS
            point(:) = irr_unfolding_SCKPTS_frac_coords(ikpt)%coord(:)
            do icoord=1,3
                point(icoord) = real(nint(point(icoord)/default_symprec),kind=dp) * default_symprec
            enddo
            write(03,'(3(2X,'//trim(adjustl(float_format))//'),2X,I1)')(point(i), i=1,3),1
        enddo
        write(03,'(A)')''
        write(03,'(A)')''
        write(03,'(A)')'! The above SCKPTS (and/or some other SCKPTS related to them by symm. ops. of the SCBZ)' 
        write(03,'(A)')'! unfold onto the pckpts listed below (selected by you) (and/or some other pckpts related to them by symm. ops. of the pcbz): '
        write(03,'(A)')'! (Fractional coords. w.r.t. the pcrl vectors) '
        open(unit=04, file=input_file_pc_kpts)
            ios=0
            do while(ios==0)
                read(04,'(A)',iostat=ios)file_line
                if(ios==0) write(03,'(A)')trim(file_line)
            enddo
        close(04)
    close(03)

    if(.not. are_commens)then
        call print_message_commens_test(commensurate=are_commens,M=matrix_M, &
                                        stop_if_not_commens=stop_if_not_commensurate)
    endif

end program get_wavefunc_SCKPTS_needed_for_EBS

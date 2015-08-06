/*******************************************************************************
* Filename: cegsV_ag_create_model_design_file_no_tra.sas
*
* Author: Justin M Fear | jfear@ufl.edu 
*
* Description: Models are created using the same iterative process for each
* genes.  So Model 1 will be the same for all genes. I wan't to create a design
* file to relate what location the gene was added to the model number.  CEGS
* will be different from DGPR because I used isoforms in DGPR.
*
*******************************************************************************/

/* Libraries
libname sem '!MCLAB/cegs_sem_sd_paper/sas_data';
filename mymacros '!MCLAB/cegs_sem_sd_paper/sas_programs/mclib_SAS';
options SASAUTOS=(sasautos mymacros);
*/

data SEM.cegsV_ag_model_no_tra;
    informat model $14.;
    informat modelnum best12.;
    informat path $30.;
    input model$ modelnum path$;
    datalines;
        Model_Baseline   0  .
        Model_1   1    Sxl->gene
        Model_2   2    Yp2->gene
        Model_3   3    dsx->gene
        Model_4   4    fru->gene
        Model_5   5    Spf45->gene
        Model_6   6    fl_2_d->gene
        Model_7   7    her->gene
        Model_8   8    ix->gene
        Model_9   9    snf->gene
        Model_10  10   tra2->gene
        Model_11  11   vir->gene
        Model_12  12   gene->Sxl
        Model_13  13   gene->Yp2
        Model_14  14   gene->dsx
        Model_15  15   gene->fru
        Model_16  16   gene->Spf45
        Model_17  17   gene->fl_2_d
        Model_18  18   gene->her
        Model_19  19   gene->ix
        Model_20  20   gene->snf
        Model_21  21   gene->tra2
        Model_22  22   gene->vir
        Model_23  23   Sxl->gene->fru
        Model_24  24   dsx->gene->Yp2
        Model_25  25   Spf45->gene->Sxl
        Model_26  26   fl_2_d->gene->Sxl
        Model_27  27   her->gene->Yp2
        Model_28  28   ix->gene->Yp2
        Model_29  29   snf->gene->Sxl
        Model_30  30   tra2->gene->dsx
        Model_31  31   tra2->gene->fru
        Model_32  32   vir->gene->Sxl
        ;
    run;

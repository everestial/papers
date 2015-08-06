/*******************************************************************************
* Filename: cegsV_export_adding_genes_nofilter_yp2_no_tra.sas
*
* Author: Justin M Fear | jfear@ufl.edu 
*
* Description: Export the nofilter Yp2 BIC stack with the model paths.
*
*******************************************************************************/

/* Libraries
libname sem '!MCLAB/cegs_sem_sd_paper/sas_data';
libname dmel '!MCLAB/useful_dmel_data/flybase551/sas_data';
filename mymacros '!MCLAB/cegs_sem_sd_paper/sas_programs/mclib_SAS';
options SASAUTOS=(sasautos mymacros);
*/

/* Merge to Path List */
    proc sort data=SEM.cegsV_ag_yp2_stack_bic_no_tra;
        by model;
        run;

    proc sort data=SEM.cegsV_ag_model_no_tra;
        by model;
        run;

    data merged;
        retain model modelnum gene path bic;
        merge SEM.cegsV_ag_yp2_stack_bic_no_tra (in=in1) SEM.cegsV_ag_model_design_file (in=in2);
        by model;
        run;

/* Sort and export */
    proc sort data=merged;
        by gene modelnum;
        run;

    data merged2;
        set merged;
        drop modelnum;
        run;

    proc export data=merged2 
            outfile='!MCLAB/cegs_sem_sd_paper/analysis_output/adding_genes/cegsV_ag_yp2_BIC_w_model_path_no_tra.csv'
            dbms=csv replace;
        putnames=yes;
        run;

/* Clean up */
    proc datasets nolist;
        delete bic;
        delete merged;
        delete merged2;
        run; quit;

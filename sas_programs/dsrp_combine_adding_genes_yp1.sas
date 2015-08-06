/*
libname sem '!MCLAB/cegs_sem_sd_paper/sas_data';
filename mymacros '!MCLAB/cegs_sem_sd_paper/sas_programs/mclib_SAS';
options SASAUTOS=(sasautos mymacros);
*/

*libname addgen '!MCLAB/cegs_sem_sd_paper/adding_genes/yp1/sas_data';
libname addgen '/home/jfear/tmp/yp1/sas_data';

*Get baseline BIC value;
data _null_;
    set SEM.dsrp_sex_det_gene_cov_model_bic;
    call symput('baseline', trim(left(BIC)));
    run;

data baseline;
    format gene $ 12.;
    format model $ 12.;
    format bic best8.;
    model = 'baseline';
    bic = &baseline;
    run;

*Combine all genes into a single dataset;
%macro combine_bic(gene);
    %if %sysfunc(exist(addgen.&gene)) %then %do;
        data &gene;
            set addgen.&gene baseline;
            gene = "&gene.";
            run;
            
        proc append data=&gene base=combined;
            run;

        proc datasets nolist;
            delete &gene;
            run; quit;
    %end;
    %else %do;
        /* I did not run the key sex det genes because they were already in the
         * model. So they should not have a dataset. Check to make sure I got
         * everything elese. */
        data misgene;
            format gene $12.;
            gene = "&gene";
            run;

        proc append data=misgene base=checks;
            run;
    %end;
%mend;

proc printto log='/home/jfear/tmp/yp1.log' new;
run;
%iterdataset(dataset=SEM.dsrp_gene_list, function=%nrstr(%combine_bic(&symbol)));
*%combine_bic(Rbp1);
proc printto log=log new;
run;

* checks looks good;

/* The datasets in addgen do not contain a single gene. In other words I had
 * some appending issues. So now genes are in the datset multiple times. Just
 * sort nodupkey to get things right.
 */

/* Check for dups
proc sort data=combined nodupkey out=combined_uniq;
    by gene model;
    run;
*/

/* Create Perminant stacked datset */
proc sort data=combined;
    by gene;
    run;

proc freq data=combined noprint;
    table gene / out=gene_count;
    run;

data SEM.dsrp_adding_genes_yp1_stack_bic;
    set combined;
    run;

proc transpose data=combined out=flip;
    by gene;
    var BIC;
    id model;
    run;

data SEM.dsrp_adding_genes_yp1_sbs_bic;
    retain gene baseline Model_1 Model_2 Model_3 Model_4 Model_5 Model_6
    Model_7 Model_8 Model_9 Model_10 Model_11 Model_12 Model_13 Model_14
    Model_15 Model_16 Model_17 Model_18 Model_19 Model_20 Model_21 Model_22
    Model_23 Model_24 Model_25 Model_26 Model_27 Model_28 Model_29 Model_30
    Model_31;
    set flip;
    drop _name_;
    run;

/* Clean up */
proc datasets nolist;
    delete checks;
    delete combined;
    delete combined_uniq;
    delete flip;
    delete misgene;
    delete sbs;
    delete baseline;
    delete gene_count;
    run; quit;

ods listing; ods html close;

libname event '!MCLAB/event_analysis/sas_data';
libname eventloc '/mnt/store/event_sandbox/sas_data';

/* For each transcript list, calculate the variance in TPM per transcript per cell type */

data subject_list;
   set eventloc.subjects_for_rsem_test;
run;

data design;
   set con.design_by_subject_new;
   keep subject_id cell_type library;
run;

proc sort data=subject_list;
   by subject_id;
proc sort data=design;
   by subject_id;
run;

data design2;
   merge design (in=in1) subject_list (in=in2);
   by subject_id;
   if in1 and in2;
run;

data xs2gene;
   set event.hg19_feature2xs2gene_exp_only2;
   where transcript_id ^? ".1.";
   keep transcript_id gene_id;
run;

proc sort data=xs2gene nodup;
  by transcript_id gene_id;
run;


%macro calcVar(datain,dataout);

data counts;
  set eventloc.&datain.;
  log_tpm=log(tpm+1);
run;

proc sort data=counts;
   by library;
proc sort data=design2;
   by library;
run;

data counts_w_key;
  merge counts (in=in1) design2 (in=in2);
   by library;
  if in1 and in2;
run;

proc sort data=counts_w_key;
   by transcript_id;
proc sort data=xs2gene;
   by transcript_id;
run;

data counts_w_key_gene;
   merge counts_w_key (in=in1) xs2gene (in=in2);
   by transcript_id;
   if in1 and in2;
run;

proc sort data=counts_w_key_gene;
  by cell_type gene_id;
proc means data=counts_w_key_gene noprint;
  by cell_type gene_id;
  var log_tpm;
  output out=var_by_xs_cell mean=tpm_mean stddev=tpm_var;
run;

proc sort data=var_by_xs_cell;
   by gene_id cell_type;
proc transpose data=var_by_xs_cell out=var_sbys;
   by gene_id;
   var tpm_var;
   id cell_type;
run;

proc transpose data=var_by_xs_cell out=mean_sbys;
   by gene_id;
   var tpm_mean;
   id cell_type;
run;

data var_sbys2;
   set var_sbys;
   keep gene_id cd4 cd8 cd19;
   rename cd4=var_cd4 cd8=var_cd8 cd19=var_cd19;
run;

data mean_sbys2;
   set mean_sbys;
   keep gene_id cd4 cd8 cd19;
   rename cd4=mean_cd4 cd8=mean_cd8 cd19=mean_cd19;
run;

proc sort data=mean_sbys2;
   by gene_id;
proc sort data=var_sbys2;
   by gene_id;
run;


data &dataout. ;
  merge mean_sbys2 (in=in1) var_sbys2 (in=in2);
   by gene_id;
  if in1 and in2;
run;

%mend;

%calcVar(hg19_rsem_all_xscripts,hg19_variance_all_gene);
%calcVar(hg19_rsem_75perc_apn5_xscripts,hg19_variance_filt_gene);

/* Make permenant */

data eventloc.hg19_variance_all_gene;
   set hg19_variance_all_xs;
run;

data eventloc.hg19_variance_filtered_gene;
   set hg19_variance_filt_xs;
run;


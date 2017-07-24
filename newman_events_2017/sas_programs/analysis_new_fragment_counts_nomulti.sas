ods listing; ods html close;
libname mm10 '!MCLAB/useful_mouse_data/mm10/sas_data';
libname event '!MCLAB/event_analysis/sas_data';
libname evspl '!MCLAB/conesa_pacbio/sas_data/splicing';
libname conesa '!MCLAB/conesa_pacbio/sas_data';
libname refseq '!MCLAB/event_analysis/refseq_fusions/sas_data';

/* Count number of genes with multigene exonic regions
   After removing multigene exonic regions, count number of:
	exons
	exonic regions
	genes

   	number of singletons
	number of exon fragments
	number of singletons detected
	number of exon fragments detected
	number of genes with exonic pieces detected
	number of short fragments

*/

data genes2keep;
  set event.flag_gene_expressed;
  if flag_gene_only_mult=1 then delete;
  keep gene_id;
run;

data fus_data;
   set mm10.mm10_fusion_si_info_unique;
   if transcript_id='' then delete;
   keep exon_id gene_id fusion_id num_genes_per_fusion flag_multigene;
run;

proc sort data=fus_Data;
   by gene_id;
proc sort data=genes2keep nodup;
   by gene_id;
run;

data fus_data2;
   merge fus_data (in=in1) genes2keep (in=in2);
   by gene_id;
   if in1 and in2;
run;


data single multi;
   set fus_data2;
   if flag_multigene=1 then output multi;
   else output single;
   keep exon_id gene_id fusion_id num_genes_per_fusion;
run;

* 0 multigene exonic regions;
* 201642 single-gene exonic regions;

data multigenes;
   set multi;
   length gene_id2 $18.;
   do i=1 by 1 while(scan(gene_id,i,"|") ^= "");
      gene_id2=scan(gene_id,i,"|");
   output;
   end;
   keep gene_id2 fusion_id;
run;

data multiexons;
   set multi;
   length exon_id2 $18.;
   do i=1 by 1 while(scan(exon_id,i,"|") ^= "");
      exon_id2=scan(exon_id,i,"|");
   output;
   end;
   keep exon_id2 fusion_id;
run; *26,722 exons in multigene regions;

proc sort data=multiexons nodup;
   by exon_id2;
run;


data single_genes;
   set single;
   length gene_id2 $18.;
   do i=1 by 1 while(scan(gene_id,i,"|") ^= "");
      gene_id2=scan(gene_id,i,"|");
   output;
   end;
   keep gene_id2;
run;


data single_exons;
   set single;
   length exon_id2 $18.;
   do i=1 by 1 while(scan(exon_id,i,"|") ^= "");
      exon_id2=scan(exon_id,i,"|");
   output;
   end;
   keep exon_id2;
run; *26,722 exons in multigene regions;

proc sort data=single_genes nodup;
   by gene_id2;
run;
proc sort data=single_exons nodup;
   by exon_id2;
run;


/* Remove fragments from corresponding multigene fusions and recount singletons and fragments */

data multifus;
  set multi;
  keep fusion_id;
run;

data frag2fus2gene;
   set mm10.mm10_exon_fragment_flagged;
   keep fragment_id fusion_id gene_id;
run;

proc sort data=multifus nodup;
   by fusion_id;
proc sort data=frag2fus2gene nodup;
   by fusion_id fragment_id gene_id;
run;

data frag2keep;
   merge frag2fus2gene (in=in1) multifus (in=in2);
   by fusion_id;
   if in2 then delete;
run;

proc sort data=frag2keep;
   by gene_id;
run;

data frag2keep2;
   merge frag2keep (in=in1) genes2keep (in=in2);
   by gene_id;
   if in1 and in2;
run;


/* Now of my remaining fragments, which are singletons?
   which are detected
   and which are too small? */

data singletons;
  set event.features_w_annotations_nomulti;
  where feature_type="fragment";
  keep feature_id flag_feature_on flag_singleton;
  rename feature_id=fragment_id;
run;

data short;
   set event.flagged_fragment_length;
run;

proc sort data=singletons;
   by fragment_id;
proc sort data=short;
   by fragment_id;
proc sort data=frag2keep2;
   by fragment_id;
run;

data frag2keep_w_annot;
  merge frag2keep2 (in=in1) singletons short;
  by fragment_id;
  if in1;
run;

proc freq data=frag2keep_w_annot;
   tables flag_singleton
          flag_singleton*flag_feature_on
          flag_fragment_lt_min_bp;
run;


/*

  flag_singleton    Frequency
  ------------------------------
               0       81835
               1      169979

  flag_singleton     flag_feature_on

  Frequency|
  Percent  |
  Row Pct  |
  Col Pct  |       0|       1|  Total
  ---------+--------+--------+
         0 |  37775 |  44060 |  81835
           |  15.00 |  17.50 |  32.50
           |  46.16 |  53.84 |
           |  37.09 |  29.38 |
  ---------+--------+--------+
         1 |  64059 | 105920 | 169979
           |  25.44 |  42.06 |  67.50
           |  37.69 |  62.31 |
           |  62.91 |  70.62 |
  ---------+--------+--------+
  Total      101834   149980   251814
              40.44    59.56   100.00


    flag_fragment_
         lt_min_bp    Frequency     Percent
  --------------------------------------------
                 0      237040       94.13
                 1       14774        5.87


*/

data genes_on;
  set frag2keep_w_annot;
   where flag_feature_on=1;
   keep gene_id;
run;

proc sort data=genes_on nodup;
  by gene_id;
run;

data genes_on2;
  set genes_on;
  where gene_id ? "|";
run;


/* For each non-multigene fusion, count the number fragments (length filtered)
   and number of detected fragments */

* Number of fragments;

proc sort data=frag2keep_w_annot;
   by fusion_id;
proc freq data=frag2keep_w_annot noprint;
   tables fusion_id / out=num_frags_per_fus;
proc freq data=frag2keep_w_annot noprint;
   where flag_fragment_lt_min_bp = 0;
   tables fusion_id / out=num_frags_per_fus_lf;
proc means data=frag2keep_w_annot noprint;
   by fusion_id;
   var flag_feature_on;
   output out=num_dtct_frags_per_fus sum=num_dtct_frags_per_fus;
run;
proc means data=frag2keep_w_annot noprint;
   where flag_fragment_lt_min_bp = 0;
   by fusion_id;
   var flag_feature_on;
   output out=num_dtct_frags_per_fus_lf sum=num_dtct_frags_per_fus_lf;
run;

data num_frags_per_fus2;
  set num_frags_per_fus;
  rename count=num_frags_per_fus;
  drop percent;
run;


data num_frags_per_fus_lf2;
  set num_frags_per_fus_lf;
  rename count=num_frags_per_fus_lf;
  drop percent;
run;

proc sort data=num_frags_per_fus2;
   by fusion_id;
proc sort data=num_frags_per_fus_lf2;
   by fusion_id;
proc sort data=num_dtct_frags_per_fus;
   by fusion_id;
proc sort data=num_dtct_frags_per_fus_lf;
   by fusion_id;
run;

data frags_per_fus_cnts;
   merge num_frags_per_fus2 (in=in1)
         num_frags_per_fus_lf2 (in=in2)
         num_dtct_frags_per_fus (in=in3)
         num_dtct_frags_per_fus_lf (in=in4);
   by fusion_id;
   if not in1 then num_frags_per_fus=0;
   if not in2 then num_frags_per_fus_lf=0;
   if not in3 then num_dtct_frags_per_fus=0;
   if not in4 then num_dtct_frags_per_fus_lf=0;
   drop _TYPE_ _FREQ_;
run;

proc export data=frags_per_fus_cnts outfile="!MCLAB/event_analysis/analysis_output/event_analysis_fragments_per_region_nomulti.csv" dbms=csv replace;
run;



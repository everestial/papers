ods listing; ods html close;
libname mm10 '!MCLAB/useful_mouse_data/mm10/sas_data';
libname event '!MCLAB/event_analysis/sas_data';
libname evspl '!MCLAB/conesa_pacbio/sas_data/splicing';
libname conesa '!MCLAB/conesa_pacbio/sas_data';
libname refseq '!MCLAB/event_analysis/refseq_fusions/sas_data';

/* Filtering exon fragments and exons by length. The length threshold is a user-defined variable, which we have set at 10bp for this analysis
*/

/* Comment out the below statement when done */
%global minLength;

%let minLength = 10;

/* Command line option for submission script: -set minLength ${MINLENGTH} */

*%let minLength = %sysget(minLength); * <- uncomment this out for submission script;


*Fragments;

data frag_length;
  set mm10.mm10_exon_fragment_flagged;
  fragment_length=fragment_end-fragment_start;
  if fragment_length < &minLength. then flag_fragment_lt_min_bp=1;
  else flag_fragment_lt_min_bp=0;
  keep fragment_id flag_fragment_lt_min_bp;
run;

*Fusions;

data fus_length;
  set mm10.mm10_fusion_si_info_unique;
  fusion_length=fusion_stop-fusion_start;
  if fusion_length < &minLength. then flag_fusion_lt_min_bp=1;
  else flag_fusion_lt_min_bp=0;
  keep fusion_id flag_fusion_lt_min_bp;
run;

* splicing events;
data splice_length;
   set evspl.splicing_events_annot_refseq;
   if event_size < &minLength. then flag_event_lt_min_bp=1;
   else flag_event_lt_min_bp=0;
   keep event_id flag_event_short  flag_event_lt_min_bp;
run;


/* Make permenant */

data event.flagged_fragment_length;
  set frag_length;
run;

data event.flagged_fusion_length;
  set fus_length;
run;


data event.flagged_event_length;
  set splice_length;
run;

/* Count: how many fusions/fragments that are too short? */

proc freq data=event.flagged_fragment_length;
   tables flag_fragment_lt_min_bp;
run;

* 22792 of 360236 fragments less than minimum length;

proc freq data=event.flagged_fusion_length;
   tables flag_fusion_lt_min_bp;
run;

* 268 of 275177 fusions less than minimum length;

proc freq data=event.flagged_event_length;
   tables flag_event_lt_min_bp flag_event_short;
run;

* 113 of 2998454 events less than minimum length;
* 32497 of 2998454 events less than read length;

/* Check: do the short fusions correspond to short fragments? Expectation is that 
   if a fusion is too short, then any fragment corresponding to that fusion should
   also be too short 
   Therefore, the set of fusions that are short should be a subset of the set of
   fusions that have a short fragment */


data frag2fus;
  set mm10.mm10_exon_fragment_flagged;
  keep fusion_id fragment_id;
run;

data short_frag;
  set event.flagged_fragment_length;
  where flag_fragment_lt_min_bp=1;
  keep fragment_id;
run;

data short_fus;
  set event.flagged_fusion_length;
  where flag_fusion_lt_min_bp=1;
  keep fusion_id;
run;

proc sort data=frag2fus;
  by fragment_id fusion_id;
proc sort data=short_frag;
  by fragment_id;
run;

data fus_W_short_frag;
  merge frag2fus (in=in1) short_frag (in=in2);
  by fragment_id;
  if in1 and in2;
  keep fusion_id;
run;

proc sort data=fus_w_short_frag nodup;
  by fusion_id;
proc sort data=short_fus;
  by fusion_id;
run;

data short_fus2fus_w_short;
  merge fus_w_short_frag (in=in1) short_fus (in=in2);
  by fusion_id;
  if in1 then flag_has_short_frag=1; else flag_has_short_frag=0;
  if in2 then flag_short_fusion=1; else flag_short_fusion=0;
run;

proc freq data=short_fus2fus_w_short;
  tables flag_has_short_frag*flag_short_fusion;
run;

/*
   flag_has_short_frag
             flag_short_fusion

   Frequency|
   Percent  |
   Row Pct  |
   Col Pct  |       0|       1|  Total
   ---------+--------+--------+
          1 |  17391 |    268 |  17659
            |  98.48 |   1.52 | 100.00
            |  98.48 |   1.52 |
            | 100.00 | 100.00 |
   ---------+--------+--------+
   Total       17391      268    17659
               98.48     1.52   100.00

All short fusions are a subset of the fusions that have at lease one corresponding short
fragment

*/

DELIMITER $$
CREATE  PROCEDURE `rebuild_hiv_summary`()
BEGIN
                    select @_query_type := "rebuild"; 
					select @_start := now();
					select @_start := now();
					select @_table_version := "flat_hiv_summary_v2.12";

					set session sort_buffer_size=512000000;

					select @_sep := " ## ";
					select @_lab_encounter_type := 99999;
					select @_death_encounter_type := 31;
					select @_last_date_created := (select max(max_date_created) from etl.flat_obs);

					
					
					create table if not exists rebuild_flat_hiv_summary (
						person_id int,
						uuid varchar(100),
						visit_id int,
							encounter_id int,
						encounter_datetime datetime,
						encounter_type int,
						is_clinical_encounter int,
						location_id int,
						location_uuid varchar(100),
						visit_num int,
						enrollment_date datetime,
						hiv_start_date datetime,
						death_date datetime,
						scheduled_visit int,
						transfer_out int,
						transfer_in int,

						patient_care_status int,
						out_of_care int,
						prev_rtc_date datetime,
						rtc_date datetime,

							arv_start_location int,
							arv_first_regimen_start_date datetime,
						arv_start_date datetime,
							prev_arv_start_date datetime,
							prev_arv_end_date datetime,

						arv_first_regimen varchar(500),
							prev_arv_meds varchar(500),
						cur_arv_meds varchar(500),
							prev_arv_line int,
						cur_arv_line int,

						
						prev_arv_adherence varchar(200),
						cur_arv_adherence varchar(200),
						hiv_status_disclosed int,

						first_evidence_patient_pregnant datetime,
						edd datetime,
						screened_for_tb boolean,
						tb_screening_result boolean,
						tb_prophylaxis_start_date datetime,
						tb_prophylaxis_end_date datetime,
						tb_tx_start_date datetime,
						tb_tx_end_date datetime,
						pcp_prophylaxis_start_date datetime,
						cd4_resulted double,
						cd4_resulted_date datetime,
							cd4_1 double,
							cd4_1_date datetime,
							cd4_2 double,
							cd4_2_date datetime,
							cd4_percent_1 double,
						cd4_percent_1_date datetime,
							cd4_percent_2 double,
						cd4_percent_2_date datetime,
						vl_resulted int,
						vl_resulted_date datetime,
							vl_1 int,
							vl_1_date datetime,
							vl_2 int,
							vl_2_date datetime,
							vl_order_date datetime,
							cd4_order_date datetime,

						
						hiv_dna_pcr_order_date datetime,
						hiv_dna_pcr_resulted int,
						hiv_dna_pcr_resulted_date datetime,
						hiv_dna_pcr_1 int,
						hiv_dna_pcr_1_date datetime,
						hiv_dna_pcr_2 int,
						hiv_dna_pcr_2_date datetime,

						
						hiv_rapid_test_resulted int,
						hiv_rapid_test_resulted_date datetime,

						condoms_provided int,
						using_modern_contraceptive_method int,
						
						cur_who_stage int,
						prev_encounter_datetime_hiv datetime,
						next_encounter_datetime_hiv datetime,
						prev_encounter_type_hiv mediumint,
						next_encounter_type_hiv mediumint,
						prev_clinical_datetime_hiv datetime,
						next_clinical_datetime_hiv datetime,

						prev_clinical_rtc_date_hiv datetime,
                        next_clinical_rtc_date_hiv datetime,
                        primary key encounter_id (encounter_id),
                        index person_date (person_id, encounter_datetime),
						index location_rtc (location_uuid,rtc_date),
						index person_uuid (uuid),
						index location_enc_date (location_uuid,encounter_datetime),
						index enc_date_location (encounter_datetime, location_uuid),
						index location_id_rtc_date (location_id,rtc_date),
                        index location_uuid_rtc_date (location_uuid,rtc_date),
                        index loc_id_enc_date_next_clinical (location_id, encounter_datetime, next_clinical_datetime_hiv),
                        index encounter_type (encounter_type)
					);

					select @_last_update := (select max(date_updated) from etl.flat_log where table_name=@_table_version);

					
					select @_last_update :=
						if(@_last_update is null,
							(select max(date_created) from amrs.encounter e join etl.rebuild_flat_hiv_summary using (encounter_id)),
							@_last_update);

					
					select @_last_update := if(@_last_update,@_last_update,'1900-01-01');
					
					

					
					create  table if not exists rebuild_hiv_summary_queue(person_id int, primary key (person_id));

					
					
					select @_num_ids := (select count(*) from rebuild_hiv_summary_queue limit 1);

					if (@_num_ids=0 or @_query_type="sync") then

                        replace into rebuild_hiv_summary_queue
                        (select distinct patient_id 
                            from amrs.encounter
                            where date_changed > @_last_update
                        );


                        replace into rebuild_hiv_summary_queue
                        (select distinct person_id 
                            from etl.flat_obs
                            where max_date_created > @_last_update
                        
                        
                        );

                        (select distinct person_id 
                            from etl.flat_obs
                            where max_date_created > @_last_update
                        
                        
                        );

                        replace into rebuild_hiv_summary_queue
                        (select distinct person_id
                            from etl.flat_lab_obs
                            where max_date_created > @_last_update
                        );

                        replace into rebuild_hiv_summary_queue
                        (select distinct person_id
                            from etl.flat_orders
                            where max_date_created > @_last_update
                        );
					  end if;

					select @_person_ids_count := (select count(*) from rebuild_hiv_summary_queue);

					delete t1 from rebuild_flat_hiv_summary t1 join rebuild_hiv_summary_queue t2 using (person_id);

					while @_person_ids_count > 0 do

						
						drop table if exists rebuild_hiv_summary_queue_0;

						create temporary table rebuild_hiv_summary_queue_0 (select * from rebuild_hiv_summary_queue limit 5000); 


						select @_person_ids_count := (select count(*) from rebuild_hiv_summary_queue);

						drop table if exists rebuild_flat_hiv_summary_0a;
						create temporary table rebuild_flat_hiv_summary_0a
						(select
							t1.person_id,
							t1.visit_id,
							t1.encounter_id,
							t1.encounter_datetime,
							t1.encounter_type,
							t1.location_id,
							t1.obs,
							t1.obs_datetimes,
							
							case
								when t1.encounter_type in (1,2,3,4,10,14,15,17,19,26,32,33,34,47,105,106,112,113,114,115,117,120,127,128,129) then 1
								else null
							end as is_clinical_encounter,

						    case
								when t1.encounter_type in (1,2,3,4,10,14,15,17,19,26,32,33,34,47,105,106,112,113,114,115,117,120,127,128,129) then 10
								else 1
							end as encounter_type_sort_index,

							t2.orders
							from etl.flat_obs t1
								join rebuild_hiv_summary_queue_0 t0 using (person_id)
								left join etl.flat_orders t2 using(encounter_id)
						
							where t1.encounter_type in (1,2,3,4,10,14,15,17,19,22,23,26,32,33,43,47,21,105,106,110,111,112,113,114,115,116,117,120,127,128,129)
						);

						insert into rebuild_flat_hiv_summary_0a
						(select
							t1.person_id,
							null,
							t1.encounter_id,
							t1.test_datetime,
							t1.encounter_type,
							null, 
							t1.obs,
							null, 
							
							0 as is_clinical_encounter,
							1 as encounter_type_sort_index,
							null
							from etl.flat_lab_obs t1
								join rebuild_hiv_summary_queue_0 t0 using (person_id)
						);

						drop table if exists rebuild_flat_hiv_summary_0;
						create temporary table rebuild_flat_hiv_summary_0(index encounter_id (encounter_id), index person_enc (person_id,encounter_datetime))
						(select * from rebuild_flat_hiv_summary_0a
						order by person_id, date(encounter_datetime), encounter_type_sort_index
						);


						select @_prev_id := null;
						select @_cur_id := null;
						select @_enrollment_date := null;
						select @_hiv_start_date := null;
						select @_cur_location := null;
						select @_cur_rtc_date := null;
						select @_prev_rtc_date := null;
						select @_hiv_start_date := null;
						select @_prev_arv_start_date := null;
						select @_arv_start_date := null;
						select @_prev_arv_end_date := null;
						select @_arv_start_location := null;
						select @_art_first_regimen_start_date := null;
						select @_arv_first_regimen := null;
						select @_prev_arv_line := null;
						select @_cur_arv_line := null;
						select @_prev_arv_adherence := null;
						select @_cur_arv_adherence := null;
						select @_hiv_status_disclosed := null;
						select @_first_evidence_pt_pregnant := null;
						select @_edd := null;
						select @_prev_arv_meds := null;
						select @_cur_arv_meds := null;
						select @_tb_prophylaxis_start_date := null;
						select @_tb_prophylaxis_end_date := null;
						select @_tb_treatment_start_date := null;
						select @_tb_treatment_end_date := null;
						select @_pcp_prophylaxis_start_date := null;
						select @_screened_for_tb := null;
						select @_tb_screening_result := null;
						select @_death_date := null;
						select @_vl_1:=null;
						select @_vl_2:=null;
						select @_vl_1_date:=null;
						select @_vl_2_date:=null;
						select @_vl_resulted:=null;
						select @_vl_resulted_date:=null;

						select @_cd4_resulted:=null;
						select @_cd4_resulted_date:=null;
						select @_cd4_1:=null;
						select @_cd4_1_date:=null;
						select @_cd4_2:=null;
						select @_cd4_2_date:=null;
						select @_cd4_percent_1:=null;
						select @_cd4_percent_1_date:=null;
						select @_cd4_percent_2:=null;
						select @_cd4_percent_2_date:=null;
						select @_vl_order_date := null;
						select @_cd4_order_date := null;

						select @_hiv_dna_pcr_order_date := null;
						select @_hiv_dna_pcr_1:=null;
						select @_hiv_dna_pcr_2:=null;
						select @_hiv_dna_pcr_1_date:=null;
						select @_hiv_dna_pcr_2_date:=null;

						select @_hiv_rapid_test_resulted:=null;
						select @_hiv_rapid_test_resulted_date:= null;

						select @_patient_care_status:=null;

						select @_condoms_provided := null;
						select @_using_modern_contraceptive_method := null;

						
						select @_cur_who_stage := null;

						
						
						

						drop temporary table if exists rebuild_flat_hiv_summary_1;
						create temporary table rebuild_flat_hiv_summary_1 (index encounter_id (encounter_id))
						(select
							encounter_type_sort_index,
							@_prev_id := @_cur_id as prev_id,
							@_cur_id := t1.person_id as cur_id,
							t1.person_id,
							p.uuid,
							t1.visit_id,
							t1.encounter_id,
							t1.encounter_datetime,
							t1.encounter_type,
							t1.is_clinical_encounter,

							case
								when @_prev_id != @_cur_id and t1.encounter_type in (21,@_lab_encounter_type) then @_enrollment_date := null
								when @_prev_id != @_cur_id then @_enrollment_date := encounter_datetime
								when t1.encounter_type not in (21,@_lab_encounter_type) and @_enrollment_date is null then @_enrollment_date := encounter_datetime
								else @_enrollment_date
							end as enrollment_date,

							
							
							
							
							if(obs regexp "!!1839="
								,replace(replace((substring_index(substring(obs,locate("!!1839=",obs)),@_sep,1)),"!!1839=",""),"!!","")
								,null) as scheduled_visit,

							case
								when location_id then @_cur_location := location_id
								when @_prev_id = @_cur_id then @_cur_location
								else null
							end as location_id,

							case
						        when @_prev_id=@_cur_id and t1.encounter_type not in (5,6,7,8,9,21) then @_visit_num:= @_visit_num + 1
						        when @_prev_id!=@_cur_id then @_visit_num := 1
							end as visit_num,

							case
						        when @_prev_id=@_cur_id then @_prev_rtc_date := @_cur_rtc_date
						        else @_prev_rtc_date := null
							end as prev_rtc_date,

							
							case
								when obs regexp "!!5096=" then @_cur_rtc_date := replace(replace((substring_index(substring(obs,locate("!!5096=",obs)),@_sep,1)),"!!5096=",""),"!!","")
								when @_prev_id = @_cur_id then if(@_cur_rtc_date > encounter_datetime,@_cur_rtc_date,null)
								else @_cur_rtc_date := null
							end as cur_rtc_date,

							
							case
								when obs regexp "!!7015=" then @_transfer_in := replace(replace((substring_index(substring(obs,locate("!!7015=",obs)),@_sep,1)),"!!7015=",""),"!!","")
								else @_transfer_in := null
							end as transfer_in,

							
							
							

							case
								when obs regexp "!!1285=(1287|9068)!!" then 1
								when obs regexp "!!1596=1594!!" then 1
								when obs regexp "!!9082=(1287|9068|9504|1285)!!" then 1
								else null
							end as transfer_out,

							
							case
								when obs regexp "!!1946=1065!!" then 1
								when obs regexp "!!1285=(1287|9068)!!" then 1
								when obs regexp "!!1596=" then 1
								when obs regexp "!!9082=(159|9036|9083|1287|9068|9079|9504|1285)!!" then 1
								when t1.encounter_type = @_death_encounter_type then 1
								else null
							end as out_of_care,

							
							
							
							
							case
								when obs regexp "!!1946=1065!!" then @_patient_care_status := 9036
								when obs regexp "!!1285=" then @_patient_care_status := replace(replace((substring_index(substring(obs,locate("!!1285=",obs)),@_sep,1)),"!!1285=",""),"!!","")
								when obs regexp "!!1596=" then @_patient_care_status := replace(replace((substring_index(substring(obs,locate("!!1596=",obs)),@_sep,1)),"!!1596=",""),"!!","")
								when obs regexp "!!9082=" then @_patient_care_status := replace(replace((substring_index(substring(obs,locate("!!9082=",obs)),@_sep,1)),"!!9082=",""),"!!","")

								when t1.encounter_type = @_death_encounter_type then @_patient_care_status := 159
								when t1.encounter_type = @_lab_encounter_type and @_cur_id != @_prev_id then @_patient_care_status := null
								when t1.encounter_type = @_lab_encounter_type and @_cur_id = @_prev_id then @_patient_care_status
								else @_patient_care_status := 6101
							end as patient_care_status,

							
							
							
							
							
							
							case
								when obs regexp "!!1946=1065!!" then @_hiv_start_date := null
								when t1.encounter_type=@_lab_encounter_type and obs regexp "!!(1040|1030)=664!!" then @_hiv_start_date:=null
								when @_prev_id != @_cur_id or @_hiv_start_date is null then
									case
										when obs regexp "!!(1040|1030)=664!!" then @_hiv_start_date := date(encounter_datetime)
										when obs regexp "!!(1088|1255)=" then @_hiv_start_date := date(t1.encounter_datetime)
										else @_hiv_start_date := null
									end
								else @_hiv_start_date
							end as hiv_start_date,

							case
								when obs regexp "!!1255=1256!!" or (obs regexp "!!1255=(1257|1259|981|1258|1849|1850)!!" and @_arv_start_date is null ) then @_arv_start_location := location_id
								when @_prev_id = @_cur_id and obs regexp "!!(1250|1088|2154)=" and @_arv_start_date is null then @_arv_start_location := location_id
								when @_prev_id != @_cur_id then @_arv_start_location := null
								else @_arv_start_location
						    end as arv_start_location,

							case
						        when @_prev_id=@_cur_id then @_prev_arv_meds := @_cur_arv_meds
						        else @_prev_arv_meds := null
							end as prev_arv_meds,
							
							
							
							
							case
								when obs regexp "!!1255=(1107|1260)!!" then @_cur_arv_meds := null
								when obs regexp "!!1250=" then @_cur_arv_meds :=
									replace(replace((substring_index(substring(obs,locate("!!1250=",obs)),@_sep,ROUND ((LENGTH(obs) - LENGTH( REPLACE ( obs, "!!1250=", "") ) ) / LENGTH("!!1250=") ))),"!!1250=",""),"!!","")
								when obs regexp "!!1088=" then @_cur_arv_meds :=
									replace(replace((substring_index(substring(obs,locate("!!1088=",obs)),@_sep,ROUND ((LENGTH(obs) - LENGTH( REPLACE ( obs, "!!1088=", "") ) ) / LENGTH("!!1088=") ))),"!!1088=",""),"!!","")
								when obs regexp "!!2154=" then @_cur_arv_meds :=
									replace(replace((substring_index(substring(obs,locate("!!2154=",obs)),@_sep,ROUND ((LENGTH(obs) - LENGTH( REPLACE ( obs, "!!2154=", "") ) ) / LENGTH("!!2154=") ))),"!!2154=",""),"!!","")
								when @_prev_id=@_cur_id then @_cur_arv_meds
								else @_cur_arv_meds:= null
							end as cur_arv_meds,


							case
								when @_arv_first_regimen is null and @_cur_arv_meds is not null then @_arv_first_regimen := @_cur_arv_meds
								when @_prev_id = @_cur_id then @_arv_first_regimen
								else @_arv_first_regimen := null
							end as arv_first_regimen,

							case
								when @_arv_first_regimen_start_date is null and (obs regexp "!!1255=(1256|1259|1850)" or obs regexp "!!1255=(1257|1259|981|1258|1849|1850)!!") then @_arv_first_regimen_start_date := date(t1.encounter_datetime)
								when @_prev_id != @_cur_id then @_arv_first_regimen_start_date := null
                                else @_arv_first_regimen_start_date
							end as arv_first_regimen_start_date,

							case
						        when @_prev_id=@_cur_id then @_prev_arv_line := @_cur_arv_line
						        else @_prev_arv_line := null
							end as prev_arv_line,

							case
								when obs regexp "!!1255=(1107|1260)!!" then @_cur_arv_line := null
								when obs regexp "!!1250=(6467|6964|792|633|631)!!" then @_cur_arv_line := 1
								when obs regexp "!!1250=(794|635|6160|6159)!!" then @_cur_arv_line := 2
								when obs regexp "!!1250=6156!!" then @_cur_arv_line := 3
								when obs regexp "!!1088=(6467|6964|792|633|631)!!" then @_cur_arv_line := 1
								when obs regexp "!!1088=(794|635|6160|6159)!!" then @_cur_arv_line := 2
								when obs regexp "!!1088=6156!!" then @_cur_arv_line := 3
								when obs regexp "!!2154=(6467|6964|792|633|631)!!" then @_cur_arv_line := 1
								when obs regexp "!!2154=(794|635|6160|6159)!!" then @_cur_arv_line := 2
								when obs regexp "!!2154=6156!!" then @_cur_arv_line := 3
								when @_prev_id = @_cur_id then @_cur_arv_line
								else @_cur_arv_line := null
							end as cur_arv_line,

							case
				        when @_prev_id=@_cur_id then @_prev_arv_start_date := @_arv_start_date
				        else @_prev_arv_start_date := null
							end as prev_arv_start_date,

							
							
							
							
							

							case
								when obs regexp "!!1255=(1256|1259|1850)" or (obs regexp "!!1255=(1257|1259|981|1258|1849|1850)!!" and @_arv_start_date is null ) then @_arv_start_date := date(t1.encounter_datetime)
								when obs regexp "!!1255=(1107|1260)!!" then @_arv_start_date := null
								when @_cur_arv_meds != @_prev_arv_meds and @_cur_arv_line != @_prev_arv_line then @_arv_start_date := date(t1.encounter_datetime)
								when @_prev_id != @_cur_id then @_arv_start_date := null
								else @_arv_start_date
							end as arv_start_date,

							case
								when @_prev_arv_start_date != @_arv_start_date then @_prev_arv_end_date  := date(t1.encounter_datetime)
								else @_prev_arv_end_date
							end as prev_arv_end_date,

							case
						        when @_prev_id=@_cur_id then @_prev_arv_adherence := @_cur_arv_adherence
						        else @_prev_arv_adherence := null
							end as prev_arv_adherence,

							
							
							
							
							case
								when obs regexp "!!8288=6343!!" then @_cur_arv_adherence := 'GOOD'
								when obs regexp "!!8288=6655!!" then @_cur_arv_adherence := 'FAIR'
								when obs regexp "!!8288=6656!!" then @_cur_arv_adherence := 'POOR'
								when @_prev_id = @_cur_id then @_cur_arv_adherence
								else @_cur_arv_adherence := null
							end as cur_arv_adherence,

							case
								when obs regexp "!!6596=(6594|1267|6595)!!" then  @_hiv_status_disclosed := 1
								when obs regexp "!!6596=1118!!" then 0
								when obs regexp "!!6596=" then @_hiv_status_disclosed := null
								when @_prev_id != @_cur_id then @_hiv_status_disclosed := null
								else @_hiv_status_disclosed
							end as hiv_status_disclosed,


							
							
							
							
							case
								when @_prev_id != @_cur_id then
									case
										when t1.encounter_type in (32,33,44,10) or obs regexp "!!(1279|5596)=" then @_first_evidence_pt_pregnant := encounter_datetime
										else @_first_evidence_pt_pregnant := null
									end
								when @_first_evidence_pt_pregnant is null and (t1.encounter_type in (32,33,44,10) or obs regexp "!!(1279|5596)=") then @_first_evidence_pt_pregnant := encounter_datetime
								when @_first_evidence_pt_pregnant and (t1.encounter_type in (11,47,34) or timestampdiff(week,@_first_evidence_pt_pregnant,encounter_datetime) > 40 or timestampdiff(week,@_edd,encounter_datetime) > 40 or obs regexp "!!5599=|!!1156=1065!!") then @_first_evidence_pt_pregnant := null
								else @_first_evidence_pt_pregnant
							end as first_evidence_patient_pregnant,

							
							
							
							
							

							case
								when @_prev_id != @_cur_id then
									case
										when @_first_evidence_patient_pregnant and obs regexp "!!1836=" then @_edd :=
											date_add(replace(replace((substring_index(substring(obs,locate("!!1836=",obs)),@_sep,1)),"!!1836=",""),"!!",""),interval 280 day)
										when obs regexp "!!1279=" then @_edd :=
											date_add(encounter_datetime,interval (40-replace(replace((substring_index(substring(obs,locate("!!1279=",obs)),@_sep,1)),"!!1279=",""),"!!","")) week)
										when obs regexp "!!5596=" then @_edd :=
											replace(replace((substring_index(substring(obs,locate("!!5596=",obs)),@_sep,1)),"!!5596=",""),"!!","")
										when @_first_evidence_pt_pregnant then @_edd := date_add(@_first_evidence_pt_pregnant,interval 6 month)
										else @_edd := null
									end
								when @_edd is null or @_edd = @_first_evidence_pt_pregnant then
									case
										when @_first_evidence_pt_pregnant then @_edd := date_add(@_first_evidence_pt_pregnant,interval 6 month)
										when @_first_evidence_patient_pregnant and obs regexp "!!1836=" then @_edd :=
											date_add(replace(replace((substring_index(substring(obs,locate("!!1836=",obs)),@_sep,1)),"!!1836=",""),"!!",""),interval 280 day)
										when obs regexp "!!1279=" then @_edd :=
											date_add(encounter_datetime,interval (40-replace(replace((substring_index(substring(obs,locate("!!1279=",obs)),@_sep,1)),"!!1279=",""),"!!","")) week)
										when obs regexp "!!5596=" then @_edd :=
											replace(replace((substring_index(substring(obs,locate("!!5596=",obs)),@_sep,1)),"!!5596=",""),"!!","")
										when @_first_evidence_pt_pregnant then @_edd := date_add(@_first_evidence_pt_pregnant,interval 6 month)
										else @_edd
									end
								when @_edd and (t1.encounter_type in (11,47,34) or timestampdiff(week,@_edd,encounter_datetime) > 4 or obs regexp "!!5599|!!1145=1065!!") then @_edd := null
								else @_edd
							end as edd,

							
							
							
							
							
							
							
							case
								when obs regexp "!!6174=" then @_screened_for_tb := true 
								when obs regexp "!!2022=1065!!" then @_screened_for_tb := true 
								when obs regexp "!!307=" then @_screened_for_tb := true 
								when obs regexp "!!12=" then @_screened_for_tb := true 
								when obs regexp "!!1271=(12|307|8064|2311|2323)!!" then @_screened_for_tb := true 
								when orders regexp "(12|307|8064|2311|2323)" then @_screened_for_tb := true 
								when obs regexp "!!1866=(12|307|8064|2311|2323)!!" then @_screened_for_tb := true 
								when obs regexp "!!5958=1077!!" then @_screened_for_tb := true 
								when obs regexp "!!2020=1065!!" then @_screened_for_tb := true 
								when obs regexp "!!2021=1065!!" then @_screened_for_tb := true 
								when obs regexp "!!2028=" then @_screened_for_tb := true 
								when obs regexp "!!1268=(1256|1850)!!" then @_screened_for_tb := true
								when obs regexp "!!5959=(1073|1074)!!" then @_screened_for_tb := true 
								when obs regexp "!!5971=(1073|1074)!!" then @_screened_for_tb := true 
								when obs regexp "!!1492=107!!" then @_screened_for_tb := true 
								when obs regexp "!!1270=" and obs not regexp "!!1268=1257!!" then @_screened_for_tb := true
							end as screened_for_tb,

							
							
							
							
							
							
							
							case

								when obs regexp "!!2022=1065!!" then @_tb_screening_result := true 
								when obs regexp "!!307=" then @_tb_screening_result := true 
								when obs regexp "!!12=" then @_tb_screening_result := true 
								when obs regexp "!!1271=(12|307|8064|2311|2323)!!" then @_tb_screening_result := true 
								when orders regexp "(12|307|8064|2311|2323)" then @_tb_screening_result := true 
								when obs regexp "!!1866=(12|307|8064|2311|2323)!!" then @_tb_screening_result := true 
								when obs regexp "!!5958=1077!!" then @_tb_screening_result := true 
								when obs regexp "!!2020=1065!!" then @_tb_screening_result := true 
								when obs regexp "!!2021=1065!!" then @_tb_screening_result := true 
								when obs regexp "!!2028=" then @_tb_screening_result := true 
								when obs regexp "!!1268=(1256|1850)!!" then @_tb_screening_result := true
								when obs regexp "!!5959=(1073|1074)!!" then @_tb_screening_result := true 
								when obs regexp "!!5971=(1073|1074)!!" then @_tb_screening_result := true 
								when obs regexp "!!1492=107!!" then @_tb_screening_result := true 
								when obs regexp "!!1270=" and obs not regexp "!!1268=1257!!" then @_tb_screening_result := true
                                when obs not regexp "!!6174=1107" then @_tb_screening_result := true
                                  else @_tb_screening_result := false
							  end as tb_screening_result,

							case
								when obs regexp "!!1265=(1256|1257|1850)!!" then @_on_tb_prophylaxis := 1
								when obs regexp "!!1110=656!!" then @_on_tb_prophylaxis := 1
								when @_prev_id = @_cur_id then @_on_tb_prophylaxis
								else null
							end as on_tb_prophylaxis,

							
							
							
							
							case
								when @_cur_id != @_prev_id then
									case
                                        when obs regexp "!!1265=(1256|1850)!!" then @_tb_prophylaxis_start_date := encounter_datetime
                                        when obs regexp "!!1265=(1257|981|1406|1849)!!" then @_tb_prophylaxis_start_date := encounter_datetime
										when obs regexp "!!1110=656!!" then @_tb_prophylaxis_start_date := encounter_datetime
                                        else @_tb_prophylaxis_start_date := null
									end
								when @_cur_id = @_prev_id then
									case
										when obs regexp "!!1265=(1256|1850)!!" then @_tb_prophylaxis_start_date := encounter_datetime
                                        when @_tb_prophylaxis_start_date is not null then @_tb_prophylaxis_start_date
                                        when obs regexp "!!1265=(1257|981|1406|1849)!!" then @_tb_prophylaxis_start_date := encounter_datetime
                                        when obs regexp "!!1110=656!!" then @_tb_prophylaxis_start_date := encounter_datetime
									end
							end as tb_prophylaxis_start_date,

							
							
							
							
							case
								when @_cur_id != @_prev_id then
									case
										when obs regexp "!!1265=1260!!" then @_tb_prophylaxis_end_date :=  encounter_datetime
                                        else @_tb_prophylaxis_end_date := null
                                    end
								when @_cur_id = @_prev_id then
									case
										when obs regexp "!!1265=1260!!" then @_tb_prophylaxis_end_date :=  encounter_datetime
                                        when  @_tb_prophylaxis_end_date is not null then @_tb_prophylaxis_end_date
										when @_tb_prophylaxis_start_date is not null and obs regexp "!!1110=1107!!" and obs regexp "!!1265=" and obs regexp "!!1265=(1107|1260)!!" then @_tb_prophylaxis_end_date := encounter_datetime
									end
							end as tb_prophylaxis_end_date,


							
							
							
							case
								when @_cur_id != @_prev_id then
									case
										when obs regexp "!!1113=" then @_tb_treatment_start_date := date(replace(replace((substring_index(substring(obs,locate("!!1113=",obs)),@_sep,1)),"!!1113=",""),"!!",""))
                                        when obs regexp "!!1268=1256!!" then @_tb_treatment_start_date := encounter_datetime
                                        when obs regexp "!!1268=(1257|1259|1849|981)!!" then @_tb_treatment_start_date := encounter_datetime
                                        when obs regexp "!!1111=" and obs not regexp "!!1111=(1267|1107)!!" then @_tb_treatment_start_date := encounter_datetime
                                        else @_tb_treatment_start_date := null
									end
								when @_cur_id = @_prev_id then
									case
										when obs regexp "!!1113=" then @_tb_treatment_start_date := date(replace(replace((substring_index(substring(obs,locate("!!1113=",obs)),@_sep,1)),"!!1113=",""),"!!",""))
                                        when @_tb_treatment_start_date is not null then @_tb_treatment_start_date
										when obs regexp "!!1268=1256!!" then @_tb_treatment_start_date := encounter_datetime
                                        when obs regexp "!!1268=(1257|1259|1849|981)!!" then @_tb_treatment_start_date := encounter_datetime
                                        when obs regexp "!!1111=" and obs not regexp "!!1111=(1267|1107)!!" then @_tb_treatment_start_date := encounter_datetime
									end
							end as tb_tx_start_date,

                            
							
							
							case
								when @_cur_id != @_prev_id then
									case
										when obs regexp "!!2041=" then @_tb_treatment_end_date := date(replace(replace((substring_index(substring(obs,locate("!!2041=",obs)),@_sep,1)),"!!2041=",""),"!!",""))
                                        when obs regexp "!!1268=1260!!" then @_tb_treatment_end_date := encounter_datetime
                                        else @_tb_treatment_end_date := null
									end
								when @_cur_id = @_prev_id then
									case
										when obs regexp "!!2041=" then @_tb_treatment_end_date := date(replace(replace((substring_index(substring(obs,locate("!!2041=",obs)),@_sep,1)),"!!2041=",""),"!!",""))
                                        when obs regexp "!!1268=1260!!" then @_tb_treatment_end_date := encounter_datetime
										when @_tb_treatment_end_date is not null then @_tb_treatment_end_date
                                        when @_tb_treatment_start_date is not null and obs regexp "!!6176=1066!!" and !(obs regexp "!!1268=(1256|1257|1259|1849|981)!!") then @_tb_treatment_end_date := encounter_datetime
									end
							end as tb_tx_end_date,

							
							
							
							case
								when obs regexp "!!1261=(1107|1260)!!" then @_pcp_prophylaxis_start_date := null
								when obs regexp "!!1261=(1256|1850)!!" then @_pcp_prophylaxis_start_date := encounter_datetime
								when obs regexp "!!1261=1257!!" then
									case
										when @_prev_id!=@_cur_id or @_pcp_prophylaxis_start_date is null then @_pcp_prophylaxis_start_date := encounter_datetime
										else @_pcp_prophylaxis_start_date
									end
								when obs regexp "!!1109=(916|92)!!" and @_pcp_prophylaxis_start_date is null then @_pcp_prophylaxis_start_date := encounter_datetime
								when obs regexp "!!1193=916!!" and @_pcp_prophylaxis_start_date is null then @_pcp_prophylaxis_start_date := encounter_datetime
								when @_prev_id=@_cur_id then @_pcp_prophylaxis_start_date
								else @_pcp_prophylaxis_start_date := null
							end as pcp_prophylaxis_start_date,

							
							
							
							
							
							

							case
								when p.dead or p.death_date then @_death_date := p.death_date
								when obs regexp "!!1570=" then @_death_date := replace(replace((substring_index(substring(obs,locate("!!1570=",obs)),@_sep,1)),"!!1570=",""),"!!","")
								when @_prev_id != @_cur_id or @_death_date is null then
									case
										when obs regexp "!!(1734|1573)=" then @_death_date := encounter_datetime
										when obs regexp "!!(1733|9082|6206)=159!!" or t1.encounter_type=31 then @_death_date := encounter_datetime
										else @_death_date := null
									end
								else @_death_date
							end as death_date,

							
							case
								when @_prev_id=@_cur_id then
									case
										when t1.encounter_type = @_lab_encounter_type and obs regexp "!!5497=[0-9]" and @_cd4_1 >= 0 and date(encounter_datetime)<>@_cd4_1_date then @_cd4_2:= @_cd4_1
										else @_cd4_2
									end
								else @_cd4_2:=null
							end as cd4_2,

							case
								when @_prev_id=@_cur_id then
									case
										when t1.encounter_type=@_lab_encounter_type and obs regexp "!!5497=[0-9]" and @_cd4_1 >= 0 then @_cd4_2_date:= @_cd4_1_date
										else @_cd4_2_date
									end
								else @_cd4_2_date:=null
							end as cd4_2_date,

							case
								when t1.encounter_type = @_lab_encounter_type and obs regexp "!!5497=[0-9]" then @_cd4_date_resulted := date(encounter_datetime)
								when @_prev_id = @_cur_id and date(encounter_datetime) = @_cd4_date_resulted then @_cd4_date_resulted
							end as cd4_resulted_date,

							case
								when t1.encounter_type = @_lab_encounter_type and obs regexp "!!5497=[0-9]" then @_cd4_resulted := cast(replace(replace((substring_index(substring(obs,locate("!!5497=",obs)),@_sep,1)),"!!5497=",""),"!!","") as unsigned)
								when @_prev_id = @_cur_id and date(encounter_datetime) = @_cd4_date_resulted then @_cd4_resulted
							end as cd4_resulted,



							case
								when t1.encounter_type = @_lab_encounter_type and obs regexp "!!5497=[0-9]" then @_cd4_1:= cast(replace(replace((substring_index(substring(obs,locate("!!5497=",obs)),@_sep,1)),"!!5497=",""),"!!","") as unsigned)
								when @_prev_id=@_cur_id then @_cd4_1
								else @_cd4_1:=null
							end as cd4_1,


							case
								when t1.encounter_type = @_lab_encounter_type and obs regexp "!!5497=[0-9]" then @_cd4_1_date:=date(encounter_datetime)
								when @_prev_id=@_cur_id then @_cd4_1_date
								else @_cd4_1_date:=null
							end as cd4_1_date,

							
							case
								when @_prev_id=@_cur_id then
									case
										when t1.encounter_type=@_lab_encounter_type and obs regexp "!!730=[0-9]" and @_cd4_percent_1 >= 0
											then @_cd4_percent_2:= @_cd4_percent_1
										else @_cd4_percent_2
									end
								else @_cd4_percent_2:=null
							end as cd4_percent_2,

							case
								when @_prev_id=@_cur_id then
									case
										when obs regexp "!!730=[0-9]" and t1.encounter_type = @_lab_encounter_type and @_cd4_percent_1 >= 0 then @_cd4_percent_2_date:= @_cd4_percent_1_date
										else @_cd4_percent_2_date
									end
								else @_cd4_percent_2_date:=null
							end as cd4_percent_2_date,


							case
								when t1.encounter_type = @_lab_encounter_type and obs regexp "!!730=[0-9]"
									then @_cd4_percent_1:= cast(replace(replace((substring_index(substring(obs,locate("!!730=",obs)),@_sep,1)),"!!730=",""),"!!","") as unsigned)
								when @_prev_id=@_cur_id then @_cd4_percent_1
								else @_cd4_percent_1:=null
							end as cd4_percent_1,

							case
								when obs regexp "!!730=[0-9]" and t1.encounter_type = @_lab_encounter_type then @_cd4_percent_1_date:=date(encounter_datetime)
								when @_prev_id=@_cur_id then @_cd4_percent_1_date
								else @_cd4_percent_1_date:=null
							end as cd4_percent_1_date,


							
							case
									when @_prev_id=@_cur_id then
										case
											when obs regexp "!!856=[0-9]" and @_vl_1 >= 0
												and (replace(replace((substring_index(substring(obs_datetimes,locate("!!856=",obs_datetimes)),@_sep,1)),"!!856=",""),"!!","")) <>date(@_vl_1_date) then @_vl_2:= @_vl_1
											else @_vl_2
										end
									else @_vl_2:=null
							end as vl_2,

							case
									when @_prev_id=@_cur_id then
										case
											when obs regexp "!!856=[0-9]" and @_vl_1 >= 0
												and (replace(replace((substring_index(substring(obs_datetimes,locate("!!856=",obs_datetimes)),@_sep,1)),"!!856=",""),"!!","")) <>date(@_vl_1_date) then @_vl_2_date:= @_vl_1_date
											else @_vl_2_date
										end
									else @_vl_2_date:=null
							end as vl_2_date,

							case
								when t1.encounter_type = @_lab_encounter_type and obs regexp "!!856=[0-9]" then @_vl_date_resulted := date(encounter_datetime)
								when @_prev_id = @_cur_id and date(encounter_datetime) = @_vl_date_resulted then @_vl_date_resulted
							end as vl_resulted_date,

							case
								when t1.encounter_type = @_lab_encounter_type and obs regexp "!!856=[0-9]" then @_vl_resulted := cast(replace(replace((substring_index(substring(obs,locate("!!856=",obs)),@_sep,1)),"!!856=",""),"!!","") as unsigned)
								when @_prev_id = @_cur_id and date(encounter_datetime) = @_vl_date_resulted then @_vl_resulted
							end as vl_resulted,

							case
									when obs regexp "!!856=[0-9]" and t1.encounter_type = @_lab_encounter_type then @_vl_1:=cast(replace(replace((substring_index(substring(obs,locate("!!856=",obs)),@_sep,1)),"!!856=",""),"!!","") as unsigned)
									when obs regexp "!!856=[0-9]"
											and (@_vl_1_date is null or abs(datediff(replace(replace((substring_index(substring(obs_datetimes,locate("!!856=",obs_datetimes)),@_sep,1)),"!!856=",""),"!!",""),@_vl_1_date)) > 30)
											and (@_vl_1_date is null or (replace(replace((substring_index(substring(obs_datetimes,locate("!!856=",obs_datetimes)),@_sep,1)),"!!856=",""),"!!","")) > @_vl_1_date)
										then @_vl_1 := cast(replace(replace((substring_index(substring(obs,locate("!!856=",obs)),@_sep,1)),"!!856=",""),"!!","") as unsigned)
									when @_prev_id=@_cur_id then @_vl_1
									else @_vl_1:=null
							end as vl_1,

                            case
                                when obs regexp "!!856=[0-9]" and t1.encounter_type = @_lab_encounter_type then @_vl_1_date:= encounter_datetime
                                when obs regexp "!!856=[0-9]"
                                        and (@_vl_1_date is null or abs(datediff(replace(replace((substring_index(substring(obs_datetimes,locate("!!856=",obs_datetimes)),@_sep,1)),"!!856=",""),"!!",""),@_vl_1_date)) > 30)
                                        and (@_vl_1_date is null or (replace(replace((substring_index(substring(obs_datetimes,locate("!!856=",obs_datetimes)),@_sep,1)),"!!856=",""),"!!","")) > @_vl_1_date)
                                    then @_vl_1_date := replace(replace((substring_index(substring(obs_datetimes,locate("!!856=",obs_datetimes)),@_sep,1)),"!!856=",""),"!!","")
                                when @_prev_id=@_cur_id then @_vl_1_date
                                else @_vl_1_date:=null
                            end as vl_1_date,



							
							
							case
								when obs regexp "!!1271=856!!" then @_vl_order_date := date(encounter_datetime)
								when orders regexp "856" then @_vl_order_date := date(encounter_datetime)
								when @_prev_id=@_cur_id and (@_vl_1_date is null or @_vl_1_date < @_vl_order_date) then @_vl_order_date
								else @_vl_order_date := null
							end as vl_order_date,

							
							case
								when obs regexp "!!1271=657!!" then @_cd4_order_date := date(encounter_datetime)
								when orders regexp "657" then @_cd4_order_date := date(encounter_datetime)
								when @_prev_id=@_cur_id then @_cd4_order_date
								else @_cd4_order_date := null
							end as cd4_order_date,

								
							case
							  when obs regexp "!!1271=1030!!" then @_hiv_dna_pcr_order_date := date(encounter_datetime)
							  when orders regexp "1030" then @_hiv_dna_pcr_order_date := date(encounter_datetime)
							  when @_prev_id=@_cur_id then @_hiv_dna_pcr_order_date
							  else @_hiv_dna_pcr_order_date := null
							end as hiv_dna_pcr_order_date,

							case
							  when t1.encounter_type = @_lab_encounter_type and obs regexp "!!1030=[0-9]" then encounter_datetime
							  when obs regexp "!!1030=[0-9]"
								  and (@_hiv_dna_pcr_1_date is null or abs(datediff(replace(replace((substring_index(substring(obs_datetimes,locate("!!1030=",obs_datetimes)),@_sep,1)),"!!1030=",""),"!!",""),@_hiv_dna_pcr_1_date)) > 30)
								then replace(replace((substring_index(substring(obs_datetimes,locate("1030=",obs_datetimes)),@_sep,1)),"1030=",""),"!!","")
							end as hiv_dna_pcr_resulted_date,

							case
							  when @_prev_id=@_cur_id then
								case
								  when t1.encounter_type = @_lab_encounter_type and obs regexp "!!1030=[0-9]" and @_hiv_dna_pcr_1 >= 0 and date(encounter_datetime)<>@_hiv_dna_pcr_1_date then @_hiv_dna_pcr_2:= @_hiv_dna_pcr_1
								  when obs regexp "!!1030=[0-9]" and @_hiv_dna_pcr_1 >= 0
									and abs(datediff(replace(replace((substring_index(substring(obs_datetimes,locate("!!1030=",obs_datetimes)),@_sep,1)),"!!1030=",""),"!!",""),@_hiv_dna_pcr_1_date)) > 30 then @_hiv_dna_pcr_2 := @_hiv_dna_pcr_1
								  else @_hiv_dna_pcr_2
								end
							  else @_hiv_dna_pcr_2:=null
							end as hiv_dna_pcr_2,

							case
							  when @_prev_id=@_cur_id then
								case
								  when t1.encounter_type=@_lab_encounter_type and obs regexp "!!1030=[0-9]" and @_hiv_dna_pcr_1 >= 0 and date(encounter_datetime)<>@_hiv_dna_pcr_1_date then @_hiv_dna_pcr_2_date:= @_hiv_dna_pcr_1_date
								  when obs regexp "!!1030=[0-9]" and @_hiv_dna_pcr_1 >= 0
									and abs(datediff(replace(replace((substring_index(substring(obs_datetimes,locate("1030=",obs_datetimes)),@_sep,1)),"1030=",""),"!!",""),@_hiv_dna_pcr_1_date)) > 30 then @_hiv_dna_pcr_2_date:= @_hiv_dna_pcr_1_date
								  else @_hiv_dna_pcr_2_date
								end
							  else @_hiv_dna_pcr_2_date:=null
							end as hiv_dna_pcr_2_date,

							case
							  when t1.encounter_type = @_lab_encounter_type and obs regexp "!!1030=[0-9]" then cast(replace(replace((substring_index(substring(obs,locate("!!1030=",obs)),@_sep,1)),"!!1030=",""),"!!","") as unsigned)
							  when obs regexp "!!1030=[0-9]"
								and (@_hiv_dna_pcr_1_date is null or abs(datediff(replace(replace((substring_index(substring(obs_datetimes,locate("!!1030=",obs_datetimes)),@_sep,1)),"!!1030=",""),"!!",""),@_hiv_dna_pcr_1_date)) > 30)
								then cast(replace(replace((substring_index(substring(obs,locate("!!1030=",obs)),@_sep,1)),"!!1030=",""),"!!","") as unsigned)
							end as hiv_dna_pcr_resulted,

							case
							  when t1.encounter_type = @_lab_encounter_type and obs regexp "!!1030=[0-9]" then @_hiv_dna_pcr_1:= cast(replace(replace((substring_index(substring(obs,locate("!!1030=",obs)),@_sep,1)),"!!1030=",""),"!!","") as unsigned)
							  when obs regexp "!!1030=[0-9]"
								  and (@_hiv_dna_pcr_1_date is null or abs(datediff(replace(replace((substring_index(substring(obs_datetimes,locate("!!1030=",obs_datetimes)),@_sep,1)),"!!1030=",""),"!!","") ,@_hiv_dna_pcr_1_date)) > 30)
								then @_hiv_dna_pcr_1 := cast(replace(replace((substring_index(substring(obs,locate("!!1030=",obs)),@_sep,1)),"!!1030=",""),"!!","") as unsigned)
							  when @_prev_id=@_cur_id then @_hiv_dna_pcr_1
							  else @_hiv_dna_pcr_1:=null
							end as hiv_dna_pcr_1,


							case
							  when t1.encounter_type = @_lab_encounter_type and obs regexp "!!1030=[0-9]" then @_hiv_dna_pcr_1_date:=date(encounter_datetime)
							  when obs regexp "!!1030=[0-9]"
								  and (@_hiv_dna_pcr_1_date is null or abs(datediff(replace(replace((substring_index(substring(obs_datetimes,locate("!!1030=",obs_datetimes)),@_sep,1)),"!!1030=",""),"!!","") ,@_hiv_dna_pcr_1_date)) > 30)
								then @_hiv_dna_pcr_1_date := replace(replace((substring_index(substring(obs_datetimes,locate("!!1030=",obs_datetimes)),@_sep,1)),"!!1030=",""),"!!","")
							  when @_prev_id=@_cur_id then @_hiv_dna_pcr_1_date
							  else @_hiv_dna_pcr_1_date:=null
							end as hiv_dna_pcr_1_date,

							
							case
							  when t1.encounter_type = @_lab_encounter_type and obs regexp "!!(1040|1042)=[0-9]" then encounter_datetime
							end as hiv_rapid_test_resulted_date,

							case
							  when t1.encounter_type = @_lab_encounter_type and obs regexp "!!(1040|1042)=[0-9]" then cast(replace(replace((substring_index(substring(obs,locate("!!(1040|1042)=",obs)),@_sep,1)),"!!(1040|1042)=",""),"!!","") as unsigned)
							end as hiv_rapid_test_resulted,


							case
								when obs regexp "!!8302=8305!!" then @_condoms_provided := 1
								when obs regexp "!!374=(190|6717|6718)!!" then @_condoms_provided := 1
								when obs regexp "!!6579=" then @_condoms_provided := 1
								else null
							end as condoms_provided,

							case
								when obs regexp "!!374=(5275|6220|780|5279)!!" then @_using_modern_conctaceptive_method := 1
								else null
							end as using_modern_contraceptive_method,

							
							
							
							
							

							
							
							
							
							
							case
								when obs regexp "!!5356=(1204)!!" then @_cur_who_stage := 1
								when obs regexp "!!5356=(1205)!!" then @_cur_who_stage := 2
								when obs regexp "!!5356=(1206)!!" then @_cur_who_stage := 3
								when obs regexp "!!5356=(1207)!!" then @_cur_who_stage := 4
								when obs regexp "!!1224=(1220)!!" then @_cur_who_stage := 1
								when obs regexp "!!1224=(1221)!!" then @_cur_who_stage := 2
								when obs regexp "!!1224=(1222)!!" then @_cur_who_stage := 3
								when obs regexp "!!1224=(1223)!!" then @_cur_who_stage := 4
								when @_prev_id = @_cur_id then @_cur_who_stage
								else @_cur_who_stage := null
							end as cur_who_stage

						from rebuild_flat_hiv_summary_0 t1
							join amrs.person p using (person_id)
						);

						select @_prev_id := null;
						select @_cur_id := null;
						select @_prev_encounter_datetime := null;
						select @_cur_encounter_datetime := null;

						select @_prev_clinical_datetime := null;
						select @_cur_clinical_datetime := null;

						select @_next_encounter_type := null;
						select @_cur_encounter_type := null;


						alter table rebuild_flat_hiv_summary_1 drop prev_id, drop cur_id;

						drop table if exists rebuild_flat_hiv_summary_2;
						create temporary table rebuild_flat_hiv_summary_2
						(select *,
							@_prev_id := @_cur_id as prev_id,
							@_cur_id := person_id as cur_id,

							case
								when @_prev_id = @_cur_id then @_prev_encounter_datetime := @_cur_encounter_datetime
								else @_prev_encounter_datetime := null
							end as next_encounter_datetime_hiv,

							@_cur_encounter_datetime := encounter_datetime as cur_encounter_datetime,

							case
								when @_prev_id=@_cur_id then @_next_encounter_type := @_cur_encounter_type
								else @_next_encounter_type := null
							end as next_encounter_type_hiv,

							@_cur_encounter_type := encounter_type as cur_encounter_type,

							case
								when @_prev_id = @_cur_id then @_prev_clinical_datetime := @_cur_clinical_datetime
								else @_prev_clinical_datetime := null
							end as next_clinical_datetime_hiv,

							case
								when is_clinical_encounter then @_cur_clinical_datetime := encounter_datetime
								when @_prev_id = @_cur_id then @_cur_clinical_datetime
								else @_cur_clinical_datetime := null
							end as cur_clinic_datetime,

						    case
								when @_prev_id = @_cur_id then @_prev_clinical_rtc_date := @_cur_clinical_rtc_date
								else @_prev_clinical_rtc_date := null
							end as next_clinical_rtc_date_hiv,

							case
								when is_clinical_encounter then @_cur_clinical_rtc_date := cur_rtc_date
								when @_prev_id = @_cur_id then @_cur_clinical_rtc_date
								else @_cur_clinical_rtc_date:= null
							end as cur_clinical_rtc_date

							from rebuild_flat_hiv_summary_1
							order by person_id, date(encounter_datetime) desc, encounter_type_sort_index desc
						);

						alter table rebuild_flat_hiv_summary_2 drop prev_id, drop cur_id, drop cur_encounter_type, drop cur_encounter_datetime, drop cur_clinical_rtc_date;

						select @_prev_id := null;
						select @_cur_id := null;
						select @_prev_encounter_type := null;
						select @_cur_encounter_type := null;
						select @_prev_encounter_datetime := null;
						select @_cur_encounter_datetime := null;
						select @_prev_clinical_datetime := null;
						select @_cur_clinical_datetime := null;

						drop temporary table if exists rebuild_flat_hiv_summary_3;
						create temporary table rebuild_flat_hiv_summary_3 (prev_encounter_datetime datetime, prev_encounter_type int, index person_enc (person_id, encounter_datetime desc))
						(select
							*,
							@_prev_id := @_cur_id as prev_id,
							@_cur_id := t1.person_id as cur_id,

							case
						        when @_prev_id=@_cur_id then @_prev_encounter_type := @_cur_encounter_type
						        else @_prev_encounter_type:=null
							end as prev_encounter_type_hiv,	@_cur_encounter_type := encounter_type as cur_encounter_type,

							case
						        when @_prev_id=@_cur_id then @_prev_encounter_datetime := @_cur_encounter_datetime
						        else @_prev_encounter_datetime := null
						    end as prev_encounter_datetime_hiv, @_cur_encounter_datetime := encounter_datetime as cur_encounter_datetime,

							case
								when @_prev_id = @_cur_id then @_prev_clinical_datetime := @_cur_clinical_datetime
								else @_prev_clinical_datetime := null
							end as prev_clinical_datetime_hiv,

							case
								when is_clinical_encounter then @_cur_clinical_datetime := encounter_datetime
								when @_prev_id = @_cur_id then @_cur_clinical_datetime
								else @_cur_clinical_datetime := null
							end as cur_clinical_datetime,

							case
								when @_prev_id = @_cur_id then @_prev_clinical_rtc_date := @_cur_clinical_rtc_date
								else @_prev_clinical_rtc_date := null
							end as prev_clinical_rtc_date_hiv,

							case
								when is_clinical_encounter then @_cur_clinical_rtc_date := cur_rtc_date
								when @_prev_id = @_cur_id then @_cur_clinical_rtc_date
								else @_cur_clinical_rtc_date:= null
							end as cur_clinic_rtc_date

							from rebuild_flat_hiv_summary_2 t1
							order by person_id, date(encounter_datetime), encounter_type_sort_index
						);

						replace into rebuild_flat_hiv_summary
						(select
							person_id,
							t1.uuid,
							t1.visit_id,
						    encounter_id,
							encounter_datetime,
							encounter_type,
							is_clinical_encounter,
							location_id,
							t2.uuid as location_uuid,
							visit_num,
							enrollment_date,
							hiv_start_date,
							death_date,
							scheduled_visit,
							transfer_out,
							transfer_in,
						    patient_care_status,
							out_of_care,
							prev_rtc_date,
							cur_rtc_date,
						    arv_start_location,
						    arv_first_regimen_start_date,
							arv_start_date,
							prev_arv_start_date,
						    prev_arv_end_date,
							arv_first_regimen,
						    prev_arv_meds,
							cur_arv_meds,
						    prev_arv_line,
							cur_arv_line,
							prev_arv_adherence,
							cur_arv_adherence,
							hiv_status_disclosed,
						    first_evidence_patient_pregnant,
						    edd,
							screened_for_tb,
							tb_screening_result,
							tb_prophylaxis_start_date,
                            tb_prophylaxis_end_date,
							tb_tx_start_date,
							tb_tx_end_date,
							pcp_prophylaxis_start_date,
							cd4_resulted,
							cd4_resulted_date,
						    cd4_1,
						    cd4_1_date,
						    cd4_2,
						    cd4_2_date,
						    cd4_percent_1,
							cd4_percent_1_date,
						    cd4_percent_2,
							cd4_percent_2_date,
							vl_resulted,
							vl_resulted_date,
						    vl_1,
						    vl_1_date,
						    vl_2,
						    vl_2_date,
						    vl_order_date,
						    cd4_order_date,
							hiv_dna_pcr_order_date,
							hiv_dna_pcr_resulted,
							hiv_dna_pcr_resulted_date,
							hiv_dna_pcr_1,
							hiv_dna_pcr_1_date,
							hiv_dna_pcr_2,
							hiv_dna_pcr_2_date,
							hiv_rapid_test_resulted,
							hiv_rapid_test_resulted_date,
							condoms_provided,
							using_modern_contraceptive_method,
							cur_who_stage,
							prev_encounter_datetime_hiv,
							next_encounter_datetime_hiv,
							prev_encounter_type_hiv,
							next_encounter_type_hiv,
							prev_clinical_datetime_hiv,
							next_clinical_datetime_hiv,
							prev_clinical_rtc_date_hiv,
						    next_clinical_rtc_date_hiv
							from rebuild_flat_hiv_summary_3 t1
								join amrs.location t2 using (location_id));

				    delete from rebuild_hiv_summary_queue where person_id in (select person_id from rebuild_hiv_summary_queue_0);

				 end while;

				 select @_end := now();
				 insert into etl.flat_log values (@_start,@_last_date_created,@_table_version,timestampdiff(second,@_start,@_end));
				 select concat(@_table_version," : Time to complete: ",timestampdiff(minute, @_start, @_end)," minutes");

		END$$
DELIMITER ;

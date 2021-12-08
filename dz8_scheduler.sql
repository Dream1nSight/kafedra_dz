
create or replace procedure KOTLYAROV_DM.job_sync_hospitals_action
as
begin

end;

create or replace procedure KOTLYAROV_DM.job_sync_specialties_action
as
begin

end;

create or replace procedure KOTLYAROV_DM.job_sync_doctors_action
as
begin

end;

begin
    sys.dbms_scheduler.create_job(
            job_name => 'kotlyarov.dl.job_sync_hospitals',
            start_date => current_timestamp,
            repeat_interval => 'FREQ=HOURLY;INTERVAL=1;',
            end_date => null,
            job_class => 'STORED_PROCEDURE',
            job_action => 'job_sync_hospitals_action'
        );

    sys.dbms_scheduler.create_job(
            job_name => 'kotlyarov.dl.job_sync_specialties',
            start_date => current_timestamp,
            repeat_interval => 'FREQ=HOURLY;INTERVAL=1;',
            end_date => null,
            job_class => 'STORED_PROCEDURE',
            job_action => 'job_sync_specialties_action'
        );

    sys.dbms_scheduler.create_job(
            job_name => 'kotlyarov.dl.job_sync_doctors',
            start_date => current_timestamp,
            repeat_interval => 'FREQ=HOURLY;INTERVAL=1;',
            end_date => null,
            job_class => 'STORED_PROCEDURE',
            job_action => 'job_sync_doctors_action'
        );
end;
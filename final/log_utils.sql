create or replace type KOTLYAROV_DM.t_system_log as object
(
    id          number,
    sh_user     varchar2(50),
    created_at  date,
    object_name varchar2(200),
    log_type    varchar2(1000),
    params      varchar2(4000)
);

create or replace type KOTLYAROV_DM.a_system_log as table of KOTLYAROV_DM.t_system_log;

create or replace procedure KOTLYAROV_DM.add_system_log(
    p_object_name varchar2,
    p_params varchar2,
    p_log_type varchar2 default 'common'
)
as
    pragma autonomous_transaction;
begin
    insert into KOTLYAROV_DM.system_logs(object_name, log_type, params)
    values (p_object_name, p_log_type, p_params);

    commit;
end;

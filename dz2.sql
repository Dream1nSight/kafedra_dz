-- Создать метод записи с проверками пациента на соответствие всем пунктам для записи (вариант 1)
declare
    v_id_ticket  number := 2;
    v_id_patient number := 1;
    v_count      number;
begin
    select count(t.ID)
    into v_count
    from KOTLYAROV_DM.TICKETS t
             INNER JOIN KOTLYAROV_DM.PATIENTS p on p.ID = v_id_patient
             INNER JOIN KOTLYAROV_DM.SPECIALITIES s on s.ID = t.ID_SPECIALITY
             INNER JOIN AGE_GROUPS ag on ag.ID = s.ID_AGE_GROUP
             INNER JOIN SPECIALITY_GENDER sg on s.ID = sg.ID_SPECIALITY
    WHERE t.id = v_id_ticket
      AND p.ID_GENDER = sg.ID_GENDER
      AND add_months(p.BIRTHDATE, ag.AGE_BEGIN * 12) <= current_date
      AND add_months(p.BIRTHDATE, ag.AGE_END * 12) > current_date;

    if (v_count = 1) then
        insert into KOTLYAROV_DM.PATIENT_JOURNALS (ID_PATIENT, ID_TICKET) VALUES (v_id_patient, v_id_ticket);
        commit;
        DBMS_OUTPUT.PUT_LINE('Line inserted');
    else
        DBMS_OUTPUT.PUT_LINE('Patient not suitable for this ticket');
    end if;
end;

-- Создать метод записи с проверками пациента на соответствие всем пунктам для записи (вариант 2)
declare
    v_id_ticket         number := 2;
    v_id_patient        number := 1;
    v_patient           KOTLYAROV_DM.PATIENTS%rowtype;
    v_ticket            KOTLYAROV_DM.TICKETS%rowtype;
    v_speciality        KOTLYAROV_DM.SPECIALITIES%rowtype;
    v_age_group         KOTLYAROV_DM.AGE_GROUPS%rowtype;
    v_speciality_gender KOTLYAROV_DM.SPECIALITY_GENDER%rowtype;
begin
    select *
    into v_patient
    from KOTLYAROV_DM.PATIENTS
    where id = v_id_patient;

    select *
    into v_ticket
    from KOTLYAROV_DM.TICKETS
    where id = v_id_ticket;

    select *
    into v_speciality
    from KOTLYAROV_DM.SPECIALITIES
    where id = v_ticket.ID_SPECIALITY;

    select *
    into v_age_group
    from KOTLYAROV_DM.AGE_GROUPS
    where id = v_speciality.ID_AGE_GROUP;

    select *
    into v_speciality_gender
    from KOTLYAROV_DM.SPECIALITY_GENDER
    where id_speciality = v_speciality.id;

    if (add_months(v_patient.BIRTHDATE, v_age_group.AGE_BEGIN * 12) <= current_date and
        add_months(v_patient.BIRTHDATE, v_age_group.AGE_END * 12) > current_date and
        v_patient.id_gender = v_speciality_gender.id_gender
        ) then
        insert into KOTLYAROV_DM.PATIENT_JOURNALS (ID_PATIENT, ID_TICKET) VALUES (v_id_patient, v_id_ticket);
        commit;
        DBMS_OUTPUT.PUT_LINE('Line inserted');
    else
        DBMS_OUTPUT.PUT_LINE('Patient not suitable for this ticket');
    end if;
end;

-- Сделайте выборку одного поля из таблицы. запишите результат в переменную: строковую и числовую
declare
    v_name  varchar2(255);
    v_phone number;
begin
    select FIRST_NAME, PHONE
    into v_name, v_phone
    from KOTLYAROV_DM.PATIENTS
    where id = 1;

    DBMS_OUTPUT.PUT_LINE('Patient`s ' || v_name || ' phone is ' || to_char(v_phone));
end;

-- Заведите заранее переменные для участия в запросе. создайте запрос на получение чего-то where переменная
declare
    v_id_patient number := 2;
    v_name       varchar2(255);
    v_phone      number;
begin
    select FIRST_NAME, PHONE
    into v_name, v_phone
    from KOTLYAROV_DM.PATIENTS
    where id = v_id_patient;

    DBMS_OUTPUT.PUT_LINE('Patient`s ' || v_name || ' phone is ' || to_char(v_phone));
end;

-- Заведите булеву переменную. создайте запрос который имеет разный результат в зависимости от бул переменной. всеми известными способами
declare
    v_closed     boolean := true;
    v_closed_int number(1);

    type t_tickets IS TABLE OF KOTLYAROV_DM.TICKETS%rowtype;
begin

    v_closed_int := case when v_closed then 1 else 0 end;
    v_closed_int := sys.DIUTIL.BOOL_TO_INT(v_closed);

    if (v_closed) then
        v_closed_int := 1;
    else
        v_closed_int := 0;
    end if;

    for ticket in ( select *
                    from KOTLYAROV_DM.TICKETS t
                    where t.closed = v_closed_int
        )
        loop
            DBMS_OUTPUT.PUT_LINE('Found ticket, closed flag is ' || ticket.closed || ' : ' ||
                                 to_char(ticket.time_begin, 'dd.mm.yyyy hh24:mi:ss'));
        end loop;
end;

-- Заведите заранее переменные даты. создайте выборку между датами, за сегодня. в день за неделю назад. сделайте тоже самое но через преобразрование даты из строки
declare
    v_date            date;
    v_date_end        date;
    v_date_string     varchar2(255);
    v_date_end_string varchar2(255);

    type t_tickets is table of KOTLYAROV_DM.tickets%ROWTYPE;
    a_tickets         t_tickets;
begin

    -- Today
    v_date := current_date;

    select * bulk collect
    into a_tickets
    from KOTLYAROV_DM.TICKETS
    where trunc(TIME_BEGIN) >= trunc(v_date)
      and trunc(TIME_BEGIN) < trunc(v_date + 1);

    DBMS_OUTPUT.PUT_LINE('Rows count : ' || sql%ROWCOUNT);


    -- 1 day week before
    v_date := current_date - 7;

    select * bulk collect
    into a_tickets
    from KOTLYAROV_DM.TICKETS
    where trunc(TIME_BEGIN) >= trunc(v_date)
      and trunc(TIME_BEGIN) < trunc(v_date + 1);

    DBMS_OUTPUT.PUT_LINE('Rows count : ' || sql%ROWCOUNT);


    -- In next month
    v_date := add_months(current_date, 1);
    v_date_end := add_months(current_date, 2);

    select * bulk collect
    into a_tickets
    from KOTLYAROV_DM.TICKETS
    where trunc(TIME_BEGIN) >= trunc(v_date)
      and trunc(TIME_BEGIN) < trunc(v_date_end);

    DBMS_OUTPUT.PUT_LINE('Rows count : ' || sql%ROWCOUNT);


    -- With conversion from string
    v_date_string := '01.10.2021 00:00:00';
    v_date_end_string := '01.12.2021 00:00:00';

    select * bulk collect
    into a_tickets
    from KOTLYAROV_DM.TICKETS
    where trunc(TIME_BEGIN) >= trunc(TO_DATE(v_date_string, 'dd.mm.yyyy hh24:mi:ss'))
      and trunc(TIME_BEGIN) < trunc(TO_DATE(v_date_end_string, 'dd.mm.yyyy hh24:mi:ss') + 1);

    DBMS_OUTPUT.PUT_LINE('Rows count : ' || sql%ROWCOUNT);
end;

-- Заведите заранее переменную типа строки. создайте выборку забирающуюю ровну одну строку. выведите в консоль результат
declare
    v_region KOTLYAROV_DM.regions%rowtype;
begin
    select *
    into v_region
    from KOTLYAROV_DM.regions r
    where r.id = 1;

    DBMS_OUTPUT.PUT_LINE('id ' || v_region.id || ', name ' || v_region.name || ', code ' || v_region.code);
end;

-- Завести заранее переменную массива строк. сделать выборку на массив строк. записать в переменную. вывести каждую строку в цикле в консоль
declare
    type t_regions is table of KOTLYAROV_DM.regions%rowtype;

    a_regions t_regions;
begin
    select * bulk collect
    into a_regions
    from KOTLYAROV_DM.regions;

    for i in 1..a_regions.count loop
        DBMS_OUTPUT.PUT_LINE('id ' || a_regions(i).id || ', name ' || a_regions(i).name || ', code ' || a_regions(i).code);
    end loop;
end;
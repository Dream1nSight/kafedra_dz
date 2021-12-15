create or replace package KOTLYAROV_DM.test_pkg_hospital_repository
as
    --%suite

    --%beforeall
    procedure seed;

    --%test
    procedure get_hospital_by_id;

    --%test
--     procedure get_hospital_by_organization_id(hospital_id number);

    --%test
--     procedure get_integrated_hospitals(hospital_id number);

    --%test
--     procedure get_hospital_by_id(hospital_id number);

    --%test
--     procedure get_hospital_by_id(hospital_id number);

    --%test
--     procedure get_hospital_by_id(hospital_id number);

    --%test
--     procedure get_hospital_by_id(hospital_id number);
end;

create or replace package body KOTLYAROV_DM.test_pkg_hospital_repository
as
    mock_id_region number;
    mock_id_town number;
    mock_id_organization number;

    procedure seed
    as
    begin
        insert into KOTLYAROV_DM.regions (name, code)
        values ('region1', 1)
        returning id into mock_id_region;

        insert into KOTLYAROV_DM.towns (name, id_region)
        values ('town1', mock_id_region)
        returning id into mock_id_town;

        insert into KOTLYAROV_DM.organizations (name, id_town)
        values ('organization1', mock_id_town)
        returning id into mock_id_organization;

        insert into KOTLYAROV_DM.HOSPITALS(deleted_at,
                                           name,
                                           id_organization,
                                           status,
                                           id_type,
                                           id_integration_hospital)
        values (null, 'test1', mock_id_organization, KOTLYAROV_DM.enum_hospital_statuses.C_WORKING,
                KOTLYAROV_DM.enum_hospital_types.C_PRIVATE, null);

        insert into KOTLYAROV_DM.HOSPITALS(deleted_at,
                                           name,
                                           id_organization,
                                           status,
                                           id_type,
                                           id_integration_hospital)
        values (null, 'test2', mock_id_organization, KOTLYAROV_DM.enum_hospital_statuses.C_NOT_WORKING,
                KOTLYAROV_DM.enum_hospital_types.C_PRIVATE, null);

        insert into KOTLYAROV_DM.HOSPITALS(deleted_at,
                                           name,
                                           id_organization,
                                           status,
                                           id_type,
                                           id_integration_hospital)
        values (null, 'test3', mock_id_organization, KOTLYAROV_DM.enum_hospital_statuses.C_WORKING,
                KOTLYAROV_DM.enum_hospital_types.C_GOVERNMENT, null);

        insert into KOTLYAROV_DM.HOSPITALS(deleted_at,
                                           name,
                                           id_organization,
                                           status,
                                           id_type,
                                           id_integration_hospital)
        values (null, 'test4', mock_id_organization, KOTLYAROV_DM.enum_hospital_statuses.C_WORKING,
                KOTLYAROV_DM.enum_hospital_types.C_PRIVATE, 23);
    end;

    procedure get_hospital_by_id
    as
        v_hospital KOTLYAROV_DM.T_HOSPITAL;
            asd varchar2(100) := 'test1';
    begin
        v_hospital := KOTLYAROV_DM.PKG_HOSPITAL_REPOSITORY.GET_HOSPITAL_BY_ID(mock_id_organization);

        TOOL_UT3.ut.EXPECT(v_hospital.NAME).TO_EQUAL(asd);
        TOOL_UT3.ut.EXPECT(v_hospital.ID_ORGANIZATION).TO_EQUAL(mock_id_organization);
        TOOL_UT3.ut.EXPECT(v_hospital.status).TO_EQUAL(KOTLYAROV_DM.enum_hospital_statuses.C_WORKING);
        TOOL_UT3.ut.EXPECT(v_hospital.id_type).TO_EQUAL(KOTLYAROV_DM.enum_hospital_types.C_PRIVATE);
        TOOL_UT3.ut.EXPECT(v_hospital.id_integration_hospital).TO_EQUAL(null);
    end;
end;

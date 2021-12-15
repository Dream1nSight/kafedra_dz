
create or replace type KOTLYAROV_DM.t_specialty as object
(
    id           number,
    deleted_at   date,
    id_age_group number,
    id_integration_specialty number,

    constructor function t_specialty(
        id number,
        deleted_at date,
        id_age_group number,
        id_integration_specialty number
    ) return self as result
);

create or replace type KOTLYAROV_DM.a_specialty as table of KOTLYAROV_DM.t_specialty;

create or replace type body KOTLYAROV_DM.t_specialty as
    constructor function t_specialty(
        id number,
        deleted_at date,
        id_age_group number,
        id_integration_specialty number
    ) return self as result as
    begin
        self.id := id;
        self.deleted_at := deleted_at;
        self.id_age_group := id_age_group;
        self.id_integration_specialty := id_integration_specialty;

        return;
    end;
end;


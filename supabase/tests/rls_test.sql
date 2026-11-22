do $$
declare
  user_a uuid := gen_random_uuid();
  user_b uuid := gen_random_uuid();
  job_a uuid;
  resume_a uuid;
  a_profiles int; a_jobs int; a_resumes int; a_apps int;
  b_profiles int; b_jobs int; b_resumes int; b_apps int;
  forged_blocked int := 0;
  updated int := 0;
  n int;
begin
  insert into auth.users (id, email) values
    (user_a, 'rls-test-a@example.com'),
    (user_b, 'rls-test-b@example.com');

  -- Act as user A: create one row in every table
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);
  set local role authenticated;

  insert into public.profiles (full_name) values ('User A');
  insert into public.jobs (title, company) values ('RLS test job', 'Test Co')
    returning id into job_a;
  insert into public.resumes (job_id, content) values (job_a, '{}'::jsonb)
    returning id into resume_a;
  insert into public.applications (job_id, resume_id) values (job_a, resume_a);

  select count(*) into a_profiles from public.profiles;
  select count(*) into a_jobs from public.jobs;
  select count(*) into a_resumes from public.resumes;
  select count(*) into a_apps from public.applications;

  -- Act as user B
  reset role;
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_b, 'role', 'authenticated')::text, true);
  set local role authenticated;

  select count(*) into b_profiles from public.profiles;
  select count(*) into b_jobs from public.jobs;
  select count(*) into b_resumes from public.resumes;
  select count(*) into b_apps from public.applications;

  -- B tries to forge rows that belong to A (RLS violation = SQLSTATE 42501)
  begin
    insert into public.profiles (user_id, full_name) values (user_a, 'forged');
  exception when sqlstate '42501' then forged_blocked := forged_blocked + 1;
  end;
  begin
    insert into public.jobs (user_id, title, company) values (user_a, 'forged', 'X');
  exception when sqlstate '42501' then forged_blocked := forged_blocked + 1;
  end;
  begin
    insert into public.resumes (user_id, content) values (user_a, '{}'::jsonb);
  exception when sqlstate '42501' then forged_blocked := forged_blocked + 1;
  end;
  begin
    insert into public.applications (user_id, job_id) values (user_a, job_a);
  exception when sqlstate '42501' then forged_blocked := forged_blocked + 1;
  end;

  -- B tries to modify everything it can reach
  update public.profiles set full_name = 'hacked';
  get diagnostics n = row_count; updated := updated + n;
  update public.jobs set title = 'hacked';
  get diagnostics n = row_count; updated := updated + n;
  update public.resumes set verified = true;
  get diagnostics n = row_count; updated := updated + n;
  update public.applications set notes = 'hacked';
  get diagnostics n = row_count; updated := updated + n;

  reset role;

  raise exception
    'RLS TEST (rolled back, nothing saved): A sees profiles/jobs/resumes/applications = %/%/%/%; B sees = %/%/%/%; forged inserts blocked: %/4; B updates touched % row(s)',
    a_profiles, a_jobs, a_resumes, a_apps,
    b_profiles, b_jobs, b_resumes, b_apps,
    forged_blocked, updated;
end $$;
create or replace function test.ok(c boolean, msg text) returns void language plpgsql as $$
begin
  if c is not true then raise exception 'FAIL: %', msg; end if;
  raise notice 'PASS: %', msg;
end $$;
-- 지금 권한으로 이 SQL 은 반드시 오류가 나야 한다 (RLS 거절, 제약 위반 등)
create or replace function test.throws(q text, msg text) returns void language plpgsql as $$
begin
  begin
    execute q;
  exception when others then
    raise notice 'PASS: % [%]', msg, left(sqlerrm, 60);
    return;
  end;
  raise exception 'FAIL (no error): %', msg;
end $$;
-- 지금 권한으로 보이는 행 수
create or replace function test.n(q text) returns bigint language plpgsql as $$
declare r bigint; begin execute 'select count(*) from (' || q || ') x' into r; return r; end $$;
grant execute on all functions in schema test to public;

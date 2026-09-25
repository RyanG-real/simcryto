do $$
begin
  create type public.trade_side as enum ('buy', 'sell');
exception
  when duplicate_object then null;
end
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  avatar_url text,
  available_cash numeric(20, 2) not null default 10000 check (available_cash >= 0),
  preferred_theme text not null default 'dark' check (preferred_theme in ('light', 'dark', 'system')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.holdings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  coin_id text not null,
  symbol text not null,
  amount numeric(38, 18) not null check (amount > 0),
  average_cost numeric(38, 18) not null check (average_cost > 0),
  updated_at timestamptz not null default now(),
  unique (user_id, coin_id)
);

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  client_order_id uuid not null,
  user_id uuid not null references public.profiles(id) on delete cascade,
  side public.trade_side not null,
  coin_id text not null,
  symbol text not null,
  amount numeric(38, 18) not null check (amount > 0),
  executed_price numeric(38, 18) not null check (executed_price > 0),
  total_usd numeric(20, 2) not null check (total_usd > 0),
  fee_usd numeric(20, 2) not null default 0 check (fee_usd >= 0),
  price_timestamp timestamptz not null,
  created_at timestamptz not null default now(),
  unique (user_id, client_order_id)
);

create index if not exists transactions_user_created_idx on public.transactions (user_id, created_at desc);
create index if not exists holdings_user_idx on public.holdings (user_id);

alter table public.profiles enable row level security;
alter table public.holdings enable row level security;
alter table public.transactions enable row level security;

drop policy if exists "read own profile" on public.profiles;
drop policy if exists "read own holdings" on public.holdings;
drop policy if exists "read own transactions" on public.transactions;
create policy "read own profile" on public.profiles for select to authenticated using ((select auth.uid()) = id);
create policy "read own holdings" on public.holdings for select to authenticated using ((select auth.uid()) = user_id);
create policy "read own transactions" on public.transactions for select to authenticated using ((select auth.uid()) = user_id);

revoke insert, update, delete on public.profiles from anon, authenticated;
revoke insert, update, delete on public.holdings from anon, authenticated;
revoke insert, update, delete on public.transactions from anon, authenticated;
grant select on public.profiles, public.holdings, public.transactions to authenticated;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, email, display_name, avatar_url)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', 'Demo Trader'),
    new.raw_user_meta_data ->> 'avatar_url'
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Called only by a trusted Edge Function after it verifies the market price.
create or replace function public.execute_trade_trusted(
  p_user_id uuid,
  p_client_order_id uuid,
  p_side public.trade_side,
  p_coin_id text,
  p_symbol text,
  p_amount numeric,
  p_price numeric,
  p_price_timestamp timestamptz
)
returns public.transactions
language plpgsql
security definer set search_path = ''
as $$
declare
  v_profile public.profiles;
  v_holding public.holdings;
  v_existing public.transactions;
  v_total numeric(20, 2);
  v_trade public.transactions;
begin
  if p_amount <= 0 or p_price <= 0 then
    raise exception 'Amount and price must be positive';
  end if;

  select * into v_existing from public.transactions
  where user_id = p_user_id and client_order_id = p_client_order_id;
  if found then return v_existing; end if;

  select * into v_profile from public.profiles where id = p_user_id for update;
  if not found then raise exception 'Profile not found'; end if;
  v_total := round(p_amount * p_price, 2);

  select * into v_holding from public.holdings
  where user_id = p_user_id and coin_id = p_coin_id for update;

  if p_side = 'buy' then
    if v_profile.available_cash < v_total then raise exception 'Insufficient cash'; end if;
    update public.profiles set available_cash = available_cash - v_total, updated_at = now() where id = p_user_id;
    if v_holding.id is null then
      insert into public.holdings (user_id, coin_id, symbol, amount, average_cost)
      values (p_user_id, p_coin_id, upper(p_symbol), p_amount, p_price);
    else
      update public.holdings set
        average_cost = ((amount * average_cost) + v_total) / (amount + p_amount),
        amount = amount + p_amount,
        updated_at = now()
      where id = v_holding.id;
    end if;
  else
    if v_holding.id is null or v_holding.amount < p_amount then raise exception 'Insufficient holdings'; end if;
    update public.profiles set available_cash = available_cash + v_total, updated_at = now() where id = p_user_id;
    if v_holding.amount = p_amount then
      delete from public.holdings where id = v_holding.id;
    else
      update public.holdings set amount = amount - p_amount, updated_at = now() where id = v_holding.id;
    end if;
  end if;

  insert into public.transactions (client_order_id, user_id, side, coin_id, symbol, amount, executed_price, total_usd, price_timestamp)
  values (p_client_order_id, p_user_id, p_side, p_coin_id, upper(p_symbol), p_amount, p_price, v_total, p_price_timestamp)
  returning * into v_trade;
  return v_trade;
end;
$$;

revoke execute on function public.execute_trade_trusted(uuid, uuid, public.trade_side, text, text, numeric, numeric, timestamptz) from public, anon, authenticated;
grant execute on function public.execute_trade_trusted(uuid, uuid, public.trade_side, text, text, numeric, numeric, timestamptz) to service_role;

create or replace function public.reset_my_account()
returns void
language plpgsql
security definer set search_path = ''
as $$
declare v_user_id uuid := auth.uid();
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  delete from public.transactions where user_id = v_user_id;
  delete from public.holdings where user_id = v_user_id;
  update public.profiles set available_cash = 10000, updated_at = now() where id = v_user_id;
end;
$$;

revoke execute on function public.reset_my_account() from public, anon;
grant execute on function public.reset_my_account() to authenticated;

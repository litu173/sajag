-- New enum values live in their own migration: Postgres can't use a value added in the same transaction.

-- Traffic-division officers verify traffic-violation reports and record the action taken.
alter type public.admin_role add value if not exists 'traffic';

-- Community flag for posts that target a person, politician or celebrity, or serve personal gain.
alter type public.flag_reason add value if not exists 'targets_person';

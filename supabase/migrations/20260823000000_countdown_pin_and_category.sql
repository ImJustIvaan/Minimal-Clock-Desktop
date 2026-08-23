-- Countdown pinning is a per-viewer preference, so it lives on the
-- follows join row (same as `notify`) rather than on the countdown itself.
alter table countdown_follows
  add column if not exists pinned boolean not null default false;

-- Category describes the countdown itself, so it lives on the countdown
-- record and is set by its owner.
alter table countdowns
  add column if not exists category text;
